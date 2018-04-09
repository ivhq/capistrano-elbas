module Elbas
  module AWS
    module AutoScaling
      extend ActiveSupport::Concern
      include Elbas::AWS::Credentials
      include Capistrano::DSL

      def autoscaling
        @_autoscaling ||= ::Aws::AutoScaling::Resource.new(autoscaling_client)
      end

      def autoscaling_client
        @_autoscaling_client ||= ::Aws::AutoScaling::Client.new(credentials)
      end

      def autoscaling_group(autoscaling_group_name)
        @_autoscaling_groups ||= {}
        @_autoscaling_groups[autoscaling_group_name] ||= autoscaling.group(autoscaling_group_name)
      end
    end
  end
end
