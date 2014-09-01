expect = require "expect.js"

# Ackleys function (-5 ≤ x,y ≤ 5) - only initial solution is constrained
ackleys =
  makeRandomSolution: () ->
    x: -5 + Math.random()*10
    y: -5 + Math.random()*10
  findNeighbour: (point) ->
    x: point.x + -.1 + Math.random()*.2
    y: point.y + -.1 + Math.random()*.2
  recombine: (mother, father, params) ->
    x: if Math.random() and params?.recombinationStrategy is 'bin' >= .5 then mother.x else father.x
    y: if Math.random() and params?.recombinationStrategy is 'bin' >= .5 then father.y else mother.y
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
  makeRandomSolution: () ->
    x: -10 + Math.random()*20
    y: -10 + Math.random()*20
  findNeighbour: (point) ->
    x: point.x + -.1 + Math.random()*.2
    y: point.y + -.1 + Math.random()*.2
  recombine: (mother, father, params) ->
    x: if Math.random() and params?.recombinationStrategy is 'bin' >= .5 then mother.x else father.x
    y: if Math.random() and params?.recombinationStrategy is 'bin' >= .5 then father.y else mother.y
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
  makeRandomSolution: () ->
    x: -10 + Math.random()*20
    y: -10 + Math.random()*20
  findNeighbour: (point) ->
    x: point.x + -.1 + Math.random()*.2
    y: point.y + -.1 + Math.random()*.2
  recombine: (mother, father, params) ->
    x: if Math.random() and params?.recombinationStrategy is 'bin' >= .5 then mother.x else father.x
    y: if Math.random() and params?.recombinationStrategy is 'bin' >= .5 then father.y else mother.y
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

describe "SimulatedAnnealing", () ->
  
  sa = require("./../src/MetaHeuristics.coffee").SimulatedAnnealing

  describe "run w Ackleys function", () ->
    it "finds a global minimum at (0,0)", (done) -> 
      sa.run(ackleys).then(
        (winner) ->
          try 
            expect(winner.x).to.be.within(-0.01, 0.01)
            expect(winner.y).to.be.within(-0.01, 0.01)
            done()
          catch e
            done(e)
      )
  
  describe "run w Matayas function", () ->
    it "finds a global minimum at (0,0)", (done) ->
      sa.run(matayas).then(
        (winner) ->
          try 
            expect(winner.x).to.be.within(-0.01, 0.01)
            expect(winner.y).to.be.within(-0.01, 0.01)
            done()
          catch e
            done(e)
      )

  describe "run w Booths function", () ->
    it "finds a global minimum at (1,3)", (done) ->
      sa.run(booths).then(
        (winner) ->
          try 
            expect(winner.x).to.be.within(0.99, 1.01)
            expect(winner.y).to.be.within(2.99, 3.01)
            done()
          catch e
            done(e)
      )

describe "Evolution", () ->
  
  evolution = require("./../src/MetaHeuristics.coffee").Evolution

  describe "run w Ackleys function", () ->
    it "finds a global minimum at (0,0)", (done) -> 
      evolution.run(ackleys).then(
        (winner) ->
          try 
            expect(winner.x).to.be.within(-0.01, 0.01)
            expect(winner.y).to.be.within(-0.01, 0.01)
            done()
          catch e
            done(e)
      )
  
  describe "run w Matayas function", () ->
    it "finds a global minimum at (0,0)", (done) ->
      evolution.run(matayas).then(
        (winner) ->
          try 
            expect(winner.x).to.be.within(-0.01, 0.01)
            expect(winner.y).to.be.within(-0.01, 0.01)
            done()
          catch e
            done(e)
      )

  describe "run w Booths function", () ->
    it "finds a global minimum at (1,3)", (done) ->
      evolution.run(booths).then(
        (winner) ->
          try 
            expect(winner.x).to.be.within(0.99, 1.01)
            expect(winner.y).to.be.within(2.99, 3.01)
            done()
          catch e
            done(e)
      )


describe "DifferentialEvolution", () ->
  
  de = require("./../src/MetaHeuristics.coffee").DifferentialEvolution

  describe "run w Ackleys function", () ->
    it "finds a global minimum at (0,0)", (done) -> 
      de.run(ackleys).then(
        (winner) ->
          try 
            expect(winner.x).to.be.within(-0.01, 0.01)
            expect(winner.y).to.be.within(-0.01, 0.01)
            done()
          catch e
            done(e)
      )
  
  describe "run w Matayas function", () ->
    it "finds a global minimum at (0,0)", (done) ->
      de.run(matayas).then(
        (winner) ->
          try 
            expect(winner.x).to.be.within(-0.01, 0.01)
            expect(winner.y).to.be.within(-0.01, 0.01)
            done()
          catch e
            done(e)
      )

  describe "run w Booths function", () ->
    it "finds a global minimum at (1,3)", (done) ->
      de.run(booths).then(
        (winner) ->
          try 
            expect(winner.x).to.be.within(0.99, 1.01)
            expect(winner.y).to.be.within(2.99, 3.01)
            done()
          catch e
            done(e)
      )

