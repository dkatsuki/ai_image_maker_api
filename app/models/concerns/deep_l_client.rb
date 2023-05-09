# https://github.com/wikiti/deepl-rb#deepl-for-ruby
require 'deepl'

class DeepLClient

  def initialize(api_version = 'v2')
    setup_auth(api_version)
  end

  def language_list
    return @language_list if @language_list.present?
    @languages ||= self.fetch_all_languages
    @language_list = @languages.map {|language| [language.code, language.name]}.to_h
  end

  def fetch_all_languages
    @languages = DeepL.languages
  end

  def translate(text, base_language_code, to_language_code)
    translation = fetch_translation_instance(text, base_language_code, to_language_code)
    translation.text
  end

  def translate_auto(text, to_language_code)
    translation = fetch_translation_instance(text, nil, to_language_code)
    translation.text
  end

  def estimate_language(text)
    translation = fetch_translation_instance(text, nil, 'EN')
    self.language_list[translation.detected_source_language]
  end

  def to_english(text, base_language_code = 'JA')
    self.translate(text, base_language_code, 'EN')
  end

  def to_japanese(text, base_language_code = 'EN')
    self.translate(text, base_language_code, 'JA')
  end

  private
    def fetch_translation_instance(text, base_language_code, to_language_code)
      DeepL.translate(text, base_language_code, to_language_code)
    end

    def setup_auth(api_version)
      DeepL.configure do |config|
        enviroment = Rails.application.credentials.deep_l
        config.auth_key = enviroment[:api_key]
        config.host = "https://#{enviroment[:api_domain]}"
        config.version = api_version # Default value is 'v2'
      end
    end
end