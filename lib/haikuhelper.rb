require "httparty"


class HaikuHelperAPI
  include HTTParty
  format :json

  def initialize(uri, user, password)
    self.class.base_uri uri
    self.class.digest_auth user, password
  end

  def api(cmd)
    begin
      result = self.class.get URI::encode "/api/#{cmd}"
      raise IOError, "Authentication error!" if result.response.code == "401"

      result.parsed_response
    rescue Exception => e
      description = "Could not communicate via the remote HaikuHelper API: #{e}"
      raise IOError, description
    end
  end
end
