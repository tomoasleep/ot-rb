# frozen_string_literal: true

require "debug"

module DebugHelper
  class << self
    def debug_on_error
      yield
    rescue StandardError => e
      enter_postmortem_session(e)
      raise e
    end

    def enter_postmortem_session(error)
      error = error.cause while error.cause

      puts "Enter postmortem mode with #{error.inspect}"
      puts error.backtrace.map { |b| "\t#{b}" }
      puts "\n"

      DEBUGGER__::SESSION.enter_postmortem_session(error)
    end

    def enable
      DEBUGGER__::SESSION.postmortem = true
    end
  end
end

return unless ENV['DEBUG_ON_ERROR']

RSpec.configure do |config|
  DebugHelper.enable

  config.around(:example) do |example|
    DebugHelper.debug_on_error do
      example.run
    end
  end

  config.after(:example) do |example|
    DebugHelper.enter_postmortem_session(example.exception) if example.exception
  end
end
