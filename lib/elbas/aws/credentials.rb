module Elbas
  module AWS
    module Credentials
      extend ActiveSupport::Concern
      include Capistrano::DSL

      def credentials
        @_credentials ||= begin
          _credentials = {}

          if fetch(:aws_access_key_id, ENV['AWS_ACCESS_KEY_ID']).present?
            _credentials.merge! access_key_id: fetch(:aws_access_key_id, ENV['AWS_ACCESS_KEY_ID'])
          end

          if fetch(:aws_secret_access_key, ENV['AWS_SECRET_ACCESS_KEY']).present?
            _credentials.merge! secret_access_key: fetch(:aws_secret_access_key, ENV['AWS_SECRET_ACCESS_KEY'])
          end

          _credentials.merge! region: fetch(:aws_region) if fetch(:aws_region)
          _credentials
        end
      end
    end
  end
end
