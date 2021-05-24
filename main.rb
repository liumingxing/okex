require './ok.rb'
require 'yaml'

#读取配置文件
$config = YAML.load_file('./conf.yml')

puts "获取当前服务器时间"
p ok_call("GET", "/api/general/v3/time", nil)

puts "获取币币信息"
p ok_call("GET", "/api/v5/account/balance", nil)