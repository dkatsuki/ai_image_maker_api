require 'securerandom'
# MiniMagick official repo => https://github.com/minimagick/minimagick

module ImageAttachment
  extend ActiveSupport::Concern
  attr_reader :tmp_images

  included do
    after_save :retouch_images, :send_images_to_s3
    after_destroy :delete_image_from_s3
  end

  module ClassMethods
    # ここに定義したメソッドはクラスメソッドとしてincludeされる
    @@files_domain = Rails.application.credentials.config[:files_domain]

    def image_config
      {bucket_name: @@files_bucket}
    end

    def files_domain
      @@files_domain
    end

    def save_binary_to_system_tmp(binary, extension)
      extension.gsub!(/\./, '')
      tmp_file_path = "/tmp/#{SecureRandom.uuid}.#{extension}"
      File.open(tmp_file_path, 'wb') { |file| file.print(binary) }
      tmp_file_path
    end

    def new_action_dispatch(file_path)
      ActionDispatch::Http::UploadedFile.new(
        filename: File.basename(file_path),
        type: "image/#{File.extname(file_path)}",
        tempfile: File.open(file_path, 'rb')
      )
    end

    def get_binary_from(source)
      HttpClient.new.get_image(source)
    end
  end

  def set_up_image(attribute_name, action_dispatch)
    attribute_name = attribute_name.to_sym
    @tmp_images = {} unless @tmp_images
		self.send("#{attribute_name}=", action_dispatch.original_filename)
    image = MiniMagick::Image.open(action_dispatch.tempfile.path)
    image.format('jpeg')
    @tmp_images[attribute_name] = image
  end

  def set_up_images(attributes)
		attributes.each do |attribute_name, value|
      set_up_image(attribute_name, value) if value.is_a?(ActionDispatch::Http::UploadedFile)
    end
  end

  def retouch_images
    # if you wanna retouch images, override this method and define process in the method.
  end

  def send_images_to_s3
    return true if @tmp_images.blank? #after_saveでfalse返すとsave失敗しちゃうので
    s3_client = S3Client.new
		@tmp_images.each do |key, image|
      s3_key = make_s3_key(key)
      s3_client.put_object(file_name: s3_key, body: image.to_blob)
      self.update_column(key.to_sym, s3_key) if self.class.has_attribute?(key) #もう一回saveするとまたコールバック呼んじゃうから嫌
    end
    @tmp_images = {}
	end

  def delete_image_from_s3
    s3_client = S3Client.new
    self.attribute_names.each do |attribute_name|
      if attribute_name.include?('image')
        if self.send(attribute_name).present?
          s3_client.delete_object(file_name: self.send(attribute_name))
        end
      end
    end
	end

  def attributes=(attributes)
    super(attributes)
    set_up_images(attributes)
  end

  def assign_attributes(attributes)
    super(attributes)
    set_up_images(attributes)
	end

  def set_image_file_as_action_dispatch_to_image_key(file_path)
    set_image_file_as_action_dispatch_to(:image_key, file_path)
  end

  def set_image_file_as_action_dispatch_to(attribute_name, file_path)
    attribute_name = attribute_name.to_sym
    action_dispatch = ActionDispatch::Http::UploadedFile.new(
      filename: File.basename(file_path),
      type: "image/#{File.extname(file_path)}",
      tempfile: File.open(file_path, 'rb')
    )
    set_up_image(attribute_name, action_dispatch)
  end

  def fetch_image_binary(image_source = nil)
    self.class.get_binary_from(image_source || self.image_source)
  end

  def image_source
    if self.image_key.present?
      "https://#{self.class.files_domain}/#{self.image_key}"
    else
      ''
    end
  end

  private
    def make_s3_key(attribute_name)
      attribute_name = attribute_name.to_s
      result = self.class.name.tableize
      result = result + '/' + attribute_name if attribute_name != 'image_key'
      result = result + '/' + self.id.to_s + ".jpeg"
    end
end