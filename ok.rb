require 'rest-client'
require 'active_support/all'
require 'base64'
require 'openssl'

def ok_call(method, url, params)
  timestamp = Time.now.ago(8.hours).strftime("%Y-%m-%dT%H:%M:%S.%LZ")
  params_json = params.to_json
  params_json = "" if !params 


  data = timestamp + method + url + params_json
  digest = OpenSSL::HMAC.digest('SHA256', $config['ok_access_secret'], data)
  sign = Base64.encode64(digest).strip
  #p [data, $config['ok_access_secret'], sign, "https://www.okex.com" + url, $config['passphase']]
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

  # if method == "POST"
  #   h = ""
  #   headers.each{|key, value|
  #     h += %! -H "#{key}: #{value}"!
  #   }
    
  #   command = %!curl -x #{$config["proxy"]} #{h}  -X post --data '#{params_json}' #{"https://www.okex.com" + url} !
  #   puts command
  #   result = `#{command}`
  #   p result
  #   return JSON.parse(result)
  # end

  RestClient.proxy = $config['proxy']
  
  begin
    res = RestClient::Request.execute(
      url: "https://www.okex.com" + url,
      method: method,
      timeout: 30,
      payload: params_json,
      headers: headers
    )
    return JSON.parse(res)
  rescue Exception=>err
    p err
  end
end

#下单
def make_ok_order(direction, sz = $config["sz"])
  direction == "up" ? (puts "下多单") : (puts "下空单")
  params = {
    "instId": "BTC-USDT-SWAP",
    "tdMode": "cross",
    "side":    direction == "up" ?  "buy" : "sell",
    "ordType": "market",
    #"posSide": direction == "up" ? "long" : "short",
    "sz": sz
  }
  puts ok_call("POST", "/api/v5/trade/order", params)
end

#下单
def make_ok_order_s(direction, sz = $config["sz"])
  direction == "up" ? (puts "下多单") : (puts "下空单")
  params = {
    "instId": "BTC-USDT-SWAP",
    "tdMode": "cross",
    "side":    direction == "up" ?  "buy" : "sell",
    "ordType": "market",
    #"posSide": direction == "up" ? "long" : "short",
    "sz": sz
  }
  #puts ok_call("POST", "/api/v5/trade/order", params)
end

#平仓
#long_or_short: long 平多单，short 平空单
def clear_stock()
  puts ok_call("POST", "/api/v5/trade/close-position", {"instId": "BTC-USDT-SWAP", "mgnMode": "cross"})
end
