require 'aws-sdk-v1'
require 'capistrano/dsl'

load File.expand_path("../tasks/elbas.rake", __FILE__)

def autoscale(groupname, *args)
  include Capistrano::DSL
  include Elbas::AWS::AutoScaling

  autoscale_group   = autoscaling.groups[groupname]
  running_instances = autoscale_group.ec2_instances.filter('instance-state-name', 'running')

  set :aws_autoscale_group, groupname

  running_instances.each do |instance|
    hostname = instance.dns_name || instance.private_ip_address
    stdout.puts "** elbas: Adding server: #{hostname}"
    server(hostname, *args)
  end

  if running_instances.count > 0
    after('deploy', 'elbas:scale')
  else
    puts "** elbas: AMI could not be created because no running instances were found. Is your autoscale group name correct?"
  end
end
