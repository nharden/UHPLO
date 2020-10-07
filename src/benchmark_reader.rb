require './src/deck'
class BenchmarkReader
  attr_reader :rows
  def initialize(filename)
    @rows = []
    File.foreach(filename) do |line|
      @rows << line.split(' ')
                   .collect { |card| Card.new(card) }
                   .to_a
    end
    @current_row = 0
  end

  def next
    next_deal = @rows[@current_row]
    @current_row += 1
    next_deal
  end

  def size
    @rows.size
  end
end

class DataRecorder
  attr_reader :filename, :data

  def initialize
    @filename = nil
    @data = []
  end

  def record(*args)
    @data << args.to_a
  end

  def save_to_file(filename)
    File.open(filename, 'w') do |file|
      @data.each { |row| file.write("#{row[0]}, #{row[1]}, #{row[2]}\n") }
    end
  end
end
