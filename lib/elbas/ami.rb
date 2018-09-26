module Elbas
  class AMI < AWSResource
    include Taggable

    def self.create(autoscaling_group_name, &block)
      ami = new(autoscaling_group_name)
      ami.cleanup do
        ami.save
        ami.tag(
          'deployed-with' => 'elbas',
          'elbas-deploy-group' => autoscaling_group_name
        )
        block.call(ami)
      end
    end

    def save
      info "Creating EC2 AMI from EC2 Instance: #{base_ec2_instance_id}"
      # JH: This is the only way I found to create an image in the V2 SDK, e.g. using the lower-level Aws::EC2::Client API
      resp = ec2_client.create_image(
        name: name,
        instance_id: base_ec2_instance_id,
        no_reboot: fetch(:aws_no_reboot_on_create_ami, true)
      )
      @aws_counterpart = ec2.image(resp.image_id)
    end

    def destroy(images = [])
      image_ids = images.map(&:id)

      return if image_ids.blank?

      resp = ec2_client.describe_images(
        image_ids: image_ids,
      )

      resp.images.each do |i|
        image_id = i.image_id

        # JH: Sometimes block_device_mappings is an empty array
        if i.block_device_mappings.any?
          snapshot_id = i.block_device_mappings.first.ebs.snapshot_id
        end

        info "De-registering old AMI: #{image_id}"
        ec2_client.deregister_image(image_id: image_id)

        if snapshot_id.present?
          info "Deleting old AMI snapshot: #{image_id}"
          ec2_client.delete_snapshot(snapshot_id: snapshot_id)
        end
      end
    end

    private

    def name
      timestamp "#{environment}-ami"
    end

    def trash
      images = ec2.images(owners: ['self'])
      images.select { |ami| deployed_with_elbas?(ami) }
    end

  end
end
