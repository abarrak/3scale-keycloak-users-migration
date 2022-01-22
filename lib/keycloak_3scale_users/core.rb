# frozen_string_literal: true
require 'net/http'
require 'openssl'
require 'uri'
require 'logger'
require 'rubygems'
require 'nokogiri'
require 'csv'

##
# Parametes
# -----
# * <3scale-api-base-url>
# * <3scale-token>
# * <keycloak-url>
# * <keycloak-realm-name>
# * <keyclock_client_id>
# * <keyclock-admin-user>
# * <keycloak-admin-password>
# * <main-redirect-url>
#
#
module Keycloak3scaleUsers
  module Core
    User = Struct.new(:email, :username, :first_name, :last_name)

    def self.run
      print_welcome
      set_parameters
      import_current_users
      migrate_to_sso
      collect_keyclock_user_ids
      send_email_notifications
    rescue
      p $!
      raise
      exit 1
    end

    class << self
      protected

      def print_welcome
        puts ">> Starting Migration Script <<\n\n"
      end

      def set_parameters
        param_keys = %w(
          threescale_url threescale_token keyclock_url keyclock_realm keyclock_client_id
          keyclock_admin_user keycloak_admin_password rabet_url
        )
        arguments = ARGV.collect { |arg| arg.chomp }

        param_keys.zip(arguments).each do |key, arg|
          instance_variable_set "@#{key}", arg
          puts "> parameter #{key} is set to #{arg}"
        end

        param_keys.each do |key|
          param = instance_variable_get "@#{key}"
          if param.nil? || param.empty?
            puts "\n> Error: input parameter #{key} is empty"
            exit 1
          end
        end
        puts "> All parameters are set!\n\n"
      end

      def import_current_users
        puts ">> 1. Starting the import process .."
        count = 0

        base_url = instance_variable_get :@threescale_url
        token = instance_variable_get :@threescale_token
        pages = 500
        endpoint = "/admin/api/accounts.xml?access_token=#{token}&page=1&per_page=#{pages}"

        http = set_http_client URI.parse(base_url)
        headers = authenticate
        response = http.request Net::HTTP::Get.new(endpoint, headers)

        unless Net::HTTPSuccess === response
          puts "endpoint responded with non-success #{response.code} code.\nResponse: #{response.body}"
          exit 1
        end
        @users = pares_users_from_xml response.body

        puts ">> Imported #{@users.count} users successfully from 3scale system.\n>> Done.\n\n"
      end

      def migrate_to_sso
        puts ">> 2. Starting the migration process .."

        @users.each do |user|
          import_user_to_sso user
        end

        puts "> Done.\n\n"
      end

      def send_email_notifications
        puts ">> 4. Sending email notifications .."

        @user_ids.each do |id|
          send_email_to_user id
        end

        puts "> Done.\n\n"
      end

      def set_http_client uri
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https' ? true : false
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http
      end

      def authenticate bearer_token = ''
        headers = {}
        headers['Authorization'] = "Bearer #{bearer_token}" unless bearer_token.empty?
        headers['User-Agent'] = "SSO Migration Script"
        headers
      end

      def pares_users_from_xml response_body
        doc = Nokogiri::XML response_body
        xpath_node = '//accounts//account//users//user'
        users = doc.xpath
        emails, usernames, first_names, last_names = ['//email', '//username', '//first_name', '//last_name'].collect { |path| doc.xpath path }
        user_count = emails.count

        users = []
        1.upto(user_count).each do |i|
          e = emails[i]&.text
          u = usernames[i]&.text
          f = first_names[i]&.text
          l = last_names[i]&.text
          users << User.new(e, u, f, l) unless e.nil?
        end
        puts "> All users dump:\n"
        puts users, "\n"
        users
      end

      def parse_as_json response
        body = response.body
        body = body.nil? || body.empty? ? body : JSON.parse(body)

      rescue JSON::ParserError => error
        puts "Parsing response body as JSON failed! Returning raw body. \nDetails: \n#{error.message}"
        exit 1
      end

      def import_user_to_sso user
        base_url = instance_variable_get :@keyclock_url
        realm = instance_variable_get :@keyclock_realm
        endpoint = "/auth/admin/realms/#{realm}/users"

        http = set_http_client URI.parse(base_url)
        headers = authenticate(generate_keycloak_bearer_token).merge({ "Content-Type" => "application/json" })
        request = Net::HTTP::Post.new(endpoint, headers)
        request.body = JSON.dump({
          "createdTimestamp": 1588880747548,
          "username": user.email,
          "enabled": true,
          "emailVerified": true,
          "firstName": user.first_name,
          "lastName": user.last_name,
          "email": user.email,
          "disableableCredentialTypes": [],
          "requiredActions": [],
          "notBefore": 0,
          "access": {
            "manageGroupMembership": false,
            "view": true,
            "mapRoles": false,
            "impersonate": false,
            "manage": false
          }
        })
        response = http.request request

        unless Net::HTTPSuccess === response
          puts "endpoint responded with non-success #{response.code} code.\nResponse: #{response.body}"
          puts "Error: failed to import user #{user.email} .."
        else
          puts "> importing user #{user.email} to keyclock successfully.\n\n"
        end
      end

      def generate_keycloak_bearer_token
        return @token if @token_time && (Time.now - @token_time < 40.to_f)

        base_url = instance_variable_get :@keyclock_url
        realm = instance_variable_get :@keyclock_realm
        admin_user = instance_variable_get :@keyclock_admin_user
        admin_pass = instance_variable_get :@keycloak_admin_password

        endpoint = "/auth/realms/master/protocol/openid-connect/token"
        @token_time = Time.now

        http = set_http_client URI.parse(base_url)
        headers = authenticate.merge({ "Content-Type" => "application/x-www-form-urlencoded" })
        request = Net::HTTP::Post.new endpoint, headers
        response = http.request request
        request.body = "client_id=admin-cli&username=#{admin_user}&password=#{admin_pass}&grant_type=password"

        response = http.request request
        @token = parse_as_json(response)['access_token']
        puts "> [[ Keyclock token is regenerated ]], #{@token.slice(30, 40)}..."
        @token
      end

      def collect_keyclock_user_ids
        puts ">> 3. Getting ids for all imported users to keyclock .."
        base_url = instance_variable_get :@keyclock_url
        realm = instance_variable_get :@keyclock_realm
        users_count = 1000 
        endpoint = "/auth/admin/realms/#{realm}/users?count=#{users_count}"

        http = set_http_client URI.parse(base_url)
        headers = authenticate(generate_keycloak_bearer_token).merge({ "Content-Type" => "application/json" })
        request = Net::HTTP::Get.new(endpoint, headers)
        response = http.request request

        @user_ids = parse_as_json(response).collect { |user| user['id'] }
        puts "> All users dump:"
        puts @user_ids, "\n"

        unless Net::HTTPSuccess === response
          puts "endpoint responded with non-success #{response.code} code.\nResponse: #{response.body}"
          puts "Error: failed to get users list from Keyclock .."
          exit 1
        else
          puts "> Reterived all users (total: #{@user_ids.count}) from keyclok successfully.\n\n"
        end
        @user_ids
      end

      def send_email_to_user user_id
        base_url = instance_variable_get :@keyclock_url
        realm = instance_variable_get :@keyclock_realm
        client_id = instance_variable_get :@keyclock_client_id
        rabet_url = instance_variable_get :@rabet_url
        endpoint = "/auth/admin/realms/#{realm}/users/#{user_id}/execute-actions-email"
        endpoint = endpoint.dup + "?redirect_uri=#{rabet_url}&client_id=#{client_id}"


        http = set_http_client URI.parse(base_url)
        headers = authenticate(generate_keycloak_bearer_token).merge({ "Content-Type" => "application/json" })
        request = Net::HTTP::Put.new(endpoint, headers)
        request.body = JSON.dump [ "UPDATE_PASSWORD" ]
        response = http.request request

        unless Net::HTTPSuccess === response
          puts "endpoint responded with non-success #{response.code} code.\nResponse: #{response.body}"
          puts "Error: failed to send set actions email to user id #{user_id} .."
        else
          puts "> Restet password email to user id #{user_id} is sent successfully."
        end
      end
    end
  end
end
