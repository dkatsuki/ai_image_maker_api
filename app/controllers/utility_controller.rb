class UtilityController < ApplicationController

  def test
    render json: {status: 'ok'}
  end

end
