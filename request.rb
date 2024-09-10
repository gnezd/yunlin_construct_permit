require 'net/http'
require 'pry'
require 'nokogiri'

APQ = URI 'https://publicnewbuilding.yunlin.gov.tw/YLCGBM/maliapp/apqs/apqs_v000.jsp'

def apq(socket, cookie, baseseqno)
  request = Net::HTTP::Get.new APQ.path
  request['cookie'] = cookie
  request.set_form({BASESEQNO: baseseqno})
  socket.request request
end

def start_connection
  # Start and retrieve session
  entry_point = URI 'https://publicnewbuilding.yunlin.gov.tw/YLCGBM/'
  request = Net::HTTP::Get.new entry_point.path
  socket = Net::HTTP.new entry_point.host, entry_point.port
  socket.use_ssl=true
  socket.start

  result = socket.request request
  cookie = result.header['set-cookie']

  return socket, cookie
end



# Parse list to request
parsed = Nokogiri::HTML.parse(File.open('./list', 'r'){|f| f.read})
tbl = parsed.xpath '//tr'
title_row = tbl.shift
tbl.pop

permits = []
tbl.each do |row|
  cell_texts = row.xpath('td').map{|cell| cell.text}
  # permit_id, builder, designer, address, date = cell_texts[1..5]
  result = cell_texts[1..5]
  id = row.xpath('./td/button').attribute('onclick').value.split("'")[1]
  result.push id
  permits.push result
end

# Initialize connection and obtain session
puts "Initialization HTTP..."
socket, cookie = start_connection
puts "Done. Cookie = #{cookie}"

# 執照號碼, 起造人, 設計人, 建築地址, 核發日期, id
# Request away!
permits.each do |permit|
  id = permit[5]
  puts "Requesting permit #{permit[0]} APQ # #{id} #{Time.now.strftime "%d%b-%H%M%S.%L"}"
  fout = File.open "permit_data/#{id}.html", 'w'
  fout.write(apq(socket, cookie, id).body)
  fout.close
  sleep((rand(100).to_f)/100+0.1)
end
