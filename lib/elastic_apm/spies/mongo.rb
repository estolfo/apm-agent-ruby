# frozen_string_literal: true

module ElasticAPM
  # @api private
  module Spies
    # @api private
    class MongoSpy
      def install
        ::Mongo::Monitoring::Global.subscribe(
          ::Mongo::Monitoring::COMMAND,
          Subscriber.new
        )
      end

      # @api private
      class Subscriber
        TYPE = 'db.mongodb.query'

        def initialize
          @events = {}
        end

        def started(event)
          push_event(event)
        end

        def failed(event)
          pop_event(event)
        end

        def succeeded(event)
          pop_event(event)
        end

        private

        def push_event(event)
          return unless ElasticAPM.current_transaction

          span =
            ElasticAPM.start_span(
              event.command_name.to_s,
              TYPE,
              context: build_context(event)
            )

          @events[event.operation_id] = span
        end

        def pop_event(event)
          return unless (curr = ElasticAPM.current_span)
          span = @events.delete(event.operation_id)

          curr == span && ElasticAPM.end_span
        end

        def build_context(event)
          # Some MongoDB commands are not on collections but rather db admin commands.
          # For these commands, the value at the `command_name` key is the integer 1.
          collection = event.command[event.command_name] unless event.command[event.command_name] == 1
          Span::Context.new(
            db: {
              instance: event.database_name,
              statement: (collection && "#{collection}.#{event.command_name}"),
              type: 'mongodb',
              user: nil
            }
          )
        end
      end
    end

    register 'Mongo', 'mongo', MongoSpy.new
  end
end
