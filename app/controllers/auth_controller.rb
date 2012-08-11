require "base64"
require "json"
require "net/http"

class AuthController < ApplicationController
  include Base64

  def first
  end

  def post
    signed_request = params[:signed_request]
    @encoded_sig, @payload = signed_request.split '.', 2
    Rails.logger.info "length #{@payload.length}"
    Rails.logger.info "module #{@payload.length.modulo(4)}"
    #@payload += "=" * (4 - @payload.length.modulo(4))
    Rails.logger.info @payload
    Rails.logger.info "length #{@payload.length}"
    @json = JSON.parse urlsafe_decode64 @payload
    if @json["user_id"].nil?
      @redirect = "https://www.facebook.com/dialog/oauth?client_id=344747032279945&redirect_uri=http://apps.facebook.com/mikesdbay&scope=email,read_stream,publish_stream"
    else
      user_id = @json["user_id"]
      @access_token = @json["oauth_token"]
      http = Net::HTTP.new("graph.facebook.com", 443)
      http.use_ssl = true
      res = http.get("/#{user_id}/feed?access_token=#{@access_token}")
      @feed = JSON.parse res.body
    end
  end

  def comment
    @access = params[:access]
    @text = params[:comment_text]
    @ids = params[:post]
    requests = []
    @ids.each do |id|
      req = {"method" => "POST", "relative_url" => "#{id}/comments?message=#{@text}"}
      requests << req
    end
    @request_json = JSON.generate requests

    http = Net::HTTP.new("graph.facebook.com", 443)
    http.use_ssl = true
    @res = http.post("/", "access_token=#{@access}&batch=#{@request_json}")
  end
end
