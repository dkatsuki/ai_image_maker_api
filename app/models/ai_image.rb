class AiImage < ApplicationRecord
  @@files_domain = Rails.application.credentials.config[:files_domain]
  attr_accessor :tmp_file_path
  attr_reader :generate_image_response

  before_validation :generate_from_spell, if: -> { self.new_record? && !self.generated_image? }

  validates :spell, presence: { message: '画像生成用テキストは必須です。' }
  validates :width, presence: { message: '生成した画像のurlの横幅は必須です。' }
  validates :height, presence: { message: '生成した画像のurlの高さは必須です。' }
  validates :extension, presence: { message: '生成した画像の拡張子は必須です。' }
  validate :spell, :validate_generating_image, if: -> { self.generated_image? }

  after_save :put_image_to_s3, if: -> { self.generated_image? }

  def self.search(params)
    self.all
  end

  def self.generater
    @@generater ||= DallE::Client.new
  end

  def self.new_multiple(spell: nil, width: 256, height: 256, n: 2)
    self.generater.generate_images(spell, width: width, height: height, n: n).map do |response|
      record = self.new(spell: spell, width: width, height: height)
      record.tmp_file_path = path
      record
    end
  end

  def self.attributes_japanese_names_list
    {
      spell: '画像生成用テキスト',
    }
  end

  def self.get_japanese_attribute_name(attribute_name)
    self.attributes_japanese_names_list[attribute_name.to_sym]
  end

  def spell=(spell)
    super(spell)
    self.write_attribute(:spell_length, spell.length)
  end

  def spell_length=
    raise RuntimeError, '"spell_length" will be set by spell= method.'
  end

  def generated_image?
    @generate_image_response.present?
  end

  def generater
    self.class.generater
  end

  def s3_client
    @s3_client ||= S3Client.new
  end

  def generate_from_spell(spell = nil)
    return false unless (!!spell || !!self.spell)
    @generate_image_response = self.generater.generate_image(
      self.spell,
      width: self.width,
      height: self.height,
      response_format: 'b64_json',
    )

    if @generate_image_response.success?
      self.tmp_file_path = @generate_image_response.data.first
      self.extension = File.extname(self.tmp_file_path)
    end
  end

  def put_image_to_s3
    throw(RuntimeError, 'tmp_file_path is blank.') if @tmp_file_path.blank?
    extension = File.extname(@tmp_file_path)
    binary = File.open(@tmp_file_path, 'rb').read
    self.s3_client.put_object(file_name: self.image_key, body: binary)
  end

  def image_key
    @image_key ||= if self.id.present?
        "ai_images/#{self.id}#{self.extension}"
      else
        nil
      end
  end

  def image_source
    @image_source ||= if self.image_key.present?
        "https://#{@@files_domain}/#{self.image_key}"
      else
        nil
      end
  end

  private
    def validate_generating_image
      if @generate_image_response.present?
        if @generate_image_response.error?
          errors.add(:spell, @generate_image_response.error_message)
        end
      end
    end

end
