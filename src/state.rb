require './src/deck.rb'

def s_possible_moves(state)
  total_bet_s, total_bet_t, _card_or_hand_value = decode_state(state)
  phase = case state.length
  when 5 then :phase1
  when 6 then :phase2
  end
  if (total_bet_s == total_bet_t) && (total_bet_s == 1) && (phase == :phase1)
    possible_moves = [:check, :raise]
  elsif (total_bet_s == total_bet_t) && (total_bet_s == 1) && (phase == :phase2)
    possible_moves = [:raise, :fold]
  elsif (total_bet_s > 1) && (total_bet_s == total_bet_t)
    possible_moves = [:check, :raise]
  elsif total_bet_s < total_bet_t
    possible_moves = [:call, :fold]
  end
  possible_moves
end

def encode_state1(total_bet_s, total_bet_t, player_card)
  "%02d" % total_bet_s + "%02d" % total_bet_t + player_card.value.to_s
end

def encode_state2(total_bet_s, total_bet_t, player_card, flop_card)
  '1' + "%02d" % total_bet_s + "%02d" % total_bet_t + combine_cards(player_card, flop_card).to_s
end

def decode_state(state)
  modified_state = state
  modified_state = state.slice(1..) if state.length == 6
  total_bet_s = modified_state.to_i/1000
  total_bet_t = (modified_state.to_i%1000)/10
  card_value = (modified_state.to_i%10)
  [total_bet_s, total_bet_t, card_value]
end
