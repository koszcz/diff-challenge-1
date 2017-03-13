module Request
  module JsonHelper
    def json_response
      JSON.parse(response.body)
    end
  end

  module HTTPHelper
    require 'httparty'

    class TestedAPI
      include HTTParty
      base_uri API_HOST
    end

    class HTTPartyResponseToRSpecResponseAdapter < SimpleDelegator
      def ok?
        code == 200
      end
    end

    def get(url, options = {})
      new_options = {}
      new_options[:body] = options[:params]
      new_options[:headers] = options[:headers]
      @response = TestedAPI.get(url, new_options)
    end

    def post(url, options = {})
      new_options = {}
      new_options[:body] = options[:params]
      new_options[:headers] = options[:headers]
      response = TestedAPI.post(url, new_options)
      @response = HTTPartyResponseToRSpecResponseAdapter.new(response)
    end

    def response
      @response
    end
  end

  module GroupHelper
    def create_group(emails:, access_token: nil)
      post GROUPS_PATH, params: { group: { emails: emails } }, headers: build_access_token_header(access_token: access_token)
    end

    def groups_ids(access_token: nil)
      get GROUPS_PATH, headers: build_access_token_header(access_token: access_token)
      json_response.fetch('results').map { |group| group.fetch('id') }
    end
  end

  module OrderHelper
    def create_order(group_id: nil, restaurant:, access_token: nil)
      post ORDERS_PATH, params: { order: { group_id: group_id, restaurant: restaurant } }, headers: build_access_token_header(access_token: access_token)
    end

    def orders(user:)
      access_token = get_user_access_token(email: user)
      get ORDERS_PATH, headers: build_access_token_header(access_token: access_token)
      json_response.fetch('results')
    end
  end

  module SignInHelper
    def build_access_token_header(access_token:)
      { "X-Access-Token" => access_token }
    end

    def create_user(email = default_user_email, password = 'Very long password')
      post SIGN_UP_PATH, params: { user: { email: email, password: password, password_confirmation: password } }
    end

    def default_user_email
      'foo@bar.com'
    end

    def get_user_access_token(email:, password: 'Very long password')
      post SIGN_IN_PATH, params: { email: email, password: password }
      json_response.fetch('access_token')
    end

    def user_header(email:)
      build_access_token_header(access_token: get_user_access_token(email: email))
    end
  end
end

RSpec.configure do |config|
  config.include Request::HTTPHelper, type: :request
  config.include Request::GroupHelper, type: :request
  config.include Request::JsonHelper, type: :request
  config.include Request::OrderHelper, type: :request
  config.include Request::SignInHelper, type: :request
end
