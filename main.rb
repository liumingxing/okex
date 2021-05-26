require './ok.rb'
require 'yaml'

#读取配置文件
$config = YAML.load_file('./conf.yml')

puts "获取当前服务器时间"
ok_call("GET", "/api/general/v3/time", nil)

puts "获取币币信息"
ok_call("GET", "/api/v5/account/balance", nil)

print "获得btc-usdt价格："
json = ok_call("GET", "/api/v5/market/ticker?instId=BTC-USDT-SWAP", nil)
current_price = json["data"].first["last"].to_f
puts current_price

puts "最大可买数量"
puts ok_call("GET", "/api/v5/account/max-size?instId=BTC-USDT-SWAP&tdMode=isolated", nil)

#puts "获得交易instrument"
#p ok_call("GET", "/api/v5/public/instruments?instType=SPOT", nil)

direction = $config["init_direction"]
base_price = current_price

puts "平仓"
clear_stock()

make_ok_order(direction)

loses = 0

while true
  begin
    json = ok_call("GET", "/api/v5/market/ticker?instId=BTC-USDT-SWAP", nil)
    current_price = json["data"].first["last"].to_f
  rescue Exception=>err
    puts err
  end

  puts "当前价格：#{current_price}, [#{base_price - $config["distance"]} - #{base_price + $config["distance"]}]"
  if direction == "up"
    if current_price >= base_price + $config["distance"].to_f
      #平仓
      clear_stock()
      if $config["mode"] == "trend"
        #下多单
        make_ok_order(direction)
      elsif $config["mode"] == "grid"
        loses = 0
        #下空单
        direction = "down"
        make_ok_order(direction)
      end
      base_price = current_price
    elsif current_price <= base_price - $config["distance"].to_f
      if $config["mode"] == "trend"
        #平仓
        clear_stock()

        #下空单
        direction = "down"
        make_ok_order(direction)
      elsif $config["mode"] == "grid"
        loses += 1
        if loses >= $config["grid_step"]
          #平仓
          clear_stock()
        end
        #下多单
        make_ok_order(direction)
      end
      base_price = current_price
    end
  elsif direction == "down"
    if current_price <= base_price - $config["distance"].to_f
      #平仓
      clear_stock()
      if $config["mode"] == "trend"
        #下空单
        make_ok_order(direction)
      elsif $config["mode"] == "grid"
        loses = 0
        #下多单
        direction = "up"
        make_ok_order(direction)
      end
      base_price = current_price
    elsif current_price >= base_price + $config["distance"].to_f
      if $config["mode"] == "trend"
        #平仓
        clear_stock()

        #下多单
        direction = "up"
        make_ok_order(direction)
      elsif $config["mode"] == "grid"
        loses += 1
        if loses >= $config["grid_step"]
          #平仓
          clear_stock()
        end
        #下空单
        make_ok_order(direction)
      end
      base_price = current_price
    end
  end
  sleep(1)
end