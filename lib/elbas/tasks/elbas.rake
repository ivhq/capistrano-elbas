require 'elbas'

namespace :elbas do
  task :scale, :group_name do |task, args|
    if fetch(:aws_access_key_id, ENV['AWS_ACCESS_KEY_ID']).present?
      set :aws_access_key_id, fetch(:aws_access_key_id, ENV['AWS_ACCESS_KEY_ID'])
    end

    if fetch(:aws_secret_access_key, ENV['AWS_SECRET_ACCESS_KEY']).present?
      set :aws_secret_access_key, fetch(:aws_secret_access_key, ENV['AWS_SECRET_ACCESS_KEY'])
    end

    autoscaling_group_name = args[:group_name]

    raise '** elbas: Autocaling Group Name not provided as argument for task elbas:scale!' if autoscaling_group_name.nil?

    Elbas::AMI.create(autoscaling_group_name) do |ami|
      $stdout.puts "** elbas (#{autoscaling_group_name}): Created AMI: #{ami.aws_counterpart.id}"
      Elbas::LaunchConfiguration.create(ami, autoscaling_group_name) do |lc|
        $stdout.puts "** elbas(#{autoscaling_group_name}): Created Launch Configuration: #{lc.name}"
        lc.attach_to_autoscaling_group!
      end
    end

    task.reenable # Allow this task to be run multiple times
  end
end
