class CloudFrontClient
	# 公式APIリファレンス
	# https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Client.html

	attr_reader :client
	attr_accessor :default_distribution_id

	def initialize(default_distribution_id = nil)
		aws_config = Rails.application.credentials.config[:aws]
		@client = Aws::CloudFront::Client.new(
			region: 'ap-northeast-1',
			access_key_id: aws_config[:access_key_id],
			secret_access_key: aws_config[:secret_access_key],
		)
		@default_distribution_id = aws_config[:cloud_front][:distribution][:files][:distribution_id] if default_distribution_id.blank?
	end

	def create_invalidation(*target_paths)
		@client.create_invalidation({
			distribution_id: @default_distribution_id,
			invalidation_batch: {
				paths: {
					quantity: target_paths.length,
					items: target_paths,
				},
				caller_reference: unix_time_stamp,
			},
		})
	end

	private
		def unix_time_stamp
			Time.now.to_i.to_s + '-' + SecureRandom.hex(4)
		end
end