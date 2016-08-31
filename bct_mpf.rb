#!/usr/bin/env ruby
require 'rss'
require 'atom'
require 'open-uri'
require 'pp'
require 'nokogiri'
require 'csv'

url = URI.parse 'https://fundinsln.bcthk.com/BCT/html/eng/page/WMP0240/RSS/fundsRss_eng.xml'

fund_prices = open(url) do |rss|
  input = RSS::Parser.parse(rss)

  input.items.flat_map do |item|
    fund_family = item.title

    html = Nokogiri::HTML(item.description)
    table = html.xpath('//table[1]')

    date = table.xpath('tr[1]/td[2]').first.text
    date = /As at ([0-9]{2} [A-Za-z]{3} [0-9]{4})/.match(date)[1]
    date = Date.parse(date)

    prices = table.xpath('tr[position()>3]').map do |row|
      fund  = row.xpath('td[1]').first
      price = row.xpath('td[2]').first
      if fund.nil? || price.nil? then
        nil
      else
        price = begin Float(price.text) rescue nil end
        [date, fund_family, fund.text, price]
      end
    end.compact
  end
end

CSV do |csv|
  csv << ["Date", "Fund Family", "Fund", "Price"]

  fund_prices.each {|row| csv << row}
end
