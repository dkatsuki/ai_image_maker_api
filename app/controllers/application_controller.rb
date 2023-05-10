class ApplicationController < ActionController::API
  # include DeviseTokenAuth::Concerns::SetUserByToken
  attr_accessor :model

  def health_check
    render json: {health_check: 'ok'}
  end

  def get_card_title_class(suffix)
    "#{self.class_name_prefix}::#{suffix}".safe_constantize
  end

  def initialize
    super
    self.set_model
  end

  def set_model
    @model = self.class.name.gsub(/Controller$/, '').singularize.safe_constantize
  end

  def index
    records = self.model.search(params)
    render json: {body: self.model.to_json_with(records, params[:to_json_option])}
  end

  def show
    # 後で直す、eager_loadをactive record relationでオーバーライドしたい。
		query = if params[:associations].present?
        self.model.eager_load(params[:associations])
      else
        self.model
      end

    record = query.where(id: params[:id]).first

    if record
      render json: {body: record.to_json_with(params[:to_json_option])}
    else
      render json: {body: '存在しないページです。'}
    end
  end
end
