RSpec.describe Keycloak3scaleUsers do
  before(:all) do
    ARGV.clear
    $stderr = StringIO.new
    $stdout = StringIO.new
  end

  let(:sample_params) {
    %w(https://api.example.come Aex3! https://kc.example.come master 321 adm adm https://portal.example.com)
  }

  it "has a version number" do
    expect(Keycloak3scaleUsers::VERSION).not_to be nil
    expect(Keycloak3scaleUsers::VERSION).to be_a(String)
  end

  it "prints first message" do
    expect { Keycloak3scaleUsers::Core.run }.to output(%r{Starting Migration Script}).to_stdout
      .and raise_error(SystemExit)
  end

  describe "validations" do
    it "validates and exits if an argument is missing" do
      param_keys = %w(
        threescale_url threescale_token keyclock_url keyclock_realm keyclock_client_id
        keyclock_admin_user keycloak_admin_password rabet_url
      )
      param_keys.each do |k|
        error_msg = Regexp.new "input parameter #{k} is empty"
        expect { Keycloak3scaleUsers::Core.run }.to output(error_msg).to_stdout
          .and raise_error(SystemExit)
        ARGV.append sample_params.shift
      end
    end

    it "exits when any argument is missing" do
      sample_params.pop
      ARGV = sample_params
      error = %r|Error\: input parameter rabet_url is empty|
      expect { Keycloak3scaleUsers::Core.run }.to output(error).to_stdout
      .and raise_error(SystemExit)
    end

    it "contiunes procedure when all params are passed" do
      ARGV = sample_params
      msg_to_match = %r[All parameters are set]
      expect { Keycloak3scaleUsers::Core.run }.to output(msg_to_match).to_stdout
        .and raise_error(SocketError)
    end
  end
end
