#!/usr/bin/ruby

# What it does: Simply download all your Picasa Web Albums to current dir (where Picasa Album nams is subfolder)
# @author: Artyom Loenko (divenvrsk@gmail.com)
# This software works with all OS where Ruby installed. It is built using the Ruby Programming Language.
# It is licensed under LGPL.

require 'rubygems'
require 'net/https'
require 'xmlsimple'

if ARGV.size < 2
  puts 'use: ruby getPicasaAlbums login password
        login - your gmail account (example@gmail.com)
        password - password to your GMail account'
  exit
end

http = Net::HTTP.new('www.google.com', 443)
http.use_ssl = true
path = '/accounts/ClientLogin'
albums_url = 'http://picasaweb.google.com/data/feed/api/user/default'
data =  'accountType=HOSTED_OR_GOOGLE&' +
        'Email=' + ARGV[0] + '&Passwd=' + ARGV[1] + 
        '&service=lh2'
headers = { 'Content-Type' => 'application/x-www-form-urlencoded'}

resp, data = http.post(path, data, headers)
cl_string = data[/Auth=(.*)/, 1]
headers["Authorization"] = "GoogleLogin auth=#{cl_string}"

if !resp.to_s.include? "HTTPOK"
  puts "\tWrong login or password. Try again."
  exit
end

def get(uri, headers=nil)
  uri = URI.parse(uri)
  Net::HTTP.start(uri.host, uri.port) do |http|
    return http.get(uri.path, headers)
  end
end

albums = XmlSimple.xml_in(get(albums_url, headers).body, 'KeyAttr' => 'name')
puts 'Total albums: ' + albums['entry'].size.to_s + "\n Scanning... PLease wait."

albums['entry'].size.times { |num|
  puts "\tAlbum: " + albums['entry'][num]['title'][0]['content'] + "\t Download " + albums['entry'][num]['numphotos'].to_s + ' photos'
  photos = XmlSimple.xml_in(get(albums_url + '/albumid/' + albums['entry'][num]['id'][1], headers).body, 'KeyAttr' => 'name')  
  Dir.mkdir albums['entry'][num]['title'][0]['content']
  photos['totalResults'][0].to_i.times { |photo|
    photo_url = photos['entry'][photo]['content']['src']
    photo_url[photo_url.split('/')[-1]] = ("d/" + photo_url.split('/')[-1])
    img_uri = URI.parse(photo_url)
    Net::HTTP.start( img_uri.host ) { |http|
      resp = http.get(img_uri.path)
      open(albums['entry'][num]['title'][0]['content'] + '/' + img_uri.path.split('/')[-1].to_s, 'wb') { |file|
              file.write(resp.body)
      }
      puts  "\t\tcompleted [" + (photo + 1).to_s + '/' + albums['entry'][num]['numphotos'].to_s + ']' + 
            ' Name: ' + img_uri.path.split('/')[-1].to_s + ' Size: ' + resp.body.size.to_s + ' bytes'
    }
  }
}