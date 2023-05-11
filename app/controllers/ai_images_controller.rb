class AiImagesController < ApplicationController

  def create
    ai_image = AiImage.create(strong_parameters)
    render json: {body: ai_image.to_json_with(params[:to_json_option])}
  end

  def create_multiple_pattern_image_records
    spell, width, height, n = params[:ai_image].values_at(:spell, :width, :height, :n)
    ai_images = self.model.new_multiple(spell: spell, width: width, height: height, n: n.to_i)

    response_body = []

    ai_images.each do |ai_image|
      if ai_image.save
        response_body << ai_image.to_json_with(params[:to_json_option])
      else
        response_body << ai_image.errors.full_messages
      end
    end

    render json: {body: response_body}
  end

  def strong_parameters
    attribute_names = self.model.attribute_names.map {|e| e.to_sym}
    attribute_names = attribute_names.reject { |element| element == :spell_length }
    params.require(:ai_image).permit(attribute_names)
  end
end
