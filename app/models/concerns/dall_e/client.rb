# ドキュメント
# https://platform.openai.com/docs/guides/chat/introduction
# https://platform.openai.com/docs/api-reference/images/create
# https://github.com/alexrudall/ruby-openai

module DallE
  class Client
    attr_accessor :api_key
    attr_reader :client, :http

    def initialize
      @client = OpenAI::Client.new.images
      @http = HttpClient.new
    end

    def generate_image(prompt, width: 256, height: 256, response_format: 'b64_json') # response_format: 'url' or ''b64_json''
      response = @client.generate(parameters: {
        prompt: prompt,
        size: "#{width}x#{height}",
        response_format: response_format
      })

      response = DallE::Response.new(response)
      response
    end

    def generate_images(prompt, width: 256, height: 256, n:2, response_format: 'b64_json')
      response = @client.generate(parameters: {
        prompt: prompt,
        size: "#{width}x#{height}",
        n: n,
        response_format: response_format
      })

      DallE::Response.new(response)
    end

    def generate_image_valiations(image_path, n: 1)
      response = @client.variations(parameters: { image: image_path, n: 2 })
      response.dig('data', 0, 'url')
    end

    def edit_image(prompt)
      response = @client.edit(parameters: { prompt: prompt, image: "image.png", mask: "mask.png" })
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

      def get_response(raw_response)
      end
  end
end