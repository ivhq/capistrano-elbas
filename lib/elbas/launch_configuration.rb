module Elbas
  class LaunchConfiguration < AWSResource

    def self.create(ami, &block)
      lc = new
      lc.cleanup do
        lc.save(ami)
        yield lc
      end
    end

    def save(ami)
      info "Creating an EC2 Launch Configuration for AMI: #{ami.aws_counterpart.id}"
      with_retry do
        @aws_counterpart = autoscaling.launch_configurations.create(name, ami.aws_counterpart.id, instance_type, create_options)
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
        autoscale_group.launch_configuration
      end

      def base_security_group_ids
        base_launch_config.security_groups.map { |sg| sg.security_group_id }
      end

      def launch_config_base_name
        "elbas-#{environment}-#{autoscale_group_name}"
      end

      def name
        timestamp launch_config_base_name
      end

      def instance_type
        fetch(:aws_autoscale_instance_type, base_launch_config.instance_type)
      end

      def create_options
        options = {
          associate_public_ip_address: base_launch_config.associate_public_ip_address,
          detailed_instance_monitoring: base_launch_config.detailed_instance_monitoring,
          security_groups: base_security_group_ids
        }

        options.merge(block_device_mappings: base_launch_config.block_device_mappings) if base_launch_config.block_device_mappings.present?
        options.merge(iam_instance_profile: base_launch_config.iam_instance_profile) if base_launch_config.iam_instance_profile.present?
        options.merge(key_name: base_launch_config.key_name) if base_launch_config.key_name.present?
        options.merge(spot_price: base_launch_config.spot_price) if base_launch_config.spot_price.present?
        options.merge(user_data: base_launch_config.user_data) if base_launch_config.user_data.present?

        info "Creating launch configuration with options: #{options}"

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
