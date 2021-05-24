require 'rest-client'
require 'active_support/all'
require 'Base64'
require 'openssl'

def ok_call(method, url, params)
  timestamp = Time.now.ago(8.hours).strftime("%Y-%m-%dT%H:%M:%S.%LZ")
  params_json = params.to_json
  params_json = "" if !params 


  data = timestamp + method + url + params_json
  digest = OpenSSL::HMAC.digest('SHA256', $config['ok_access_secret'], data)
  sign = Base64.encode64(digest).strip
  p [data, $config['ok_access_secret'], sign, "https://www.okex.com" + url, $config['passphase']]
  headers = {
    "OK-ACCESS-KEY":        $config['ok_access_key'],
    "OK-ACCESS-TIMESTAMP":  timestamp,
    "OK-ACCESS-PASSPHRASE": $config['passphase'],
    "OK-ACCESS-SIGN":       sign,
    "Accept": "application/json",
    "Content-Type": "application/json; charset=UTF-8"
  }
  if $config["simulate"] == 1
    headers["x-simulated-trading"] = "1"
  end

  # h = ""
  # headers.each{|key, value|
  #   h += %! -H "#{key}: #{value}"!
  # }
  
  # command = %!curl -x #{$config["proxy"]} #{h} #{"https://www.okex.com" + url} !
  # puts command
  # result = `#{command}`
  # p result
  # return result

  RestClient.proxy = $config['proxy']
  
  res = RestClient::Request.execute(
    url: "https://www.okex.com" + url,
    method: method,
    timeout: 30,
    headers: headers
  )
  return JSON.parse(res)
end