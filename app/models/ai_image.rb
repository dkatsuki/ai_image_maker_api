class AiImage < ApplicationRecord
  attr_reader :tmp_file_path

  validates :spell, presence: { message: '画像生成用テキストは必須です。' }
  validates :width, presence: { message: '生成した画像のurlの横幅は必須です。' }
  validates :height, presence: { message: '生成した画像のurlの高さは必須です。' }
  validates :extension, presence: { message: '生成した画像の拡張子は必須です。' }
  before_validation :generate_from_spell, if: -> { self.new_record? && !self.generated_image? }
  after_save :put_image_to_s3, if: -> { self.generated_image? }

  def self.search(params)
    self.all
  end

  def self.generater
    @@generater ||= DallE.new
  end

  def new_multiple_records(params)
    spell, width, height, n = params.values_at(:spell, :width, :height, :n)
    self.generater.generate_images(spell, width: width, height: height, n: n).map do |path|
      record = self.new(spell: spell, width: width, height: height)
      record.tmp_file_path = path
      record
    end
  end

  def generated_image?
    self.tmp_file_path.present?
  end

  def generater
    self.class.generater
  end

  def s3_client
    @s3_client ||= S3Client.new
  end

  def generate_from_spell(spell = nil)
    return false unless (!!spell || !!self.spell)
    @tmp_file_path = self.generater.generate_image(self.spell, width: self.width, height: self.height)
    self.extension = File.extname(@tmp_file_path)
  end

  def put_image_to_s3
    throw(RuntimeError, 'tmp_file_path is blank.') if @tmp_file_path.blank?
    extension = File.extname(@tmp_file_path)
    binary = File.open(@tmp_file_path, 'rb').read
    self.s3_client.put_object(file_name: self.image_key, body: binary)
  end

  def image_key
    @image_key ||= if self.id.present?
        "ai_images/#{self.id}.#{self.extension}"
      else
        nil
      end
  end

  private
    def set_tmp_file_path(path)
      @tmp_file_path = path
    end
end
