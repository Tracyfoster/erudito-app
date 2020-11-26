require 'net/http'
require 'uri'

DOMAIN = Rails.application.credentials.auth0[:domain]
API_IDENTIFIER = Rails.application.credentials.auth0[:api_identifier]

class JsonWebToken
  def self.verify(token)
    JWT.decode(token, nil,
               true,
               algorithm: 'RS256',
               iss: DOMAIN,
               verify_iss: true,
               aud: API_IDENTIFIER,
               verify_aud: true) do |header|
      jwks_hash[header['kid']]
    end
  end

  def self.jwks_hash
    jwks_raw = Net::HTTP.get URI("#{DOMAIN}.well-known/jwks.json")
    jwks_keys = Array(JSON.parse(jwks_raw)['keys'])
    Hash[
      jwks_keys
      .map do |k|
        [
          k['kid'],
          OpenSSL::X509::Certificate.new(
            Base64.decode64(k['x5c'].first)
          ).public_key
        ]
      end
    ]
  end
end