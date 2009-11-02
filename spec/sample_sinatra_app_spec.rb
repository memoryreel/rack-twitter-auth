require File.dirname(__FILE__) + '/spec_helper'

require 'json'
require 'sinatra/base'
class SampleSinatraApp < Sinatra::Base
  use Rack::Session::Cookie
  use Rack::OAuth, :site => 'http://twitter.com', :key => '4JjFmhjfZyQ6rdbiql5A', 
                   :secret => 'rv4ZaCgvxVPVjxHIDbMxTGFbIMxUa4KkIdPqL7HmaQo'

  helpers do
    include Rack::OAuth::Methods
  end

  get '/' do
    if logged_in?
      "Hello World"
    else
      redirect login_path
    end
  end

  get '/get_user_info' do
    info = JSON.parse oauth_request('/account/verify_credentials.json')
  end
end

describe SampleSinatraApp do

  def example_json
    %[{"time_zone":"Pacific Time (US & Canada)","profile_image_url":"http://a3.twimg.com/profile_images/54765389/remi-rock-on_bak_normal.png","description":"Beer goes in, Code comes out","following":false,"profile_text_color":"3E4415","status":{"source":"web","in_reply_to_user_id":64218381,"in_reply_to_status_id":5352275994,"truncated":false,"created_at":"Mon Nov 02 02:00:26 +0000 2009","favorited":false,"in_reply_to_screen_name":"benatkin","id":5352407184,"text":"@benatkin For GoldBar, they would want to tell you when you buy something because lots of people are coming in and not buying anything  :/"},"profile_background_image_url":"http://s.twimg.com/a/1256928834/images/themes/theme5/bg.gif","followers_count":257,"screen_name":"remitaylor","profile_link_color":"D02B55","profile_background_tile":false,"friends_count":190,"url":"http://remi.org","created_at":"Tue Dec 11 09:13:43 +0000 2007","profile_background_color":"352726","notifications":false,"favourites_count":0,"statuses_count":1700,"profile_sidebar_fill_color":"99CC33","protected":false,"geo_enabled":false,"location":"Phoenix, AZ","name":"remitaylor","profile_sidebar_border_color":"829D5E","id":11043342,"verified":false,"utc_offset":-28800}]
  end

  before :all do
    @rackbox_app = RackBox.app
    RackBox.app = SampleSinatraApp
    Rack::OAuth.enable_test_mode
  end

  after :all do
    RackBox.app = @rackbox_app
    Rack::OAuth.disable_test_mode
  end

  it 'should be able to "authorize" a user' do
    # we're not authorized, so logged_in? is false and we should redirect to /oauth_login
    request('/').status.should == 302
    request('/').headers['Location'].should include('/oauth_login')

    # because we're in test mode, redirecting to /oauth_login should pretend to log 
    # us in and it should redirect to /oauth_complete
    request('/oauth_login').status.should == 302
    request('/oauth_login').headers['Location'].should include('/oauth_complete')

    # now the user should be authorized
    request('/').status.should == 200
    request('/').body.should include('Hello World')
  end

  it 'should be able to specify a mock response for an arbitrary authorized response' do
    request('/oauth_login') # login

    # if we don't mock the request, it should blow up
    lambda { request('/get_user_info') }.should raise_error

    Rack::OAuth.mock_request '/account/verify_credentials.json', example_json

    request('/get_user_info').body.should include('remitaylor')
  end

end
