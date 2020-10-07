require 'minitest/autorun'
require './src/game'

class UHLPOTest < MiniTest::Test
  def test_card_HJ
    c = Card.new('HJ')
    assert c.suit == 'H' && c.rank == 'J' && c.value == 0
  end

  def test_card_SJ
    c = Card.new('SJ')
    assert c.suit == 'S' && c.rank == 'J' && c.value == 1
  end

  def test_card_HQ
    c = Card.new('HQ')
    assert c.suit == 'H' && c.rank == 'Q' && c.value == 2
  end

  def test_card_SQ
    c = Card.new('SQ')
    assert c.suit == 'S' && c.rank == 'Q' && c.value == 3
  end

  def test_card_HK
    c = Card.new('HK')
    assert c.suit == 'H' && c.rank == 'K' && c.value == 4
  end

  def test_card_SK
    c = Card.new('SK')
    assert c.suit == 'S' && c.rank == 'K' && c.value == 5
  end

  def test_card_HA
    c = Card.new('HA')
    assert c.suit == 'H' && c.rank == 'A' && c.value == 6
  end

  def test_card_SA
    c = Card.new('SA')
    assert c.suit == 'S' && c.rank == 'A' && c.value == 7
  end

  def test_combine_cards_HJ_no_pair
    player_card = Card.new(7)
    flop_card = Card.new(0)
    assert combine_cards(player_card, flop_card) == 0
  end

  def test_combine_cards_HJ_pair
    player_card = Card.new(7)
    flop_card = Card.new(8)
    assert combine_cards(player_card, flop_card) == 8
  end

  def test_combine_cards_SJ_pair
    player_card = Card.new(8)
    flop_card = Card.new(7)
    assert combine_cards(player_card, flop_card) == 9
  end

  def test_combine_cards_HQ_no_pair
    player_card = Card.new(13)
    flop_card = Card.new(9)
    assert combine_cards(player_card, flop_card) == 2
  end

  def test_combine_cards_HQ_pair
    player_card = Card.new(13)
    flop_card = Card.new(5)
    assert combine_cards(player_card, flop_card) == 8
  end

  def test_combine_cards_SQ_pair
    player_card = Card.new(4)
    flop_card = Card.new(6)
    assert combine_cards(player_card, flop_card) == 9
  end

  def test_encode_state1_1_1_SA
    player_card = Card.new(0)
    assert encode_state1(1, 1, player_card) == '01017'
  end

  def test_encode_state1_4_1_SK
    player_card = Card.new(2)
    assert encode_state1(4, 1, player_card) == '04015'
  end

  def test_encode_state1_10_10_HQ
    player_card = Card.new(13)
    assert encode_state1(10, 10, player_card) == '10102'
  end

  def test_encode_state2_10_10_HQ_SQ
    player_card = Card.new(13)
    flop_card = Card.new(14)
    assert encode_state2(10, 10, player_card, flop_card) == '110108'
  end

  def test_encode_state2_13_10_SA_SQ
    player_card = Card.new(10)
    flop_card = Card.new(14)
    assert encode_state2(13, 10, player_card, flop_card) == '113107'
  end

  def test_encode_state2_13_13_SK_HK
    player_card = Card.new(12)
    flop_card = Card.new(11)
    assert encode_state2(13, 13, player_card, flop_card) == '113139'
  end

  def test_encode_state2_1_1_HJ_HK
    player_card = Card.new(7)
    flop_card = Card.new(11)
    assert encode_state2(1, 1, player_card, flop_card) == '101010'
  end

  def test_decode_state01017
    assert decode_state('01017') == [1, 1, 7]
  end

  def test_decode_state13102
    assert decode_state('13102') == [13, 10, 2]
  end

  def test_decode_state110109
    assert decode_state('110109') == [10, 10, 9]
  end

  def test_decode_state104043
    assert decode_state('104043') == [4, 4, 3]
  end

  def test_s_possible_moves_01017
    assert s_possible_moves("01017") == [:check, :raise]
  end

  def test_s_possible_moves_01042
    assert s_possible_moves("01042") == [:call, :fold]
  end

  def test_s_possible_moves_101013
    assert s_possible_moves("101012") == [:raise, :fold]
  end

  def test_s_possible_moves_104049
    assert s_possible_moves("104049") == [:check, :raise]
  end

  def test_player_SSally_adjust_bankroll_minus4
    t = TSally.new()
    t.adjust_bankroll(-4)
    assert t.bankroll == -4
  end

  def test_player_SSally_adjust_bankroll_plus13
    t = TSally.new()
    t.adjust_bankroll(13)
    assert t.bankroll == 13
  end

  def test_SSally_benchmark0
    s = SSally.new
    t = TSally.new
    g = Game.new(s, t, 0, "benchmark0.txt")
    s.game = g
    t.game = g
    g.player_s_output = 'rake_out0.txt'
    g.run_tournament
    assert s.bankroll == 2
  end

  def test_SSally_benchmark1
    s = SSally.new
    t = TSally.new
    g = Game.new(s, t, 0, "benchmark1.txt")
    g.player_s_output = 'rake_out1.txt'
    s.game = g
    t.game = g

    g.run_tournament
    assert s.bankroll == -32
  end

  def test_SSally_benchmark2
    s = SSally.new
    t = TSally.new
    g = Game.new(s, t, 0, "benchmark2.txt")
    g.player_s_output = 'rake_out2.txt'
    s.game = g
    t.game = g

    g.run_tournament
    assert s.bankroll == -430
  end

  def test_SSally_benchmark3
    s = SSally.new
    t = TSally.new
    g = Game.new(s, t, 0, 'benchmark3.txt')
    g.player_s_output = 'rake_out3.txt'
    s.game = g
    t.game = g

    g.run_tournament
    assert s.bankroll == -838
  end

  def test_learning_s_0101X
    s = LearningS.new(0.15, :sarsa, 1, 0.08, :prandom, 'wont_save_this_data')
    t = TSally.new
    g = Game.new(s, t, 1)
    s.game = g
    t.game = g
    g.verbose = false
    g.phase1
    if [:check, :call].include?(t.last_move)
      assert [:check, :raise].include?(s.last_move)
    elsif t.last_move == :raise
      assert [:call, :fold].include?(s.last_move)
    elsif
      assert t.last_move == :fold && s.last_move == :raise
    end
  end
end

=begin
index rank suit value
0 A Spade 7
1 A Heart 6
2 K Spade 5
3 K Heart 4
4 Q Spade 3
5 Q Heart 2
6 Q Spade 3
7 J Heart 0
8 J Spade 1
9 A Heart 6
10 A Spade 7
11 K Heart 4
12 K Spade 5
13 Q Heart 2
14 Q Spade 3
15 Q Heart 2
16 J Spade 1
17 J Heart 0
=end
