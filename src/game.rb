require './src/players'
require './src/benchmark_reader'
class Game
  attr_accessor :total_bet_s, :total_bet_t, :verbose, :experiment, :troubleshoot, :player_s_output, :sample_rate
  attr_reader :s_card, :t_card, :flop_card, :phase

  def initialize(player1, player2, number_of_hands_to_play, filename = :none)
    @s, @t = player1, player2
    @total_bet_s, @total_bet_t = 1, 1
    @hands_played = 0
    if filename == :none
      @max_hands = number_of_hands_to_play
      @deck = Deck.new()
      @s_card, @t_card, @flop_card = @deck.cards.sample(3)
    else
      @benchmark = BenchmarkReader.new(filename)
      @max_hands = @benchmark.size
      @s_card, @t_card, @flop_card = @benchmark.next
    end
    @sample_rate = [@max_hands/800, 2].max
    @phase = :phase1
    @verbose = false
    @troubleshoot = false
    @experiment = false
  end

  def reset
    @total_bet_s, @total_bet_t = 1, 1
    @hands_played += 1
    @phase = :phase1
    if @benchmark
      @s_card, @t_card, @flop_card = @benchmark.next
    else
      @s_card, @t_card, @flop_card = @deck.cards.sample(3)
    end
    @s.reset_moves_and_states
    @t.reset_moves_and_states
  end

  # if verbose == false the program runs ~10 times faster
  # but only outputs the final game numbers and q_table/report
  def run_tournament
    while @hands_played < @max_hands
      # Experiments 1,2,3, and 4
      if @experiment && @hands_played == 400 && @s.class == LearningS
        @s.strategy = :pegreedy
      end
      @s.record(@hands_played) if (@hands_played % @sample_rate).zero?
      phase1
      phase2 unless @s.last_move == :fold || @t.last_move == :fold
      end_hand
      reset
    end
    @s.record(@hands_played)
    @s.save
    @s.print_table
    @s.save_history(@player_s_output)
    @t.save
    "s has #{@s.bankroll}, t has #{@t.bankroll}"
  end

  def phase1
    @phase = :phase1
    puts "phase1\ns_card = #{@s_card} t_card = #{@t_card}" if @verbose

    @s.phase1_move
    puts "s move = #{@s.last_move}, total_bet_s = #{@total_bet_s}" if @verbose
    p @s.states_visited if @troubleshoot

    @t.phase1_move
    puts "t move = #{@t.last_move}, total_bet_t = #{@total_bet_t}" if @verbose

    if @t.last_move == :raise && @s.last_move != :fold
      @s.phase1_move
      puts "s move = #{@s.last_move}, total_bet_s = #{@total_bet_s}" if @verbose
      p @s.states_visited if @troubleshoot
    end
  end

  def phase2
    @phase = :phase2
    puts "\nphase2\nflop card = #{@flop_card}" if @verbose

    @s.phase2_move
    puts "s move = #{@s.last_move}, total_bet_s = #{@total_bet_s}" if @verbose
    p @s.states_visited if @troubleshoot

    unless @s.last_move == :fold
      @t.phase2_move
      puts "t move = #{@t.last_move}, total_bet_t = #{@total_bet_t}" if @verbose
    end

    if @t.last_move == :raise && @s.last_move != :fold
      @s.phase2_move
      puts "s move = #{@s.last_move}, total_bet_s = #{@total_bet_s}" if @verbose
      p @s.states_visited if @troubleshoot
    end
  end

  def end_hand
    @phase = :final_state
    p @s.states_visited if @troubleshoot
    result =
      if @s.last_move == :fold
        handle_payouts(-@total_bet_s, @total_bet_s)
        @s.q_update(-@total_bet_s)
        't wins because s folded'
      elsif @t.last_move == :fold
        handle_payouts(@total_bet_t, -@total_bet_t)
        @s.q_update(@total_bet_t)
        's wins because t folded'
      else
        s_hand = combine_cards(@s_card, @flop_card)
        t_hand = combine_cards(@t_card, @flop_card)
        if s_hand == t_hand
          @s.q_update(0)
          'it\'s a tie'
        elsif s_hand > t_hand
          handle_payouts(@total_bet_t, -@total_bet_t)
          @s.q_update(@total_bet_t)
          's has a better hand'
        else
          handle_payouts(-@total_bet_s, @total_bet_s)
          @s.q_update(-@total_bet_s)
          't has a better hand'
        end
      end
    puts "\n#{result}\ns has #{@s.bankroll}, t has #{@t.bankroll}" if @verbose
    puts '*' * 30 if @verbose
  end

  def state(player)
    game_state =
      case player.to_sym
      when :S, :s
        case @phase
        when :phase1 then encode_state1(@total_bet_s, @total_bet_t, @s_card)
        else
          encode_state2(@total_bet_s, @total_bet_t, @s_card, @flop_card)
        end
      when :T, :t
        case @phase
        when :phase1 then encode_state1(@total_bet_s, @total_bet_t, @t_card)
        else
          encode_state2(@total_bet_s, @total_bet_t, @t_card, @flop_card)
        end
      else
        raise Exception.new('invalid player symbol, use s or t')
      end
    game_state
  end

  def handle_payouts(s_payout, t_payout)
    @s.adjust_bankroll(s_payout)
    @t.adjust_bankroll(t_payout)
  end

  def final_state?
    @phase == :final_state
  end
end
