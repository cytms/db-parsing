#!/usr/bin/env ruby
# encoding: UTF-8

require 'nokogiri'
require 'open-uri'
require_relative '../lib/connect_mysql'

def get_patent_id(mysql, query_year, query_index)
  mypaper = mysql.db('mypaper') #input db
  limit = "LIMIT #{query_index-1}, 1"
  patent_id = mypaper.query("SELECT Patent_id FROM content_#{query_year} ORDER BY Patent_id ASC #{limit}")
  return patent_id
end