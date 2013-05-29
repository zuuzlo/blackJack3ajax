require 'rubygems'
require 'sinatra'
#require 'pry'

set :sessions, true
    
#TODO refractor session[:dealer_show] = false and @show_hit_or_stay_buttons = false
helpers do
  def cards
    suits = ['H', 'D', 'C', 'S']
    values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
    session[:deck] = suits.product(values).shuffle! # [ ['H', '9'], ['C', 'K'] ... ]
  end

  def card_img(card)
    case card[0]
    when "H" 
      card_suit = "h"
    when "D"
      card_suit = "d"
    when "C"
      card_suit = "c"
    when "S"
      card_suit = "s"
    end

    case card[1]
    when "J"
      card_value = "j"
    when "Q"
      card_value = "q"
    when "K"
      card_value = "k"
    when "A"
      card_value = "1"
    else
      card_value = card[1]
    end

    "<img src=/images/cards2/#{card_suit}#{card_value}.png />"
  end

  def hand_value(card_arr)
    arr = card_arr.map {|e| e[1]}
    total = 0
    arr.each do |value|
      if value == "A"
        total += 11
      elsif value.to_i == 0 #J,Q,K
        total += 10
      else
        total += value.to_i
      end
    end

    #correct for aces
    arr.select{|e| e[0] == "A"}.count.times do
      total -= 10 if total > 21
    end
    total
  end

  def loser!(msg)
    @show_hit_or_stay_buttons = false
    session[:dealer_show] = false
    session[:bankroll] -= session[:player_bet]
    show_totals
    @lose_message = "#{msg} <strong>#{session[:player_name]} loses</strong> #{session[:player_bet]}."
  end

  def winner!(msg)
    @show_hit_or_stay_buttons = false
    session[:dealer_show] = false
    session[:bankroll] += session[:player_bet]
    show_totals
    @win_message = "#{msg} <strong>#{session[:player_name]} wins</strong> #{session[:player_bet]}."
  end

  def tie!(msg)
    @show_hit_or_stay_buttons = false
    show_totals
    session[:dealer_show] = false
    @tie_message = "#{msg} <strong>#{session[:player_name]} ties with dealer."
  end

  def insurance_win!(msg)
    session[:bankroll] += 2 * session[:insurance_show].to_i
    @insurance_message_win = "#{msg} you #{2 * session[:insurance_show].to_i}"
  end

  def insurance_lose!(msg)
    session[:bankroll] -= session[:insurance_show].to_i
    @insurance_message_lose = "#{msg} you #{session[:insurance_show].to_i}"
    if session[:bankroll] <= 0
      redirect '/game/out_of_cash'
    end
  end

  def dealer_turn
    total = hand_value(session[:dealer_cards])
    while total < 17
      session[:dealer_cards] << session[:deck].pop
      total = hand_value(session[:dealer_cards])
    end
  end

  def show_totals
    @player_total = hand_value(session[:player_cards])
    @dealer_total = hand_value(session[:dealer_cards])
  end

end #helper end

before do
  @show_hit_or_stay_buttons = true
end

get '/' do
  if session[:player_name]
    redirect '/pre_game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  session[:player_name] = params[:player_name]
  redirect '/pre_game'
end

get '/pre_game' do
  cards
  session[:bankroll] = 1000
  @message = "#{session[:player_name]}, your bank roll is #{session[:bankroll]}
  . Please enter your first hands bet below."
  erb :pre_game
end

post '/pre_game' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "#{session[:player_name]}, you must make a bet."
    halt erb(:pre_game)
  elsif params[:bet_amount].to_i > session[:bankroll]
    @error = "#{session[:player_name]}, your bet amount cannot be greater than what you have (#{session[:bankroll]})"
    halt erb(:pre_game)
  else #happy path
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end

get '/game' do

  # deal cards
  if session[:deck].size < 10
    cards
  end

  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_show] = true
  session[:insurance_show] = nil
  

  redirect '/game/action'
end

