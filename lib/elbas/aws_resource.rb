module Elbas
  class AWSResource
    require 'active_support/all'

    include Capistrano::DSL
    include Elbas::AWS::AutoScaling
    include Elbas::AWS::EC2
    include Elbas::Retryable
    include Logger

    attr_reader :aws_counterpart

    def cleanup(&block)
      items = trash || []
      yield
      destroy items
      self
    end

    private
      def base_ec2_instance
        @_base_ec2_instance ||= autoscale_group.ec2_instances.filter('instance-state-name', 'running').first
      end

      def environment
        fetch(:aws_environment_base_name, 'production')
      end

      def timestamp(str)
        "#{str}-#{Time.now.to_i}"
      end

      def deployed_with_elbas?(resource)
        resource.tags['Deployed-with'] == 'elbas' &&
          resource.tags['elbas-deploy-group'] == autoscale_group_name
      end
  end
end
