module Elbas
  module AWS
    module EC2
      extend ActiveSupport::Concern
      include Elbas::AWS::Credentials
      include Capistrano::DSL

      def ec2
        @_ec2 ||= ::Aws::EC2::Resource.new(ec2_client)
      end

      def ec2_client
        @_ec2_client ||= ::Aws::EC2::Client.new(credentials)
      end
    end
  end
end
