require 'elbas'

namespace :elbas do
  task :scale do
    if fetch(:aws_access_key_id, ENV['AWS_ACCESS_KEY_ID']).present?
      set :aws_access_key_id, fetch(:aws_access_key_id, ENV['AWS_ACCESS_KEY_ID'])
    end

    if fetch(:aws_secret_access_key, ENV['AWS_SECRET_ACCESS_KEY']).present?
      set :aws_secret_access_key, fetch(:aws_secret_access_key, ENV['AWS_SECRET_ACCESS_KEY'])
    end

    Elbas::AMI.create do |ami|
      $stdout.puts "** elbas: Created AMI: #{ami.aws_counterpart.id}"
      Elbas::LaunchConfiguration.create(ami) do |lc|
        $stdout.puts "** elbas: Created Launch Configuration: #{lc.aws_counterpart.name}"
        lc.attach_to_autoscale_group!
      end
    end

  end
end
