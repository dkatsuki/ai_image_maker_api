# https://platform.openai.com/docs/guides/error-codes/python-library-error-types

module DallE
  class Response
    attr_reader :data, :response_format, :error_message, :error_type, :error_code

    def initialize(raw_response)
      @is_error = raw_response['error'].present? || response['data'].blank?

      if @is_error
        @data = nil
        @response_format = 'error'
        @error_code = raw_response.dig('error', 'code')
        @error_type = raw_response.dig('error', 'type')
        @original_error_message = raw_response.dig('error', 'message')
        @error_message = case @error_type
          when nil
            nil
          when 'invalid_request_error'
            # 現在判明しているリクエストエラーの種類
            ## prompt長すぎ
            ## 安全フィルタに引っかかったよ
            DeepLClient.new.to_japanese(@original_error_message)
          when 'api_error', 'service_unavailable_error'
            # 基本的にopen ai側が原因
            '何らかの理由により処理に失敗しました。何度も続く場合はお問合せフォームよりご連絡ください。'
          when 'rate_limit_error', 'api_connection_error', 'authentication_error'
            # 基本的にこっち側が原因だからすぐ問い合わせて欲しい
            '何らかの理由により処理に失敗しました。お問合せフォームよりご連絡ください。'
          when 'time_out'
            'タイムアウトにより処理が失敗しました。再度お試しください。'
          else
            '何らかの理由により処理に失敗しました。何度も続く場合はお問合せフォームよりご連絡ください。'
          end
      else
        @response_format = response.dig('data', 0, 'url').present? ? 'url' : 'b64_json';

        @data = if @response_format == 'url'
          raw_response['data'].map do |data|
            data['url']
          end
        elsif @response_format == 'b64_json'
          raw_response['data'].map do |data|
            base64_string = response.dig('data', 0, response_format)
            binary = Base64.decode64(base64_string)
            path = write_image(binary)
          end
        else
          raise RuntimeError, 'response_formatが不正です'
        end

        @error_code = nil
        @error_type = nil
        @original_error_message = nil
        @error_message = nil
      end
    end

    def error?
      @is_error
    end

    def ok?
      !self.error?
    end
  end
end