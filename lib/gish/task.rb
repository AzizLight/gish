module Gish
  class Task
    include Gish::Helpers::RainbowHelper

    attr_reader :command, :arguments, :options

    def initialize(command = "", arguments = [], options = {})
      @arguments = arguments
      @options = options
      # IMPROVE: command might be something like `ls-files`, in which case capitalize might not work
      self.command = "#{command.capitalize}Command".to_sym
    end

    def command=(cmd)
      return @command unless @command.nil?

      @command = Gish::Commands.const_get(cmd).new(@arguments, @options)
    end

    def run!
      command.send command.class::EXECUTION_METHOD
    rescue
      return "", Gish::ERROR
    end
  end
end

