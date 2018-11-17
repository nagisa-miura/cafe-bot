require 'line/bot'
require 'open-uri'
require 'rexml/document'

class LinebotController < ApplicationController
  protect_from_forgery with: :null_session
   
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read
    unless @client.validate_signature(body, request.env['HTTP_X_LINE_SIGNATURE'])
      error 400 do 'Bad Request' end
    end
    event = @client.parse_events_from(body)[0]
    case event.type
    when "text"
      message = {
        type: 'text',
        text: return_message
      }
    when "location"
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

  private
  
  def return_message
    open("http://www.meigensyu.com/quotations/view/random") do |file|
      page = file.read
      page.scan(/<div class=\"text\">(.*?)<\/div>/).each do |meigen|
        return meigen[0].encode("sjis")
      end
    end
  end
  
  def return_location_height(message)
    ret_msg = message['address'] + "の標高は"
    lat = message['latitude']
    lon = message['longitude']
    body = open("http://lab.uribou.net/ll2h/?ll=#{lat},#{lon}", &:read)
    doc = REXML::Document.new(body)
    ret_msg += doc.elements['result/height'].text + "mです"
    ret_msg
  end

end