require './src/state'

class QTable
  attr :values
  attr_reader :filename

  def initialize(filename, rows = 100, cols = 5)
    @filename = filename
    @values =
      if File.file?(@filename)
        File.open(@filename, 'r') { |file| Marshal.load(file) }
      else
        Array.new(rows) { Array.new(cols, 0) }
      end
  end

  # return the row that begins with the state
  # if state not found assign it to the next available empty row
  # and return that row
  def [](state)
    index = @values.find_index { |row| row.first == state }
    if index.nil?
      index = @values.find_index { |row| row.first == 0 }
      @values[index] = [state, 0, 0, 0, 0]
    end
    @values[index]
  end

  def save
    File.open(@filename, 'w') { |file| Marshal.dump(@values, file) }
    save_unencoded(@filename.split('.').first + '.txt')
  end

  def average_value
    q_values =
      @values.filter { |row| row.first.class == String }
             .collect { |row| row[1..4] }
             .flatten
    if q_values.size.nonzero?
      q_values.sum / q_values.size
    else
      0
    end
  end

  def print_table
    puts 'STATE    FOLD    CHECK    CALL     RAISE   | BEST_MOVE -> BEST_MOVE_VALUE    LEGAL_MOVES'
    @values.filter { |row| row.first.class == String }
           .sort_by(&:first)
           .each do |row|
              best_move_value, best_move_name =
                row[1..4]
                .each_with_index
                .filter { |_e, i| s_possible_moves(row[0]).include?(index_to_move(i + 1)) }
                .collect { |e, i| [e, index_to_move(i + 1)] }
                .max_by(&:first)
                printf("%6s % 3.5f % 3.5f % 3.5f % 3.5f | %9s -> % 3.5f         %s \n",  row[0], row[1], row[2], row[3], row[4], best_move_name.to_s, best_move_value, s_possible_moves(row[0]).to_s)
    end
    puts "Average value: #{average_value}"
  end

  def index_to_move(index)
    case index
    when 1 then :fold
    when 2 then :check
    when 3 then :call
    when 4 then :raise
    end
  end

  def save_unencoded(filename = 'default.txt')
    File.open(filename, 'w') do |file|
      @values.filter { |row| row.first.class == String }
             .sort_by { |row| row[0] }
             .each do |row|
        file.write("#{row[0]}, #{row[1]}, #{row[2]}, #{row[3]}, #{row[4]} \n")
      end
    end
  end

end
