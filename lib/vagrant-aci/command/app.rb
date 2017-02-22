require 'vagrant-aci/action'
require 'highline/import'
require 'colorize'
require 'json'
require 'text-table'
require 'rest-client'

module VagrantPlugins
  module ACI
    module Command
      class App < Vagrant.plugin("2", :command)
        def self.synopsis
          "allows Vagrant to deploy new Application Network Profiles to a Cisco ACI environment"
        end

        def initialize(argv, env)
          @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)

          @subcommands = Vagrant::Registry.new
          @subcommands.register(:new) do
            require File.expand_path("../new_app", __FILE__)
            New
          end
          @subcommands.register(:delete) do
            require File.expand_path("../delete_app", __FILE__)
            Delete
          end
          @subcommands.register(:list) do
            require File.expand_path("../list_app", __FILE__)
            List
          end

          super(argv, env)
        end

        def execute
          if @main_args.include?("-h") || @main_args.include?("--help")
            # Print the help for all the  commands.
            return help
          end

          command_class = @subcommands.get(@sub_command.to_sym) if @sub_command
          return help if !command_class || !@sub_command
          @logger.debug("Invoking command class: #{command_class} #{@sub_args.inspect}")

          # Initialize and execute the command class
          command_class.new(@sub_args, @env).execute
        end

        def help
          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant aci app <subcommand> [<args>]"
            opts.separator ""
            opts.separator "Available subcommands:\n"
        
            # Add the available subcommands as separators in order to print them
            # out as well.
            keys = []
            @subcommands.each { |key, value| keys << key.to_s }

            keys.sort.each do |key|
              opts.separator "     #{key}"
            end

            opts.separator ""
            opts.separator "For help on any individual subcommand run `vagrant aci app <subcommand> -h`"
          end

          @env.ui.info(opts.help, :prefix => false)
        end
      end
    end
  end
end
