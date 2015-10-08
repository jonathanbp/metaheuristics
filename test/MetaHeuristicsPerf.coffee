Q   = require 'q'
_   = require 'lodash'

# Ackleys function (-5 ≤ x,y ≤ 5) - only initial solution is constrained
ackleys =
  name: "Ackleys"
  makeRandomSolution: () ->
    x: -5 + Math.random()*10
    y: -5 + Math.random()*10
  findNeighbour: (point) ->
    x: point.x + -.1 + Math.random()*.2
    y: point.y + -.1 + Math.random()*.2
  recombine: (mother, father, params) ->
    x: if params?.recombinationStrategy is 'bin' and Math.random() >= .5 then mother.x else father.x
    y: if params?.recombinationStrategy is 'bin' and Math.random() >= .5 then father.y else mother.y
  mutate: (original) ->
    rnd = Math.random()
    x: original.x + if rnd >= .5 then -1 + Math.random()*2 else 0
    y: original.y + if rnd < .5 then -1 + Math.random()*2 else 0

  # operators for DE
  add: (individual1, individual2) ->
    x: individual1.x + individual2.x
    y: individual1.y + individual2.y
  subtract: (individual1, individual2) ->
    x: individual1.x - individual2.x
    y: individual1.y - individual2.y
  multiply: (factor, individual) ->
    x: factor * individual.x
    y: factor * individual.y

  fitness: (point) ->
    x = point.x
    y = point.y
    -20*Math.exp(-.2*Math.sqrt(.5*(x*x+y*y)))-Math.exp(.5*(Math.cos(2*Math.PI*x)+Math.cos(2*Math.PI*y)))+20+Math.E

# Matayas function
matayas =
  name: "Matayas"
  makeRandomSolution: () ->
    x: -10 + Math.random()*20
    y: -10 + Math.random()*20
  findNeighbour: (point) ->
    x: point.x + -.1 + Math.random()*.2
    y: point.y + -.1 + Math.random()*.2
  recombine: (mother, father, params) ->
    x: if params?.recombinationStrategy is 'bin' and Math.random() >= .5 then mother.x else father.x
    y: if params?.recombinationStrategy is 'bin' and Math.random() >= .5 then father.y else mother.y
  mutate: (original) ->
    rnd = Math.random()
    x: original.x + if rnd >= .5 then -5 + Math.random()*10 else 0
    y: original.y + if rnd < .5 then -5 + Math.random()*10 else 0

  # operators for DE
  add: (individual1, individual2) ->
    x: individual1.x + individual2.x
    y: individual1.y + individual2.y
  subtract: (individual1, individual2) ->
    x: individual1.x - individual2.x
    y: individual1.y - individual2.y
  multiply: (factor, individual) ->
    x: factor * individual.x
    y: factor * individual.y

  fitness: (point) ->
    x = point.x
    y = point.y
    .26*(x*x+y*y) - .48*x*y

# Booths function
booths =
  name: "Booths"
  makeRandomSolution: () ->
    x: -10 + Math.random()*20
    y: -10 + Math.random()*20
  findNeighbour: (point) ->
    x: point.x + -.1 + Math.random()*.2
    y: point.y + -.1 + Math.random()*.2
  recombine: (mother, father, params) ->
    x: if params?.recombinationStrategy is 'bin' and Math.random() >= .5 then mother.x else father.x
    y: if params?.recombinationStrategy is 'bin' and Math.random() >= .5 then father.y else mother.y
  mutate: (original) ->
    rnd = Math.random()
    x: original.x + if rnd >= .5 then -10 + Math.random()*20 else 0
    y: original.y + if rnd < .5 then -10 + Math.random()*20 else 0

  # operators for DE
  add: (individual1, individual2) ->
    x: individual1.x + individual2.x
    y: individual1.y + individual2.y
  subtract: (individual1, individual2) ->
    x: individual1.x - individual2.x
    y: individual1.y - individual2.y
  multiply: (factor, individual) ->
    x: factor * individual.x
    y: factor * individual.y

  fitness: (point) ->
    x = point.x
    y = point.y
    Math.pow((x+2*y-7),2)+Math.pow((2*x+y-5),2)


out = console.log

run = (algorithm, problem) ->
  deferred = Q.defer()
  t0 = Date.now()
  algorithm.run(problem).then(
    (champion) ->
      t1 = Date.now()
      deferred.resolve({ algorithm: algorithm, problem: problem, champion: champion, time: (t1-t0)/1000 })
  )
  deferred.promise

SimulatedAnnealing          = require("./../src/MetaHeuristics.coffee").SimulatedAnnealing
Evolution                   = require("./../src/MetaHeuristics.coffee").Evolution
DifferentialEvolution       = require("./../src/MetaHeuristics.coffee").DifferentialEvolution


algorithms = [new SimulatedAnnealing(), new Evolution(), new DifferentialEvolution()]
problems = [ackleys, matayas, booths]

Q.allSettled(
  _.flatten(
    for a in algorithms
      do (a) ->
        for p in problems
          do (p) -> run(a, p)
  )
).then (results) -> out JSON.stringify(results)
