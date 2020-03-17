# frozen_string_literal: true

module ElasticAPM
  # @api private
  class Metadata
    def initialize
      @service = ServiceInfo.new
      @process = ProcessInfo.new
      @system = SystemInfo.new
      @labels = config.global_labels
    end

    attr_reader :service, :process, :system, :labels

    private

    def config
      ElasticAPM.config
    end
  end
end

require 'elastic_apm/metadata/service_info'
require 'elastic_apm/metadata/system_info'
require 'elastic_apm/metadata/process_info'
