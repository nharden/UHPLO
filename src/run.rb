require './src/game'

def stopwatch
  starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  yield
  ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  elapsed = ending - starting
  puts "minutes spent running: #{elapsed / 60}"
end

s = SSally.new
#s = Learning_S.new(0.35, :q_learning, 1, 0.08, :prandom, "q_learning_qtable.marshal")
#s = Learning_S.new(0.15, :sarsa, 1, 0.08, :pgreedy, "sarsa_qtable.marshal")
t = TSally.new

BENCHMARKS = %w(benchmark0.txt benchmark1.txt benchmark2.txt benchmark3.txt)
BENCHMARK_NUMBER = 3

# random tournament with a specified # of hands
#g = Game.new(s, t, 1000000)
# tournament loaded from a benchmark
g = Game.new(s, t, 1, BENCHMARKS[BENCHMARK_NUMBER])

g.player_s_output =
  ['dumb_S', BENCHMARKS[BENCHMARK_NUMBER]].join('_')

g.verbose = false
s.game = g
t.game = g

stopwatch {puts g.run_tournament}
