module Elbas
  module AWS
    module EC2
      extend ActiveSupport::Concern
      include Capistrano::DSL

      def ec2
        @_ec2 ||= ::Aws::EC2::Resource.new(client: ec2_client)
      end

      def ec2_client
        @_ec2_client ||= ::Aws::EC2::Client.new(region: fetch(:aws_region))
      end
    end
  end
end
