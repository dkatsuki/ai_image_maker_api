class TranslationsController < ApplicationController
  before_action :set_deep_l

  def to_english
    japanese_text = params[:text]
    english_text = @deep_l.to_english(japanese_text)
    render json: {text: english_text}
  end

  def to_japanese
    english_text = params[:text]
    japanese_text = @deep_l.to_japanese(english_text)
    render json: {text: japanese_text}
  end

  private
    def set_deep_l
      @deep_l = DeepLClient.new
    end
end
