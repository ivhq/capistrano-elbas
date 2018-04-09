module Elbas
  class LaunchConfiguration < AWSResource

    attr_reader :image_id, :autoscaling_group_name

    def self.create(ami, autoscaling_group_name, &block)
      lc = new(ami.aws_counterpart.id, autoscaling_group_name)
      lc.cleanup do
        lc.save
        block.call(lc)
      end
    end

    def initialize(image_id, autoscaling_group_name)
      @image_id = image_id
      @autoscaling_group_name = autoscaling_group_name
    end

    def save
      info "Creating an EC2 Launch Configuration for AMI: #{image_id}"
      with_retry do
        autoscaling.create_launch_configuration(create_options)
      end
    end

    def name
      @name ||= timestamp(launch_config_base_name)
    end

    def attach_to_autoscaling_group!
      info 'Attaching Launch Configuration to AutoScaling Group'
      current_autoscaling_group.update(launch_configuration_name: name)
    end

    def destroy(launch_configurations = [])
      launch_configurations.each do |lc|
        info "Deleting old launch configuration: #{lc}"
        autoscaling.client.delete_launch_configuration(launch_configuration_name: lc)
      end
    end

    private

    def current_autoscaling_group
      autoscaling_group(autoscaling_group_name)
    end

    def base_launch_config
      autoscaling.launch_configuration(current_autoscaling_group.launch_configuration_name)
    end

    def launch_config_base_name
      "elbas-#{environment}-#{autoscaling_group_name}"
    end

    def instance_type
      fetch(:aws_autoscale_instance_type, base_launch_config.instance_type)
    end

    def create_options
      options = {
        launch_configuration_name: name,
        image_id: image_id,
        instance_type: instance_type,
        associate_public_ip_address: base_launch_config.associate_public_ip_address,
        ebs_optimized: base_launch_config.ebs_optimized,
        security_groups: base_launch_config.security_groups,
        instance_monitoring: base_launch_config.instance_monitoring
      }

      options[:iam_instance_profile] = base_launch_config.iam_instance_profile if base_launch_config.iam_instance_profile.present?
      options[:key_name] = base_launch_config.key_name if base_launch_config.key_name.present?
      options[:spot_price] = base_launch_config.spot_price if base_launch_config.spot_price.present?
      options[:user_data] = base_launch_config.user_data if base_launch_config.user_data.present?

      options
    end

    def deployed_with_elbas?(c)
      c.include?(launch_config_base_name)
    end

    def trash
      configs = autoscaling.launch_configurations.map(&:launch_configuration_name)
      configs.select { |c| deployed_with_elbas?(c) }
    end

  end
end
