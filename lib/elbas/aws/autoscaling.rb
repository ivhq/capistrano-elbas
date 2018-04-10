module Elbas
  module AWS
    module AutoScaling
      extend ActiveSupport::Concern
      include Capistrano::DSL

      def autoscaling
        @_autoscaling_resource ||= ::Aws::AutoScaling::Resource.new(client: autoscaling_client)
      end

      def autoscaling_client
        @_autoscaling_client ||= ::Aws::AutoScaling::Client.new(region: fetch(:aws_region))
      end

      def autoscaling_group(autoscaling_group_name)
        @_autoscaling_groups ||= {}
        @_autoscaling_groups[autoscaling_group_name] ||= autoscaling.group(autoscaling_group_name)
      end
    end
  end
end
