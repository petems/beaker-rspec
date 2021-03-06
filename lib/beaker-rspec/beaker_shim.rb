require 'beaker'

module BeakerRSpec
  # BeakerShim Module
  #
  # This module provides the connection between rspec and the Beaker DSL.
  # Additional wrappers are provided around commonly executed sets of Beaker
  # commands.
  module BeakerShim
    include Beaker::DSL

    # Accessor for logger
    # @return Beaker::Logger object
    def logger
      @logger
    end

    # Accessor for options hash
    # @return Hash options
    def options
      RSpec.configuration.options
    end

    # Provision the hosts to run tests on.
    # Assumes #setup has already been called.
    #
    def provision
      @network_manager = Beaker::NetworkManager.new(options, @logger)
      RSpec.configuration.hosts = @network_manager.provision
    end

    # Validate that the SUTs are up and correctly configured
    # Assumes #setup and #provision has already been called.
    def validate
      Beaker::Utils::Validator.validate(RSpec.configuration.hosts, @logger)
    end

    # Setup the testing environment
    # @param [Array<String>] args The argument array of options for configuring Beaker
    # See 'beaker --help' for full list of supported command line options
    def setup(args = [])
      options_parser = Beaker::Options::Parser.new
      options = options_parser.parse_args(args)
      options[:debug] = true
      @logger = Beaker::Logger.new(options)
      options[:logger] = @logger
      RSpec.configuration.hosts = []
      RSpec.configuration.options = options
    end

    # Accessor for hosts object
    # @return [Array<Beaker::Host>]
    def hosts
      RSpec.configuration.hosts
    end

    # Cleanup the testing framework, shut down test boxen and tidy up
    def cleanup
      @network_manager.cleanup
    end

    # Copy a puppet module from a given source to all hosts under test.
    # Assumes each host under test has an associated 'distmoduledir' (set in the
    # host configuration YAML file).
    #
    # @param opts [Hash]
    # @option opts [String] :source The location on the test runners box where the files are found
    # @option opts [String] :module_name The name of the module to be copied over
    def puppet_module_install opts = {}
      hosts.each do |host|
        scp_to host, opts[:source], File.join(host['distmoduledir'], opts[:module_name])
      end
    end

  end
end
