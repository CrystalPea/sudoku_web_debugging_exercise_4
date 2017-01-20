require_relative './lib/sudoku'
require 'sinatra/base'
require 'sinatra/flash'
require_relative './lib/sudoku_helpers'

class SudokuWeb < Sinatra::Base

  configure do
    use(Rack::Session::Cookie,
      :key => 'rack.session',
      :path => '/',
      :expire_after => 2592000, # In seconds
      :secret => 'I am the secret code to encrypt the cookie')
  end

  register Sinatra::Flash
  helpers SudokuHelpers

  helpers do
    def generate_new_game(difficulty=Sudoku::EASY)
      if session[:current_sudoku] && session[:set_sudoku]
        sudoku_puzzle = Sudoku.new(session[:current_sudoku])
      else
        sudoku_puzzle = Sudoku.generate(difficulty)
        session[:set_sudoku] = sudoku_puzzle.to_s
        session[:current_sudoku] = sudoku_puzzle.to_s
      end
    end

    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="You should subscribe to see the solution. "'
      halt 401, "Not authorized\n"
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', 'admin']
    end

  end

  post '/' do
    current_puzzle_state = convert_html_puzzle_to_string params[:cells]
    session[:current_sudoku] = current_puzzle_state
    flash[:info] = words_of_encouragement current_puzzle_state, session[:set_sudoku]
    redirect to('/')
  end

  get '/new' do
    session.clear
    redirect to('/')
  end

  get '/protected' do
    protected!
    "Welcome, authenticated client"
  end

  get '/solution' do
    # protected!
    # "Welcome, authenticated client"
    cells = get_solved_sudoku_cells(session[:set_sudoku])
    session[:current_sudoku] = convert_html_puzzle_to_string(cells)
    redirect to('/')
  end

  get '/' do
    generate_new_game
    cells_criteria
    erb :home
  end

  get '/hard' do
    session.clear
    generate_new_game(Sudoku::HARD)
    cells_criteria
    erb :home
  end

end
