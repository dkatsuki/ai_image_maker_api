# ドキュメント
# https://platform.openai.com/docs/guides/chat/introduction
# https://github.com/alexrudall/ruby-openai

# finish_reasonに格納される可能性のある選択肢
# stop: API returned complete model output
# length: Incomplete model output due to max_tokens parameter or token limit
# content_filter: Omitted content due to a flag from our content filters
# null: API response still in progress or incomplete

class ChatGpt

  DEFAULT_MODEL = 'gpt-3.5-turbo'
  DEFAULT_TEMPERATURE = 0.7
  CONTINUE_MESSAGE = '続けてください'

  attr_accessor :model, :temperature
  attr_reader :history, :stashed_history

  def initialize(model: DEFAULT_MODEL, temperature: DEFAULT_TEMPERATURE)
    @model = DEFAULT_MODEL
    @temperature = DEFAULT_TEMPERATURE
    @continue_message = CONTINUE_MESSAGE
    @client = OpenAI::Client.new
    @history = []
    @stashed_history = []
  end

  def get_parameters
    {
      model: @model,
      messages: @history,
      temperature: @temperature,
    }
  end

  def remove_continue_message_from_history
    @history.delete_if do |message|
      (message['role'] == 'user') && (message['content'] ==  @continue_message)
    end
    @history
  end

  def chat(content)
    choice = self.request(content)
    finish_reason = choice['finish_reason']

    result = choice['message']['content']

    while finish_reason == 'length'
      choice = continue_chat
      finish_reason = choice['finish_reason']
      return false if (finish_reason.blank? || finish_reason == 'null' || finish_reason == 'content_filter')
      result += choice['message']['content']
    end

    self.remove_continue_message_from_history

    result
  end

  def clear_history
    @history = []
  end

  def stash_history
    return false if @history.blank?
    @stashed_history << [@history.dup]
    @history = []
  end

  private
    def request(content)
      begin
        @history << { 'role' => 'user', 'content' => content }
        response = @client.chat(parameters: self.get_parameters)
        choice = response['choices'].first
        @history << choice['message']
        choice
      rescue => exception
        binding.pry
      end
    end

    def continue_chat
      request(@continue_message)
    end
end