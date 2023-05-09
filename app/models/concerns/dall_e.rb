# ドキュメント
# https://platform.openai.com/docs/guides/chat/introduction
# https://platform.openai.com/docs/api-reference/images/create
# https://github.com/alexrudall/ruby-openai

require 'base64'

class DallE
  attr_accessor :api_key
  attr_reader :client, :http
  @@tmp_storage = Rails.root.to_s + '/tmp/dall_e'

  def @@tmp_storage.join(string)
    @@tmp_storage + string
  end

  def self.tmp_storage
    @@tmp_storage
  end

  def initialize
    @client = OpenAI::Client.new
    @http = HttpClient.new
  end

  def generate_image(prompt, size: 256, response_format: 'b64_json') # response_format: 'url' or ''b64_json''
    response = @client.images.generate(parameters: {
      prompt: prompt,
      size: "#{size}x#{size}",
      response_format: response_format
    })

    if response['error'].present?
      return response
    end

    if response_format == 'b64_json'
      base64_string = response.dig('data', 0, response_format)
      binary = Base64.decode64(base64_string)
      path = write_image(binary)
    elsif response_format == 'url'
      url = response.dig('data', 0, response_format)
    else
      response
    end
  end

  def generate_images(prompt, size: 256, n:2)
    response = @client.images.generate(parameters: { prompt: prompt, size: "#{size}x#{size}", n: n })
    response['data'].map { |data| data['url'] }
  end

  def generate_and_save_image(prompt, size: 256)
    url = self.generate_image(prompt, size: size)
    path = download_and_save_image(url)
    path
  end

  def generate_image_valiations(image_path, n: 1)
    response = @client.images.variations(parameters: { image: image_path, n: 2 })
    response.dig('data', 0, 'url')
  end

  def edit_image(prompt = "A solid red Ruby on a blue background")
    response = @client.images.edit(parameters: { prompt: prompt, image: "image.png", mask: "mask.png" })
    # response.dig('data', 0, 'url')
  end

  private
    def download_and_save_image(url, to_path = nil)
      extention = get_extention(url)
      binary = self.http.get_image(url)
      to_path = @@tmp_storage + '/' + make_random_file_name(extention) if to_path.blank?
      File.open(to_path, 'wb') {|f| f.print(binary) }
      to_path
    end

    def get_extention(string)
      string = string.split('?').first if string.url? && string.include?('?')
      File.extname(string)
    end

    def make_random_file_name(extention)
      SecureRandom.hex(8) + extention
    end

    def write_image(binary)
      to_path = @@tmp_storage + '/' + make_random_file_name('.png')
      File.open(to_path, 'wb') do |f|
        f.print(binary)
      end
      to_path
    end
end