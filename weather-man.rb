# frozen_string_literal: true

require 'date'
require 'colorize'
require 'csv'

# weatherman Module
module Weatherman
  POSITIVE_INFINITY = 1 / 0.0
  NEGATIVE_INFINITY = -1 / 0.0

  class << self
    def change_date_format(date_string)
      return unless date_string

      date = Date.parse(date_string)
      Date::MONTHNAMES[date.month] + ' ' + date.day.to_s
    rescue StandardError
    end

    def read_file(path)
      CSV.read(path)
    rescue StandardError
      puts 'Record Not found or Invalid Path'
      exit
    end

    def date?(date_string)
      Date.parse(date_string)
      true
    rescue StandardError
      false
    end
  end

  # temperature class
  class Temperature
    def initialize
      @max_highest_temp = NEGATIVE_INFINITY
      @lowest_min_temp  = POSITIVE_INFINITY
      @min_mean_temp = POSITIVE_INFINITY
      @max_mean_temp = NEGATIVE_INFINITY
      @max_highest_temp_date = nil
      @lowest_min_temp_date = nil
      @content_found = false
    end

    def max_temp(filenames, foldername)
      filenames.each do |filename|
        path = './' + foldername + '/' + filename
        content = Weatherman.read_file(path)

        if content
          @content_found = true
          max_temp_update(content)
        end
      end
    end

    def min_temp(filenames, foldername)
      filenames.each do |filename|
        path = './' + foldername + '/' + filename
        content = Weatherman.read_file(path)
        if content
          @content_found = true
          min_temp_update(content)
        end
      end
    end

    def print_minmax_temp
      if @content_found
        puts "Highest:  #{@max_highest_temp}C on #{@max_highest_temp_date}"
        puts "Lowest: #{@lowest_min_temp}C on #{@lowest_min_temp_date}"
      else
        puts 'RECORD NOT FOUND.'
      end
    end

    def max_temp_update(content)
      hash = {}
      content.each_with_index do |e, i|
        hash[e[0]] = e[1] if i != 0 && e[1] && Weatherman.date?(e[0])
      end

      file_max_temp = hash.values.max.to_i
      date = hash.key(file_max_temp.to_s)

      return unless @max_highest_temp < file_max_temp

      @max_highest_temp = file_max_temp
      @max_highest_temp_date = Weatherman.change_date_format(date)
    end

    def min_temp_update(content)
      hash = {}
      content.each_with_index do |e, i|
        hash[e[0]] = e[3].to_i if i != 0 && e[3] && Weatherman.date?(e[0])
      end
      file_min_temp = hash.values.min
      date = hash.key(file_min_temp)

      return unless @lowest_min_temp > file_min_temp

      @lowest_min_temp = file_min_temp
      @lowest_min_temp_date = Weatherman.change_date_format(date)
    end

    def mean_temp_minmax(filenames, foldername)
      filenames.each do |filename|
        path = './' + foldername + '/' + filename
        content = Weatherman.read_file(path)
        next unless content

        @content_found = true
        avgtemp_minmax = content.each_with_index.map do |e, i|
          e[2] if e[2] && i != 0
        end.compact
        next unless avgtemp_minmax.length > 1

        avgtemp_minmax.shift if avgtemp_minmax[0] == 'Mean TemperatureC'
        avgtemp_minmax = avgtemp_minmax.map(&:to_i).minmax
        @max_mean_temp = avgtemp_minmax[1] if @max_mean_temp < avgtemp_minmax[1]
        @min_mean_temp = avgtemp_minmax[0] if @min_mean_temp > avgtemp_minmax[0]
      end
    end

    def print_mean_temp
      if @content_found
        puts "Highest Average: #{@max_mean_temp}C"
        puts "Lowest Average: #{@min_mean_temp}C"
      else
        puts 'NO RECORD FOUND.'
      end
    end

    def temperature_chart(filenames, foldername, year, month)
      if month
        filenames.each do |filename|
          content = Weatherman.read_file('./' + foldername + '/' + filename)
          next unless content

          print "#{month} #{year}\n"
          print_chart(content)
        end
      else
        puts 'Please Specify Month.'
      end
    end

    def print_chart(content)
      content.each_with_index do |_e, i|
        if i != 0
          highest_temp = content[i][1]
          lowest_temp = content[i][3]
          date = Date.parse(content[i][0])
          barchart = Barchart.new(date.day.to_s.rjust(2, '0'), lowest_temp.to_i, highest_temp.to_i)
          barchart.draw
          print "#{lowest_temp}C - #{highest_temp}C\n"
        end
      rescue StandardError
      end
    end
  end

  # humidity class
  class Humidity
    def initialize
      @max_highest_humid = NEGATIVE_INFINITY
      @max_mean_humid = NEGATIVE_INFINITY
      @max_highest_humid_date = nil
      @content_found = false
    end

    def max_humidity(filenames, foldername)
      filenames.each do |filename|
        content = Weatherman.read_file('./' + foldername + '/' + filename)
        if content
          @content_found = true
          max_humid_update(content)
        end
      end
    end

    def max_humid_update(content)
      hash = {}
      content.each_with_index do |e, i|
        hash[e[0]] = e[7] if i != 0 && e[7] && Weatherman.date?(e[0])
      end
      max_humid = hash.values.max.to_i
      date = hash.key(max_humid.to_s)

      return unless @max_highest_humid < max_humid

      @max_highest_humid = max_humid
      @max_highest_humid_date = Weatherman.change_date_format(date)
    end

    def print_max_humidity
      if @content_found
        puts "Humid:  #{@max_highest_humid}% on #{@max_highest_humid_date}"
      else
        puts 'RECORD NOT FOUND.'
      end
    end

    def max_mean_humidity(filenames, foldername)
      filenames.each do |filename|
        content = Weatherman.read_file('./' + foldername + '/' + filename)
        next unless content

        @content_found = true
        avghumid_max = content.each_with_index.map do |e, i|
          e[8].to_i if e[8] && i != 0
        end.compact.max
        @max_mean_humid = avghumid_max if @max_mean_humid < avghumid_max
      end
    end

    def print_max_mean_humidity
      if @content_found
        puts "Average Humidity: #{@max_mean_humid}%"
      else
        puts 'NO RECORD FOUND.'
      end
    end
  end

  # barchart drawer
  class Barchart
    def initialize(day, lowest_temp, highest_temp)
      @day = day
      @lowest_temp = lowest_temp
      @highest_temp = highest_temp
    end

    def draw
      print_blues
      print_reds
    end

    def print_blues
      print @day + ' '
      @lowest_temp.times do
        print '+'.blue
      end
    end

    def print_reds
      @highest_temp.times do
        print '+'.red
      end
      print ' '
    end
  end

  # reading parser
  class Parse
    attr_accessor :att, :year, :path, :month, :foldername, :filenames

    def initialize
      @args = ''
      ARGV.each { |arg| @args = @args + ' ' + arg }
      @args = @args.split(' ')
      set_variables
      generate_filenames

    end

    def set_variables
      @att = @args[0]
      @year = @args[1]
      @path = @args[2]
      @year_and_month = @year.split('/')
      @year = @year_and_month[0]
      @month = Date::MONTHNAMES[@year_and_month[1].to_i].slice(0..2) if @year_and_month.length > 1
      @path = @path.split('/')
      @foldername = @path[-1]
    end

    def generate_filenames
      @filenames = []
      if @month.nil?
        begin
          @filenames = Dir.entries('./' + @foldername).shift(2).grep(/#{@year}/)
        rescue StandardError
          puts 'File Not Found.'
        end
      else
        @filenames << "#{@foldername}_#{@year}_#{@month}.txt"
      end
    end
  end
end
# main

data = Weatherman::Parse.new
temperature = Weatherman::Temperature.new
humidity = Weatherman::Humidity.new

case data.att
when '-e'
  temperature.max_temp(data.filenames, data.foldername)
  temperature.min_temp(data.filenames, data.foldername)
  temperature.print_minmax_temp
  humidity.max_humidity(data.filenames, data.foldername)
  humidity.print_max_humidity

when '-a'
  temperature.mean_temp_minmax(data.filenames, data.foldername)
  temperature.print_mean_temp
  humidity.max_mean_humidity(data.filenames, data.foldername)
  humidity.print_max_mean_humidity

when '-c'
  temperature.temperature_chart(data.filenames, data.foldername, data.year, data.month)
end
