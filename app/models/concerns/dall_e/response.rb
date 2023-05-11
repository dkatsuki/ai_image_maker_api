# https://platform.openai.com/docs/guides/error-codes/python-library-error-types

require 'base64'

module DallE
  class Response
    @@tmp_storage = Rails.root.to_s + '/tmp/dall_e'

    attr_reader :data, :response_format, :error_message, :error_type, :error_code

    def self.tmp_storage
      @@tmp_storage
    end

    def initialize(raw_response)
      if raw_response['error'].present? || raw_response['data'].blank?
        handle_error_response(raw_response)
      else
        handle_success_response(raw_response)
      end
    end

    def error?
      @is_error
    end

    def success?
      !self.error?
    end

    private

      def handle_error_response(raw_response)
        @is_error = true
        @data = nil
        @response_format = 'error'
        @error_code = raw_response.dig('error', 'code')
        @error_type = raw_response.dig('error', 'type')
        @original_error_message = raw_response.dig('error', 'message')
        @error_message = generate_error_message
      end

      def handle_success_response(raw_response)
        @is_error = false
        @error_code = nil
        @error_type = nil
        @original_error_message = nil
        @error_message = nil

        @response_format = raw_response.dig('data', 0, 'url').present? ? 'url' : 'b64_json';
        @data = generate_data(raw_response)
      end

      def generate_error_message
        case @error_type
        when nil
          nil
        when 'invalid_request_error'
          DeepLClient.new.to_japanese(@original_error_message)
        when 'api_error', 'service_unavailable_error'
          '何らかの理由により処理に失敗しました。何度も続く場合はお問合せフォームよりご連絡ください。'
        when 'rate_limit_error', 'api_connection_error', 'authentication_error'
          '何らかの理由により処理に失敗しました。お問合せフォームよりご連絡ください。'
        when 'time_out'
          'タイムアウトにより処理が失敗しました。再度お試しください。'
        else
          '何らかの理由により処理に失敗しました。何度も続く場合はお問合せフォームよりご連絡ください。'
        end
      end

      def generate_data(raw_response)
        if @response_format == 'url'
          raw_response['data'].map do |data|
            data['url']
          end
        elsif @response_format == 'b64_json'
          raw_response['data'].map do |data|
            base64_string = data['b64_json']
            binary = Base64.decode64(base64_string)
            path = write_image(binary)
            path
          end
        else
          raise RuntimeError, 'response_formatが不正です'
        end
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
end
