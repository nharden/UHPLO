# file loading and saving code adapted from
# https://stackoverflow.com/questions/30718214/saving-hashes-to-file-on-ruby
require './src/deck'
require './src/q_table'

class Player
  attr_reader :bankroll, :last_move, :history
  attr_accessor :game

  def initialize
    @bankroll = 0
    @history = DataRecorder.new
  end

  def adjust_bankroll(amount)
    @bankroll += amount
  end

  def reset_moves_and_states() end

  def q_update(*args) end

  def report() end

  def print_table() end

  def save() end

  def save_history(filename)
    @history.save_to_file(filename)
  end

  def record(hands_played)
    @history.record(hands_played, @bankroll, 0)
  end
end

class LearningPlayer < Player
  attr_accessor :learning_mode, :strategy
  attr_reader :states_visited

  def initialize(learning_rate, learning_mode, discount_rate, epsilon, strategy, filename)
    @learning_rate = learning_rate
    @learning_mode = learning_mode
    @filename = filename
    @q = QTable.new(@filename)
    @discount_rate = discount_rate
    @strategy = strategy
    @epsilon = epsilon
    @states_visited = []
    @moves_made = []
    super()
  end

  def reset_moves_and_states
    @states_visited = []
    @moves_made = []
  end

  def record(hands_played)
    @history.record(hands_played, @bankroll, @q.average_value)
  end

  def last_state
    @states_visited.last
  end

  def last_move
    @moves_made.last
  end

  def report
    @q.report
  end

  def print_table
    @history.data.each { |row| p row } if @history.data.size <= 100
    @q.print_table
  end

  def get_possible_moves(state = nil)
    total_bet_s, total_bet_t, _card_or_hand_value =
      if state
        decode_state(state)
      else
        [@game.total_bet_s, @game.total_bet_t, -1]
      end

    puts "moves: s_bet = #{total_bet_s} t_bet = #{total_bet_t}" if @game.troubleshoot
    possible_moves =
      if (total_bet_s == total_bet_t) && (total_bet_s == 1)
        case @game.phase
        when :phase1 then [:check, :raise]
        when :phase2 then [:raise, :fold]
        end
      elsif (total_bet_s > 1) && (total_bet_s == total_bet_t)
        [:check, :raise]
      elsif total_bet_s < total_bet_t
        [:call, :fold]
      else
        raise Exception.new('No Legal Moves')
      end
    print 's possible moves: ' if @game.troubleshoot
    p possible_moves if @game.troubleshoot
    possible_moves
  end

  # move to index
  def m_to_i(move)
    case move
    when :fold then 1
    when :check then 2
    when :call then 3
    when :raise then 4
    end
  end
end

# --- Q-learning Player S ---
class LearningS < LearningPlayer
  def phase1_move
    make_move
    q_update unless last_move == :fold || @moves_made[-2].nil?
  end

  def phase2_move
    make_move
    q_update unless last_move == :fold
  end

  def make_move
    possible_moves = get_possible_moves
    @states_visited << game.state('S')

    case @strategy
    when :prandom
      @moves_made << possible_moves[rand(0..(possible_moves.size - 1))]
    when :pegreedy
      best_move =
        possible_moves.max_by { |move| @q[last_state][m_to_i(move)] }
      if rand < @epsilon # pick a random move thats not the best
        other_moves = possible_moves.filter { |move| move != best_move }
        @moves_made << other_moves[rand(0..(other_moves.size - 1))]
      else # pick the best move
        @moves_made << best_move
      end
    when :pgreedy
      @moves_made <<
        possible_moves.shuffle
                      .max_by { |move| @q[last_state][m_to_i(move)] }
    else
      raise Exception.new('invalid strategy')
    end

    if last_move == :call
      @game.total_bet_s = @game.total_bet_t
    elsif last_move == :raise
      @game.total_bet_s = @game.total_bet_t + 3
    else
      @game.total_bet_s
    end
  end

  def q_update(reward = 0)
    a_prime_index = m_to_i(last_move)
    s_prime = last_state

    if !game.final_state?
      s = @states_visited[-2]
      a_index = m_to_i(@moves_made[-2])
      puts "** s  = #{s} a  = #{@moves_made[-2]} **" if @game.troubleshoot
      puts "** s' = #{s_prime} a' = #{last_move} **" if @game.troubleshoot

      if @learning_mode == :sarsa
        @q[s][a_index] = @q[s][a_index] + @learning_rate * (@discount_rate * @q[s_prime][a_prime_index] - @q[s][a_index])
      elsif @learning_mode == :q_learning
        best_legal_move_value =
          get_possible_moves(s_prime)
          .map { |move| @q[s_prime][m_to_i(move)] }
          .max
        @q[s][a_index] = @q[s][a_index] + @learning_rate * (@discount_rate * best_legal_move_value - @q[s][a_index])
      else
        raise Exception.new('invalid learning_mode')
      end
    else # final_state update
      s = last_state
      a_index = m_to_i(last_move)
      puts "**final state: Reward = #{reward}" if @game.troubleshoot
      puts "** s  = #{s} a  = #{last_move} **" if @game.troubleshoot
      @q[s][a_index] =
        @q[s][a_index] + @learning_rate * (reward - @q[s][a_index])
    end
  end

  def save
    @q.save
  end
