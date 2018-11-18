class LinebotController < ApplicationController
  require 'line/bot'
  require 'open-uri'
  require 'rexml/document'

  protect_from_forgery :except => [:callback]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    events = client.parse_events_from(body)

    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = {
            type: 'text',
            text: event.message['text']
          }
          client.reply_message(event['replyToken'], message)
        
        #位置情報送信時
        when Line::Bot::Event::MessageType::Location
           message = {
            type: 'text',
            text: return_location_height(event.message)
            }
        else
            message = {
            type: 'text',
            text: "メッセージか位置情報を送ってね"
        }
        end
        @client.reply_message(event['replyToken'], message)
        render :nothing => true, status: :ok
      end
    }

    private
    
    def return_location_height(message)
        message = {type: 'text', text: "位置情報test"}
        # ret_msg = message['address'] + "の標高は"
        # lat = message['latitude']
        # lon = message['longitude']
        # body = open("http://lab.uribou.net/ll2h/?ll=#{lat},#{lon}", &:read)
        # doc = REXML::Document.new(body)
        # ret_msg += doc.elements['result/height'].text + "mです"
        # ret_msg
    end

    head :ok
  end
end