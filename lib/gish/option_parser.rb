require "optparse"

module Gish
  class OptionParser
    # IMPROVE: Find a better way to set the options
    OPTIONS = {
      add: [
        "Usage: gish add [<option> ...] [<query> ...]",
        {
          short: "-u",
          long: "--untracked-only",
          description: "Untracked files only",
          key: :untracked_only
        },
        {
          short: "-t",
          long: "--tracked-only",
          description: "Tracked files only",
          key: :tracked_only
        },
        {
          short: "-r",
          long: "--from-root",
          description: "Act as if in the root of the repo",
          key: :from_root
        },
        {
          short: "-g",
          long: "--greedy",
          description: "Filter the files greedily",
          key: :greedy
        }
      ],
      find: [
        "Usage: gish add [<option> ...] [<query> ...]",
        {
          short: "-d",
          long: "--directory DIRECTORY",
          description: "Directory to search",
          key: :directory
        },
        {
          short: "-c",
          long: "--command COMMAND",
          description: "Shell command to get the files to filter",
          key: :command
        },
        {
          short: "-r",
          long: "--refine",
          description: "Each query refines the search",
          key: :refine
        },
        {
          short: "-g",
          long: "--greedy",
          description: "Filter the files greedily",
          key: :greedy
        }
      ]
    }


    def initialize(command)
      @command = command.to_sym
    end

    def parse(args)
      options = {}
      return options unless OPTIONS.has_key?(@command)

      command_options = OPTIONS[@command]

      option_parser = ::OptionParser.new do |opts|
        opts.banner = command_options.shift
        opts.separator ""

        command_options.each do |opt|
          opts.on(opt[:short], opt[:long], opt[:description]) do |value|
            options[opt[:key]] = value
          end
        end
      end

      option_parser.parse!(args)
      options
    end
  end
end
