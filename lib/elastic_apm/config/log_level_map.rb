# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# frozen_string_literal: true

module ElasticAPM
  class Config
    # @api private
    class LogLevelMap
      LEVELS = {
        debug: Logger::DEBUG,
        info: Logger::INFO,
        warn: Logger::WARN,
        error: Logger::ERROR,
        fatal: Logger::FATAL,
        trace: Logger::DEBUG,
        warning: Logger::WARN,
        critical: Logger::FATAL,
        off: Logger::FATAL
      }.freeze

      def call(value)
        if value.is_a?(Integer)
          return LEVELS.value?(value) ? value : Logger::INFO
        end
        LEVELS.fetch(value.to_sym, Logger::INFO)
      end
    end
  end
end
