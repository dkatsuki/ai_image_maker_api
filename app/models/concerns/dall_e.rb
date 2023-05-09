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

  def generate_image(prompt, width: 256, height: 256, response_format: 'b64_json') # response_format: 'url' or ''b64_json''
    response = @client.images.generate(parameters: {
      prompt: prompt,
      size: "#{width}x#{height}",
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

  def generate_images(prompt, width: 256, height: 256, n:2, response_format: 'b64_json')
    response = @client.images.generate(parameters: {
      prompt: prompt,
      size: "#{width}x#{height}",
      n: n,
      response_format: response_format
    })

    if response['error'].present?
      return response
    end

    if response_format == 'b64_json' || response_format == 'url'
      response['data'].map do |data|
        binary = Base64.decode64(data[response_format])
        path = write_image(binary)
      end
    else
      response
    end
  end

  def generate_image_valiations(image_path, n: 1)
    response = @client.images.variations(parameters: { image: image_path, n: 2 })
    response.dig('data', 0, 'url')
  end

  def edit_image(prompt)
    response = @client.images.edit(parameters: { prompt: prompt, image: "image.png", mask: "mask.png" })
    # response.dig('data', 0, 'url')
  end

  private
    def download_and_save_image(url, to_path = nil)
      extension = get_extension(url)
      binary = self.http.get_image(url)
      to_path = @@tmp_storage + '/' + make_random_file_name(extension) if to_path.blank?
      File.open(to_path, 'wb') {|f| f.print(binary) }
      to_path
    end

    def get_extension(string)
      string = string.split('?').first if string.url? && string.include?('?')
      File.extname(string)
    end

    def make_random_file_name(extension)
      SecureRandom.hex(8) + extension
    end

    def write_image(binary)
      to_path = @@tmp_storage + '/' + make_random_file_name('.png')
      File.open(to_path, 'wb') do |f|
        f.print(binary)
      end
      to_path
    end
end