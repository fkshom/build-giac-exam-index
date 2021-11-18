require 'pp'

class Indexfile
  def initialize
    @booknum_with_filename = []
    @entries = nil
  end

  def <<(booknum_with_filename)
    @booknum_with_filename << booknum_with_filename
  end

  def entries
    @entries ||= load
    @entries
  end

  def each(&block)
    entries.each(&block)
  end

  private

  def parse_chunk(lines)
    line = lines.shift
    page, title = line.strip.split(' ', 2)
    keywords = lines.inject([]) do |memo, line|
      next memo if line =~ /\A#/

      memo + line.strip.split(',').map(&:strip).reject(&:empty?)
    end
    {
      page: page,
      title: title,
      keywords: keywords
    }
  end

  def load
    entries = []
    @booknum_with_filename.each do |book_no, filename|
      File.foreach(filename).chunk do |line|
        /\A\s*\z/ !~ line || nil
      end.each do |_, lines|
        entry = parse_chunk(lines)
        entry[:book] = book_no
        entries << entry
      end
    end
    entries
  end
end

indexfile = Indexfile.new
indexfile << [1, 'book1.txt']
indexfile << [2, 'book2.txt']
entries = {}
indexfile.each do |entry|
  entry[:keywords].each do |keyword|
    entries[keyword] ||= []
    entries[keyword] << { book: entry[:book], page: entry[:page] }
  end
end

entries.keys.sort.each do |keyword|
  bookpages = entries[keyword].map do |bookpage|
    "#{bookpage[:book]}-#{bookpage[:page]}"
  end
  puts "#{keyword}    #{bookpages.join(', ')}"
end
