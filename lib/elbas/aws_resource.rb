module Elbas
  class AWSResource
    require 'active_support/all'

    include Capistrano::DSL
    include Elbas::AWS::AutoScaling
    include Elbas::AWS::EC2
    include Elbas::Retryable
    include Logger

    attr_reader :aws_counterpart, :autoscaling_group_name

    def initialize(autoscaling_group_name)
      @autoscaling_group_name = autoscaling_group_name
    end

    def cleanup(&block)
      items = trash || []
      block.call
      destroy(items)
      self
    end

    private

    def base_ec2_instance_id
      @_base_ec2_instance_id ||= autoscaling_group(autoscaling_group_name).instances.first.instance_id
    end

    def environment
      fetch(:aws_environment_base_name, 'production')
    end

    def timestamp(str)
      "#{str}-#{Time.now.to_i}"
    end

    def deployed_with_elbas?(resource)
      resource.tags.any? { |tag| tag.key.downcase == 'deployed-with' && tag.value.downcase == 'elbas' } &&
      resource.tags.any? { |tag| tag.key.downcase == 'elbas-deploy-group' && tag.value.downcase == autoscaling_group_name.downcase }
    end

  end
end
