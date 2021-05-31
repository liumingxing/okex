#短期模型
require './ok.rb'
require 'yaml'

def get_current_price
  json = ok_call("GET", "/api/v5/market/ticker?instId=BTC-USDT-SWAP", nil)
  current_price = json["data"].first["last"].to_f
  return current_price
end

#读取配置文件
$config = YAML.load_file('./conf.yml')
make_ok_order_s($config["init_direction"])
direction = $config["init_direction"]
current_price = get_current_price
profit = 0

while true
  json = ok_call("GET", "/api/v5/market/candles?instId=BTC-USDT&bar=#{$config["bar"]}&limit=#{$config['short_trend_see']}", nil)
  if json["code"] == "0"
    up = 0
    down = 0
    for data in json["data"]
      ts, o, h, l, c, vol, volCCy = data[0].to_f, data[1].to_f, data[2].to_f, data[3].to_f, data[4].to_f, data[5].to_f, data[6].to_f
      if o > c
        down += 1
      else o < c
        up += 1
      end
    end
    max = [up, down].max
    p "profit: #{profit} up:#{up}, down:#{down}"
    if max >= $config['short_trend_same']
      new_direction = up > down ? "up" : "down"
      if new_direction != direction
        #下反向单
        make_ok_order_s($config["sz"]*2)
        price_diff = get_current_price - current_price
        if direction == "up"
          profit += price_diff
        else
          profit -= price_diff
        end

        direction = new_direction
      end
    end
    sleep(2)
  end
end