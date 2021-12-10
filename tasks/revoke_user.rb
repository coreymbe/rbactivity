#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require 'net/https'
require 'uri'
require 'json'

def revoke_user(token, username)
  uri       = URI.parse('https://localhost:4433/rbac-api/v1/users')
  rbac_user = Net::HTTP.start(
    uri.host,
    uri.port,
    use_ssl: true,
    verify_mode: OpenSSL::SSL::VERIFY_NONE
  ) do |http|
    request = Net::HTTP::Get.new uri
    request.add_field('X-Authentication', token)

    response      = http.request request
    data_response = JSON.parse(response.body)
    data_response.find { |user| user['login'] == username.to_s }
  end

  rbac_user['is_revoked'] = true
  revoked_rbac_user       = rbac_user.to_json
  id                      = rbac_user['id']
  uri                     = URI.parse("https://localhost:4433/rbac-api/v1/users/#{id}")

  Net::HTTP.start(
    uri.host,
    uri.port,
    use_ssl: true,
    verify_mode: OpenSSL::SSL::VERIFY_NONE
  ) do |http|
    request = Net::HTTP::Put.new uri
    request.add_field('X-Authentication', token)
    request.add_field('Content-Type', 'application/json')
    request.body  = revoked_rbac_user
    response      = http.request request

    puts response.body
  end
end

params = JSON.parse($stdin.read)
username = params['username']
token = params['token'] || `puppet access show`.chomp

revoke_user(token, username)
