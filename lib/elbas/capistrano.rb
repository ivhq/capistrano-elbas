require 'aws-sdk'
require 'capistrano/dsl'

load File.expand_path("../tasks/elbas.rake", __FILE__)

def autoscale(autoscaling_group_name, *args)
  include Capistrano::DSL
  include Elbas::AWS::AutoScaling
  include Elbas::AWS::EC2

  instances    = autoscaling_group(autoscaling_group_name).instances
  instance_ids = instances.map(&:instance_id)

  deploy_instances = ec2.instances(
    filters: [
      {
        name: 'instance-state-name',
        values: ['running']
      }
    ],
    instance_ids: instance_ids
  )

  deploy_instances.each do |instance|
    hostname = instance.public_dns_name || instance.public_ip_address
    $stdout.puts "** elbas (#{autoscaling_group_name}): Adding server: #{hostname}"
    server(hostname, *args)
  end

  if deploy_instances.count > 0
    after :deploy, :finished do
      invoke 'elbas:scale', autoscaling_group_name
    end
    $stdout.puts "** elbas (#{autoscaling_group_name}): Scheduled AMI creation after deployment"
  else
    $stdout.puts "** elbas (#{autoscaling_group_name}): AMI could not be created because no running instances were found. Is your autoscale group name correct?"
  end
end
