require 'helper'

class TestRackSslEnforcer < Test::Unit::TestCase
  
  context 'that has no :redirect_to set' do
    setup { mock_app }
    
    should 'respond with a ssl redirect to plain-text requests' do
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end
    
    #heroku / etc do proxied SSL
    #http://github.com/pivotal/refraction/issues/issue/2
    should 'respect X-Forwarded-Proto header for proxied SSL' do
      get 'http://www.example.org/', {}, { 'HTTP_X_FORWARDED_PROTO' => 'http', 'rack.url_scheme' => 'http' }
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/', last_response.location
    end
    
    should 'respond not redirect ssl requests' do
      get 'https://www.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
    
    should 'respond not redirect ssl requests and respect X-Forwarded-Proto header for proxied SSL' do
      get 'http://www.example.org/', {}, { 'HTTP_X_FORWARDED_PROTO' => 'https', 'rack.url_scheme' => 'http' }
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end
  
  context 'that has :redirect_to set' do
    setup { mock_app :redirect_to => 'https://www.google.com' }
    
    should 'respond with a ssl redirect to plain-text requests and redirect to :redirect_to' do
      get 'http://www.example.org/'
      assert_equal 301, last_response.status
      assert_equal 'https://www.google.com', last_response.location
    end
    
    should 'respond not redirect ssl requests' do
      get 'https://www.example.org/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end
  
  context 'that has regex pattern as only option' do
    setup { mock_app :only => /^\/admin/ }
    
    should 'respond with a ssl redirect for /admin path' do
      get 'http://www.example.org/admin'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/admin', last_response.location
    end
    
    should 'respond not redirect ssl requests' do
      get 'http://www.example.org/foo'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end
  
  context 'that has path as only option' do
    setup { mock_app :only => "/login" }
    
    should 'respond with a ssl redirect for /login path' do
      get 'http://www.example.org/login'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/login', last_response.location
    end
    
    should 'respond not redirect ssl requests' do
      get 'http://www.example.org/foo/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end
  
  context 'that has array of regex pattern & path as only option' do
    setup { mock_app :only => [/\.xml$/, "/login"] }
    
    should 'respond with a ssl redirect for /login path' do
      get 'http://www.example.org/login'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/login', last_response.location
    end
    
    should 'respond with a ssl redirect for /admin path' do
      get 'http://www.example.org/users.xml'
      assert_equal 301, last_response.status
      assert_equal 'https://www.example.org/users.xml', last_response.location
    end
    
    should 'respond not redirect ssl requests' do
      get 'http://www.example.org/foo/'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end
  
  context 'that has array of regex pattern & path as only option with strict option' do
    setup { mock_app :only => [/\.xml$/, "/login"], :strict => true }
    
    should 'respond with a http redirect from non-allowed https url' do
      get 'https://www.example.org/foo/'
      assert_equal 301, last_response.status
      assert_equal 'http://www.example.org/foo/', last_response.location
    end
    
    should 'respond from allowed https url' do
      get 'https://www.example.org/login'
      assert_equal 200, last_response.status
      assert_equal 'Hello world!', last_response.body
    end
  end
  
end