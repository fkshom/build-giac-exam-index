# frozen_string_literal: true

require 'csv'
require 'pp'
require 'yaml'

class PageBlock
  class << self
    def parse_pageblock_lines(pageblock_lines)
      head_line = pageblock_lines.shift
      page, title = head_line.strip.split(' ', 2)
      keywords = pageblock_lines.inject([]) do |memo, line|
        next memo if line =~ /\A#/

        memo + line.strip.split(',').map(&:strip).reject(&:empty?)
      end
      PageBlock.new(page, title, keywords)
    end
  end

  attr_reader :page, :title, :keywords
  attr_accessor :bookname

  def initialize(page, title, keywords)
    @page = page
    @title = title
    @keywords = keywords
    @bookname = ''
  end
end

class Indexfile
  def initialize
    @files = []
    @entries = nil
  end

  def add(bookname:, filename:)
    @files << [bookname, filename]
  end

  def entries
    @entries ||= load_files
    @entries
  end

  def each(&block)
    entries.each(&block)
  end

  private

  def load_files
    entries = []
    @files.each do |bookname, filename|
      pageblocks = File.foreach(filename).chunk do |line|
        /\A\s*\z/ !~ line || nil
      end

      pageblocks.each do |_, pageblock_lines|
        entry = PageBlock.parse_pageblock_lines(pageblock_lines)
        entry.bookname = bookname
        entries << entry
      end
    end
    entries
  end
end

config = YAML.load_file('config.yml')

indexfile = Indexfile.new
config['files'].each do |file|
  indexfile.add(bookname: file['bookname'], filename: file['filename'])
end

keyword_dict = {}
indexfile.each do |entry|
  entry.keywords.each do |keyword|
    keyword_dict[keyword] ||= []
    keyword_dict[keyword] << { bookname: entry.bookname, page: entry.page, title: entry.title }
  end
end

result = CSV.generate do |csv|
  keyword_dict.keys.sort_by(&:downcase).each do |keyword|
    bookpages = keyword_dict[keyword].map do |entry|
      "#{entry[:bookname]}-#{entry[:page]} #{entry[:title]}"
    end
    csv << [keyword, bookpages.join("\n")]
  end
end

puts result
