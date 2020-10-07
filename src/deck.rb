# modified from https://stackoverflow.com/questions/2641329/programming-technique-how-to-create-a-simple-card-game
def combine_cards(player_card, flop_card)
  case player_card.rank
  when flop_card.rank
    8 + (1 if player_card.suit == 'S').to_i
  else
    player_card.value
  end
end

class Card
  RANKS = %w[A A K K Q Q Q J J].freeze
  SUITS = %w[S H].freeze
  attr_accessor :rank, :suit, :value

  def to_s
    "#{@suit}#{@rank}"
  end

  def initialize(id)
    if id.class == String
      @suit, @rank = id.chars
    else
      @suit = SUITS[id % 2]
      @rank = RANKS[id % 9]
    end

    @value =
      case @rank
      when 'A' then 6
      when 'K' then 4
      when 'Q' then 2
      when 'J' then 0
      else
        raise Exception.new("error assigning value to card #{@suit}#{@rank}")
      end

    if @suit == 'S'
      @value += 1
    elsif @suit != 'H'
      raise Exception.new("#{@suit} is not a valid suit")
    end
  end
end

class Deck
  attr_accessor :cards
  def initialize
    # shuffle array and init each Card
    self.cards = (0..17).to_a.shuffle.collect { |id| Card.new(id) }
  end
end
