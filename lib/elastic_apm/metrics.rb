# frozen_string_literal: true

module ElasticAPM
  # @api private
  module Metrics
    def self.new(config, &block)
      Registry.new(config, &block)
    end

    def self.platform
      @platform ||= Gem::Platform.local.os.to_sym
    end

    # @api private
    class Registry
      include Logging

      TIMEOUT_INTERVAL = 5 # seconds

      def initialize(config, &block)
        @config = config
        @callback = block
      end

      attr_reader :config, :sets, :callback
      def start
        unless config.collect_metrics?
          debug 'Skipping metrics'
          return
        end

        debug 'Starting metrics'

        @sets = {
          system: CpuMemSet,
          vm: VMSet,
          breakdown: BreakdownSet,
          transaction: TransactionSet
        }.each_with_object({}) do |(key, kls), sets|
          debug "Adding metrics collector '#{kls}'"
          sets[key] = kls.new(config)
        end

        @timer_task = Concurrent::TimerTask.execute(
          run_now: true,
          execution_interval: config.metrics_interval,
          timeout_interval: TIMEOUT_INTERVAL
        ) do
          begin
            debug 'Collecting metrics'
            collect_and_send
            true
          rescue StandardError => e
            error 'Error while collecting metrics: %e', e.inspect
            debug { e.backtrace.join("\n") }
            false
          end
        end

        @running = true
      end

      def stop
        return unless running?

        debug 'Stopping metrics'

        @timer_task.shutdown
        @running = false
      end

      def running?
        !!@running
      end

      def get(key)
        sets.fetch(key)
      end

      def collect_and_send
        return unless @config.recording?
        metricsets = collect
        metricsets.compact!
        metricsets.each do |m|
          callback.call(m)
        end
      end

      def collect
        sets.each_value.each_with_object([]) do |set, arr|
          samples = set.collect
          next unless samples
          arr.concat(samples)
        end
      end
    end
  end
end

require 'elastic_apm/metricset'

require 'elastic_apm/metrics/metric'
require 'elastic_apm/metrics/set'

require 'elastic_apm/metrics/cpu_mem_set'
require 'elastic_apm/metrics/vm_set'
require 'elastic_apm/metrics/span_scoped_set'
require 'elastic_apm/metrics/transaction_set'
require 'elastic_apm/metrics/breakdown_set'
