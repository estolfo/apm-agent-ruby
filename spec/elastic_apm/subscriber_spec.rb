# frozen_string_literal: true

enable = false
begin
  require 'active_support/notifications'
  enable = true
rescue LoadError
  puts '[INFO] Skipping Subscriber spec'
end

if enable
  require 'elastic_apm/subscriber'

  module ElasticAPM
    RSpec.describe Subscriber, :mock_intake do
      let(:config) { Config.new }

      before do
        MockIntake.stub!
        ElasticAPM.start(config)
      end

      after { ElasticAPM.stop }

      subject { Subscriber.new }

      describe '#register!' do
        it 'subscribes to AS::Notifications' do
          expect(ActiveSupport::Notifications)
            .to receive(:subscribe).with(Regexp, subject)
          subject.register!
        end

        it 'unregisters first if already registered' do
          allow(ActiveSupport::Notifications)
            .to receive(:unsubscribe).and_call_original

          subject.register!
          subject.register!

          expect(ActiveSupport::Notifications)
            .to have_received(:unsubscribe)

          subject.unregister! # clean up
        end
      end

      describe 'AS::Notifications API' do
        it 'adds spans from notifications', :intercept do
          ElasticAPM.start_transaction 'Test'

          subject.start(
            'process_action.action_controller',
            'id-1',
            controller: 'UsersController', action: 'index'
          )

          span = ElasticAPM.current_span
          expect(span).to be_running
          expect(span.name).to eq 'UsersController#index'

          subject.finish(
            'process_action.action_controller',
            'id-1',
            nil
          )

          ElasticAPM.end_transaction

          expect(span).to_not be_running
          expect(span).to be_stopped
        end

        context 'with unknown notifications' do
          let(:config) { Config.new(disable_send: true) }

          it 'ignores unknown notifications' do
            subject = Subscriber.new
            ElasticAPM.start_transaction 'Test'

            expect do
              subject.start('unknown.notification', nil, {})
            end.to_not change(ElasticAPM, :current_span)
          end
        end
      end
    end
  end
end