get '/game/action' do
  player_total = hand_value(session[:player_cards])
  dealer_total = hand_value(session[:dealer_cards])
  if session[:dealer_cards][0][1] == "A" && session[:insurance_show].nil?
    @play_message = "#{session[:player_name]}, dealer has Ace showing would you like to buy insurance?"
    @show_hit_or_stay_buttons = false
    @show_insurance_bet = true
  elsif dealer_total == 21 && player_total == 21
    tie!("You and the Dealer have Blackjack. ")
  elsif dealer_total == 21
    if session[:insurance_show].to_i != 0
      insurance_win!("Your insurance bet wins") #TODO correct message
      loser!("Dealer has Blackjack, ") 
          else
      loser!("Dealer has Blackjack, ")
          end
  elsif player_total == 21
    session[:player_bet] *= 1.5 #so player gets 1.5 x bet for blackjack
    winner!("You have <strong>BLACKJACK</strong> ")
  else
    @play_message = "#{session[:player_name]}, action is on you. Your bet is #{session[:player_bet]}"
  end
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = hand_value(session[:player_cards])
  
  if player_total > 21
    loser!("It looks like #{session[:player_name]} busted at #{player_total}.")   
  else
    @play_message = "#{session[:player_name]}, action is on you. Your bet is #{session[:player_bet]}"
  end
  erb :game, layout: false
end
=begin
post '/game/player/dd' do
  session[:player_cards] << session[:deck].pop
  player_total = hand_value(session[:player_cards])
  
  if player_total > 21
    loser!("It looks like #{session[:player_name]} busted at #{player_total}.") 
    erb :game, layout: false  
  else
    #request '/game/dealer/hit', 307
    redirect '/game/dealer/hit'
  end
end
=end

post '/game/dealer/hit' do
  @player_total = hand_value(session[:player_cards])
  if params[:double_down] == "Double Down"
    session[:player_cards] << session[:deck].pop
    @player_total = hand_value(session[:player_cards])
    session[:player_bet] *= 2
  end
  if @player_total > 21
    loser!("It looks like #{session[:player_name]} busted at #{player_total}.") 
  else
    @dealer_total =  hand_value(session[:dealer_cards])
    @player_total = hand_value(session[:player_cards])
    @show_hit_or_stay_buttons = false
    session[:dealer_show] = false
    if @dealer_total < 17
      dealer_turn
      @dealer_total =  hand_value(session[:dealer_cards])
    end
    if @dealer_total > 21
      winner!("The dealer busted,")
    else
      if @player_total < @dealer_total
        loser!("#{session[:player_name]} stayed at #{@player_total}, and the dealer has #{@dealer_total}.")
      elsif @player_total > @dealer_total
        winner!("#{session[:player_name]} stayed at #{@player_total}, and the dealer has #{@dealer_total}.")
      else
        tie!("Both #{session[:player_name]} and the dealer stayed at #{@player_total}.")
      end
    end
  end
  erb :game, layout: false
end

post '/game/insurance' do
  if params[:no_insurance] == "No Thanks"
    session[:insurance_show] = "No"
    redirect '/game/action'
  end
  if params[:insurance_amount].nil? || params[:insurance_amount].to_i == 0
    @error = "#{session[:player_name]}, you must make an insurance bet."
    @show_hit_or_stay_buttons = false
    @show_insurance_bet = true
    halt erb(:game)
  elsif params[:bet_amount].to_i > session[:bankroll]
    @error = "#{session[:player_name]}, your bet amount cannot be greater than what you have (#{session[:bankroll]})"
    halt erb(:game)
  else #happy path
    session[:insurance_show] = params[:insurance_amount].to_i
    #session[:bankroll] -= session[:insurance_show].to_i
    redirect '/game/action'
  end
end

post '/game/deal' do
  if session[:bankroll] <= 0
    redirect '/game/out_of_cash'
  end

  if params[:deal] == "Deal"
    if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
      @error = "#{session[:player_name]}, you must make bet."
      @show_hit_or_stay_buttons = false
      halt erb(:game)
    elsif params[:bet_amount].to_i > session[:bankroll]
      @error = "#{session[:player_name]}, your bet amount cannot be greater than what you have (#{session[:bankroll]})"
      halt erb(:game)
    else #happy path
     
      session[:player_bet] = params[:bet_amount].to_i
      redirect '/game'
    end
  else
    redirect '/game/quit'
  end
end

get '/game/quit' do
  erb :quit
end

get 'shuffle' do

end

get 'cut_cards' do

end

get '/game/out_of_cash' do
  erb :out_of_cash
end
