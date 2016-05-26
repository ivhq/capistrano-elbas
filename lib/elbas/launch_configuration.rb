module Elbas
  class LaunchConfiguration < AWSResource

    attr_reader :image_id

    def self.create(ami, &block)
      lc = new(ami.aws_counterpart.id)
      lc.cleanup do
        lc.save
        yield lc
      end
    end

    def initialize(image_id)
      @image_id = image_id
    end

    def save
      info "Creating an EC2 Launch Configuration for AMI: #{image_id}"
      with_retry do
        # @aws_counterpart = autoscaling.launch_configurations.create(name, image_id, instance_type, create_options)
        @aws_counterpart = autoscaling.client.create_launch_configuration(create_options)
      end
    end

    def attach_to_autoscale_group!
      info 'Attaching Launch Configuration to AutoScale Group'
      autoscale_group.update(launch_configuration: aws_counterpart)
    end

    def destroy(launch_configurations = [])
      launch_configurations.each do |lc|
        info "Deleting old launch configuration: #{lc.name}"
        lc.delete
      end
    end

    private

    def base_launch_config
      launch_configs = autoscaling.client.describe_launch_configurations(
        launch_configuration_names: [autoscale_group.launch_configuration_name]
      )
      launch_configs[:launch_configurations].first
    end

    def launch_config_base_name
      "elbas-#{environment}-#{autoscale_group_name}"
    end

    def name
      @name ||= timestamp(launch_config_base_name)
    end

    def instance_type
      fetch(:aws_autoscale_instance_type, base_launch_config[:instance_type])
    end

    def create_options
      options = {
        launch_configuration_name: name,
        image_id: image_id,
        instance_type: instance_type,
        associate_public_ip_address: base_launch_config[:associate_public_ip_address],
        ebs_optimized: base_launch_config[:ebs_optimized],
        security_groups: base_launch_config[:security_groups],
        instance_monitoring: base_launch_config[:instance_monitoring]
      }

      options[:block_device_mappings] = base_launch_config[:block_device_mappings] if base_launch_config[:block_device_mappings].present?
      options[:iam_instance_profile] = base_launch_config[:iam_instance_profile] if base_launch_config[:iam_instance_profile].present?
      options[:key_name] = base_launch_config[:key_name] if base_launch_config[:key_name].present?
      options[:spot_price] = base_launch_config[:spot_price] if base_launch_config[:spot_price].present?
      options[:user_data] = base_launch_config[:user_data] if base_launch_config[:user_data].present?

      info "Launch configuration options: #{options}"

      abort

      options
    end

    def deployed_with_elbas?(lc)
      lc.name.include? launch_config_base_name
    end

    def trash
      autoscaling.launch_configurations.to_a.select do |lc|
        deployed_with_elbas? lc
      end
    end

  end
end
