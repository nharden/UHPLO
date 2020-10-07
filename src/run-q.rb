require './src/game'

def stopwatch
  starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  yield
  ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  elapsed = ending - starting
  puts "minutes spent running: #{elapsed / 60}"
end

# if a .marshal file with the name [experiment_name]_qtable.marshal exists in
# the root directory of the project (one level above the src folder) then then
# agent will be initialized with the Q-table contained in that file. if it does
# not exist the agent will be initialized with an empty Q-table
# in either case the q-table is saved in machine radable format to the file
# at the end of the experiment. A human readable q-table and hand history are
# saved as text files as well.
experiment_name = "test_q"

# the parameters for LearningS are learning_rate, :q_learning or :sarsa:,
# discount_rate, :prandom, :pgreedy, or :pegreedy, and finally the name of the
# .marshal file where the agent's Q-table is saved and loaded from.
s = LearningS.new(0.35, :q_learning, 1, 0.2, :prandom, experiment_name + '_qtable.marshal')

#s = LearningS.new(0.35, :sarsa, 1, 0.2, :prandom, experiment_name + '_qtable.marshal')
t = TSally.new()

BENCHMARKS = %w(benchmark0.txt benchmark1.txt benchmark2.txt benchmark3.txt)
# enter the number of the benchmark you would like to run below
BENCHMARK_NUMBER = 1

# random tournament with a specified # of hands
#g = Game.new(s, t, 1000000)

# tournament loaded from a benchmark
g = Game.new(s, t, 1, BENCHMARKS[BENCHMARK_NUMBER])

#where to save the bank account history
g.player_s_output = experiment_name + '_history.txt'
# set verbose to true to see play by play output
g.verbose = false
# set experiment to true to switch strategy to pegreedy after 400 hands
g.experiment = true

s.game = g
t.game = g

stopwatch { puts g.run_tournament }
