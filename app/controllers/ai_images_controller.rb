class AiImagesController < ApplicationController

  def create
    ai_image = AiImage.new(strong_parameters)
    if ai_image.save
      render json: {body: ai_image.to_json_with(params[:to_json_option])}
    else
      render json: {body: ai_image.errors.full_messages}
    end
  end

  def create_multiple_pattern_image_records
    ai_images = self.model.new_multiple_records(strong_parameters)

    response_body = []

    ai_images.each do |ai_image|
      if ai_image.save
        response_body << ai_image
      else
        response_body << ai_image.errors.full_messages
      end
    end

    render json: {body: response_body.to_json}
  end

  def strong_parameters
    attribute_names = self.model.attribute_names.map {|e| e.to_sym}
    attribute_names << :n
    params.require(:ai_image).permit(attribute_names)
  end
end