end

# ---SSally---
# plays postion 1
# phase 1:
# check or fold with any J or heart king
# checks or calls/raises if no check is available holding a Q or the spade king
# raise (or call with no raise available) with any A
class SSally < Player
  def phase1_move
    @last_move =
      case @game.s_card.value
      when 0, 1, 4 # HJ, SJ, HK
        if @game.total_bet_t == 1
          :check
        else
          :fold
        end
      when 2, 3, 5 # HQ, SQ, SK
        if @game.total_bet_s == @game.total_bet_t
          :check
        else
          :call
        end
      when 6, 7 # HA, SA
        if (@game.total_bet_s == 1) && (@game.total_bet_s == @game.total_bet_t)
          :raise
        else
          :call
        end
      end

    case @last_move
    when :raise then @game.total_bet_s = @game.total_bet_t + 3
    when :call then @game.total_bet_s = @game.total_bet_t
    else
      @game.total_bet_s
    end
  end

  # phase 2:
  # Raises (or calls if no raise is available) holding a pair or the SA
  # doesn't fold, prefers to check/call with no pair but with the HA or the SK
  # checks or folds having no pair and the HK or a Q or J.
  # must raise or fold when both players check in phase1
  def phase2_move
    @last_move =
      case combine_cards(@game.s_card, @game.flop_card)
      when 7, 8, 9 # SA, Heart Pair, Spade Pair
        if @game.total_bet_s < @game.total_bet_t
          :call
        else
          :raise
        end
      when 5, 6 # SK, HA
        if (@game.total_bet_s == @game.total_bet_t) && (@game.total_bet_s == 1)
          :raise
        elsif @game.total_bet_s == @game.total_bet_t
          :check
        else
          :call
        end
      else # HK, any Q, any J
        if ((@game.total_bet_s == @game.total_bet_t) && (@game.total_bet_s == 1)) || @game.total_bet_s < @game.total_bet_t
          :fold
        else
          :check
        end
      end

    case @last_move
    when :raise then @game.total_bet_s = @game.total_bet_t + 3
    when :call then @game.total_bet_s = @game.total_bet_t
    else
      @game.total_bet_s
    end
  end
end

# ---TSally---
# plays position 2
# Phase1: checks or folds holding a J or the H king
# checks or calls if no check is available holding Q or the spade K
# and raises (or calls if no raise is available) holding an A.
# Phase 2: Raises (or calls if can't raise) holding a pair or the SA
# checks or calls but does not fold holding no pair but the heart A or the SK
# checks or folds having no pair and the HK or a Q or J.
class TSally < Player
  def phase1_move
    @last_move =
      case @game.t_card.value
      when 0, 1, 4 # HJ, SJ, HK
        if @game.total_bet_s == @game.total_bet_t
          :check
        else
          :fold
        end
      when 2, 3, 5 # HQ, SQ, SK
        if @game.total_bet_s == @game.total_bet_t
          :check
        else
          :call
        end
      when 6, 7 then :raise # HA, SA
      end

    case @last_move
    when :raise then @game.total_bet_t = @game.total_bet_s + 3
    when :call then @game.total_bet_t = @game.total_bet_s
    else
      @game.total_bet_t
    end
  end

  def phase2_move
    @last_move =
      case combine_cards(@game.t_card, @game.flop_card)
      when 7, 8, 9 then :raise # SA, Heart Pair, Spade Pair
      when 5, 6 # SK, HA
        if @game.total_bet_s == @game.total_bet_t
          :check
        else
          :call
        end
      else # HK, any Q, any J
        if @game.total_bet_t == @game.total_bet_s
          :check
        else
          :fold
        end
      end

    case @last_move
    when :raise then @game.total_bet_t = @game.total_bet_s + 3
    when :call then @game.total_bet_t = @game.total_bet_s
    else
      @game.total_bet_t
    end
  end
end
