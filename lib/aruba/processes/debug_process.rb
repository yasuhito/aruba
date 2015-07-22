require 'aruba/processes/spawn_process'

module Aruba
  module Processes
    # Debug Process
    class DebugProcess < BasicProcess
      # Use only if mode is :debug
      def self.match?(mode)
        mode == :debug || (mode.is_a?(Class) && mode <= DebugProcess)
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/CyclomaticComplexity
      def start
        if RUBY_VERSION < '2'
          Dir.chdir @working_directory do
            with_local_env(environment) do
              @exit_status = system(command, *arguments) ? 0 : 1
            end
          end
        else
          with_local_env(environment) do
            @exit_status = system(command, *arguments, :chdir => @working_directory) ? 0 : 1
          end
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/MethodLength

      def stdin(*); end

      def stdout(*)
        'This is the debug launcher on STDOUT. If this output is unexpected, please check your setup.'
      end

      def stderr(*)
        'This is the debug launcher on STDERR. If this output is unexpected, please check your setup.'
      end

      def stop(_reader)
        @stopped = true

        @exit_status
      end

      def terminate(*)
        stop
      end
    end
  end
end
