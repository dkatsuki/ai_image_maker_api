# https://developers.line.biz/ja/docs/messaging-api/sending-messages/
# https://github.com/line/line-bot-sdk-ruby
# https://github.com/line/line-bot-sdk-ruby/blob/master/lib/line/bot/client.rb

class LineBot
  def initialize(channel_name = :default)
    channel_name = channel_name.to_sym

    @client ||= Line::Bot::Client.new do |config|
      line_channel_enviroment = Rails.application.credentials.config[:line][:channels][channel_name]
      config.channel_secret = line_channel_enviroment[:secret]
      config.channel_token = line_channel_enviroment[:token]
    end
  end

  def signature_valid?(request)
    @client.validate_signature(request.body.read, request.env['HTTP_X_LINE_SIGNATURE'])
  end

  def get_events_from(request)
    @client.parse_events_from(request.body.read)
  end

  def get_user_id_from(line_bot_event)
    line_bot_event&.[]('source')&.[]('userId')
  end

  def message_event?(line_bot_event)
    line_bot_event.is_a?(Line::Bot::Event::Message)
  end

  def get_message_type(line_bot_message_event)
    case line_bot_message_event.type
    when Line::Bot::Event::MessageType::Text
      'text'
    when Line::Bot::Event::MessageType::Image
      'image'
    when Line::Bot::Event::MessageType::Video
      'video'
    when Line::Bot::Event::MessageType::Audio
      'audio'
    when Line::Bot::Event::MessageType::File
      'file'
    when Line::Bot::Event::MessageType::Location
      'location'
    when Line::Bot::Event::MessageType::Sticker
      'sticker'
    else
      nil
    end
  end

  def get_message_from(line_bot_message_event)
    line_bot_message_event.message['text']
  end

  def reply_text(line_bot_event, text)
    reply_token = get_reply_token_from(line_bot_event)
    @client.reply_message(reply_token, { type: 'text', text: text })
  end

  def reply_image(line_bot_event, url)
    reply_token = get_reply_token_from(line_bot_event)
    @client.reply_message(reply_token, {
      type: 'image',
      originalContentUrl: url,
      previewImageUrl: url
    })
  end

  private
    def get_reply_token_from(line_bot_event)
      line_bot_event['replyToken']
    end

end