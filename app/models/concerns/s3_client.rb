class S3Client
	# 公式APIリファレンス
	# https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Client.html

	attr_reader :client, :next_objects_token
	attr_accessor :default_bucket_name

	def initialize(default_bucket_name = nil, region = 'ap-northeast-1')
		aws_config = Rails.application.credentials.config[:aws]

		@client = Aws::S3::Client.new(
			region: region,
			access_key_id: aws_config[:access_key_id],
			secret_access_key: aws_config[:secret_access_key],
		)

		@next_object_list = nil
		@default_bucket_name = aws_config[:s3][:bucket][:files][:name]
		@cloud_front_client = CloudFrontClient.new
	end

	def create_bucket(name)
		@client.create_bucket(bucket: name)
	end

	def delete_bucket(name)
		return false if name.include?('izzetnews')
		@client.delete_bucket(bucket: name)
	end

	def get_objects(bucket: nil, prefix: nil, next_objects_token: nil)
		if next_objects_token.present?
			@next_objects_token = next_objects_token
		end

		bucket = @default_bucket_name if bucket.blank?
		return false if bucket.blank?

		if prefix.present? && next_objects_token.present?
			object_list = @client.list_objects_v2(bucket: bucket, prefix: prefix, continuation_token: next_objects_token)
		elsif prefix.present?
			object_list = @client.list_objects_v2(bucket: bucket, prefix: prefix)
		elsif @next_objects_token.present?
			object_list = @client.list_objects_v2(bucket: bucket, continuation_token: @next_objects_token)
		else
			object_list = @client.list_objects_v2(bucket: bucket)
		end

		@next_objects_token = object_list.next_continuation_token
		object_list.contents
	end

	def get_object(bucket: nil, file_name: nil)
		bucket = @default_bucket_name if bucket.blank?
		return false if bucket.blank?
		@client.get_object(bucket: bucket, key: file_name).body
	end

	def delete_object(bucket: nil, file_name: nil)
		bucket = @default_bucket_name if bucket.blank?
		return false if bucket.blank?
		raise RuntimeError.new('You must not touch "izzet news" bucket on this application!!!!!') if bucket.include?('izzetnews')
		@client.delete_object(bucket: bucket, key: file_name)
	end

	def put_object(bucket: nil, file_name: nil, body: nil, acl: 'private')
		bucket = @default_bucket_name if bucket.blank?
		return false if bucket.blank? || file_name.blank?
		is_old_file_exist = file_exist?(file_name: file_name, bucket: bucket)
		response = @client.put_object(bucket: bucket, key: file_name, body: body)
		@cloud_front_client.create_invalidation('/' + file_name) if is_old_file_exist
		response
	end

	def search_file_names(bucket: nil, prefix: nil)
		bucket = @default_bucket_name if bucket.blank?

		file_names = []

		object_list = @client.list_objects_v2(bucket: @default_bucket_name, prefix: prefix)
		object_list.contents.each do |object|
			file_names << object.key
		end

		while object_list.is_truncated
			object_list = @client.list_objects_v2(bucket: @default_bucket_name, prefix: prefix, continuation_token: object_list.next_continuation_token)
			object_list.contents.each do |object|
				file_names << object.key
			end
		end
		file_names
	end

	def get_meta_data(bucket: nil, file_name: nil)
		bucket = @default_bucket_name if bucket.blank?
		begin
			@client.head_object({
				bucket: bucket,
				key: file_name,
			}).to_h.merge({result: true})
		rescue => e
			{result: false}
		end
	end

	def file_exist?(file_name: nil, bucket: nil)
		bucket = @default_bucket_name if bucket.blank?
		begin
			!!client.get_object_acl(bucket: bucket, key: file_name)
		rescue => exception
			false
		end
	end

	private
end