_        = require 'lodash-node'
Parallel = require "paralleljs"
Q        = require "q"



# A (simple) simulated annealing algorithm scaffolding.
#
# Feed it problems of the form:
#
# {
#  # Generate a random solution.
#  # Will be called in the initialization phase of the algorithm.
#  makeRandomSolution: () -> ...
#
#  # Find a "close" neighbour to the given solution.
#  findNeighbour: (solution) ->  ...
#
#  # Calculate the fitness of the given solution.
#  # For numerical functions this will be the function itself.
#  fitness: (solution) -> ...
# }
class SimulatedAnnealing

  constructor: ->
    @name = "SimulatedAnnealing"

  run: (problem, params, progress) ->

    deferred = Q.defer()

    params = _.merge({ steps: 100, temp: 1000, cdr: .999 }, params)

    temp = params.temp
    steps = params.steps

    # the probability function which determines whether to move to neighbour
    # even when it isnt a better solution
    P = (current, neighbour, temp) ->
      Math.random() < Math.exp((current.fitness-neighbour.fitness)/temp)

    # starting point is a random solution
    current = problem.makeRandomSolution()

    # remember temp and fitness on solutions
    current.temp = temp
    current.fitness = problem.fitness(current)
    champion = current

    # while there is still some heat left, iterate
    while temp > 1.5
      for step in [0..steps]

        # find neighbour (and remember its fitness
        # and at which temperature it was found
        neighbour = problem.findNeighbour(current)
        neighbour.temp = temp
        neighbour.fitness = problem.fitness(neighbour)

        # minimization problem
        if neighbour.fitness < current.fitness or P(current, neighbour, temp)
          current = neighbour

        # remember champion (optimization)
        if current.fitness < champion.fitness
          champion = current

        progress?({ temperature: temp, best: champion })

      # slowly cool down (cdr is cool-down ratio)
      temp *= params.cdr

    # return
    deferred.resolve(champion)
    deferred.promise



# Evolutionary algorithm scaffolding.
#
# Should be fed problems of the form 
# 
# TODO recombine, mutate, makeRandomSolution, fitness

class Evolution

  constructor: ->
    @name = "Evolution"

  evolutionize = (problem, params, population, generation, progress, bestFitness, reign = 0, deferred = Q.defer()) ->

    if generation <= 0 or reign > params.stopAfterUnimprovedGenerations
      deferred.resolve(population)
    else
      parents = []
      switch params.selection
        when "deterministic"
          # DETERMINISTIC SELECTION
          # Select top-tier solution as parents.
          parents = _.sortBy(population, "fitness").slice(0, params.parents)
          best = parents[0]
          progress?({ generation: params.generations - generation, best: best, reign: reign })
          # -or- no parents survive - choose top-tier from most recent generation (not implemented)
        when "stochastic"
          # STOCHASTIC SELECTION
          parents = if params.elites > 0 then _.sortBy(population, "fitness").slice(0, params.elites) else []

          # tournament #1 (n solutions are chosen in n tournaments - winner gets to be parent)
          # -or- tournament #2 (all solutions are eval'ed against a subset of pop - top-tier n chosen as parents)
          parentCandidates = _.without(population, parents)
          # TODO can be made async
          for solution in parentCandidates
            do (solution) ->
              for i in [0..params.tournamentSize-1]
                solution.score ?= 0
                if solution.fitness < population[Math.round(Math.random()*(population.length-1))].fitness
                  solution.score += 1

          # -- choose parents as those with highest score
          _.sortBy(parentCandidates, "score").slice(-(params.parents - parents.length)).forEach(
            (p) ->
              delete p.score
              parents.push(p)
          )
          best = _.sortBy(parents, "fitness")[0]
          progress?({ generation: params.generations - generation, best: best, reign: reign })


      # Create offspring. Recombine or mutate? Compute fitness.
      mate = (parents) ->
        parents = _.shuffle(parents)
        if Math.random() > params.recombinationProbability
          # Re-combine (problem may choose the number of parents used to produce offspring).
          child = problem.recombine.apply(this, parents)
        else
          # Mutate to generate offspring.
          child = problem.mutate(parents[0])

        child.generation = (params.generations - generation)
        child.fitness = problem.fitness(child)
        child

      # TODO this could be parallelized
      population = ([0..(params.populationSize-parents.length)].map(() -> parents)).map(mate)

      # Allow solutions chosen as parents to survive to next generation.
      population.push parent for parent in parents

      # Next generation.
      evolutionize(problem, params, population, --generation, progress, best.fitness, (if Math.abs(best.fitness - bestFitness) < params.improvementThreshold then reign+1 else 0), deferred)

    # Return
    deferred.promise



  run: (problem, params, progress) ->

    params = _.merge(
      {
        generations: 2000,
        populationSize: 200,
        selection: "deterministic",
        parents: 20,
        elites: 5,
        tournamentSize: 10,
        recombinationProbability: .5,
        stopAfterUnimprovedGenerations: 300
        improvementThreshold: 1e-6
      },
      params
    )

    # Generate initial population of random solutions. And add fitness to each solution.
    population = [0..params.populationSize-1].map (i) -> problem.makeRandomSolution()
    population.forEach (solution) -> solution.fitness = problem.fitness(solution)

    # Run evolution.
    deferred = Q.defer()
    evolutionize(problem, params, population, params.generations, progress)
    .then(
      (population) ->
        # Resolve w fittest solution in final population.
        deferred.resolve(_.sortBy(population, "fitness")[0])
    )

    # Return promise
    deferred.promise



class DifferentialEvolution

  constructor: ->
    @name = "DifferentialEvolution"

  findFittest: (population) ->
    population.reduce(((best, current) -> if current.fitness < best.fitness then current else best), { fitness: Number.MAX_VALUE })

  run: (problem, params, progress) ->

    deferred = Q.defer()

    params = _.merge(
      {
        generations: 300,
        populationSize: 100,
        
        # DE/rand/1/bin as default
        selectionStrategy: 'rand' # rand
        numberOfDifferenceIndividuals: 1
        recombinationStrategy: 'bin' # bin = binomial, exp = exponential (n/a)

        scalingFactor: .5 # should be [0,2]

        stopAfterUnimprovedGenerations: 20
        improvementThreshold: 1e-6
      },
      params
    )

    # Generate initial population of random solutions. And add fitness to each solution.
    population = [0..params.populationSize-1].map (i) -> problem.makeRandomSolution()
    population.forEach (solution) -> solution.fitness = problem.fitness(solution)

    # Run main loop
    unimprovedGenerations = 0
    generation = 0
    previousBest = Number.MAX_VALUE
    while unimprovedGenerations < params.stopAfterUnimprovedGenerations and generation < params.generations
      
      currentBest = @findFittest(population)
      if Math.abs(currentBest.fitness - previousBest.fitness) < params.improvementThreshold
        unimprovedGenerations++
      else
        unimprovedGenerations = 0
      previousBest = currentBest

      population = population.map =>

        # THIS IS INNER LOOP

        #
        # Perform mutation
        #
        
        # TODO individuals must be different

        # - Find individual from which to start selection process
        chosenIndividual = if params.selectionStrategy is 'rand'
          population[Math.round(Math.random()*(population.length-1))]
        
        # - Randomly find individuals to mutate with
        chosenDifferenceIndividuals = [0..params.numberOfDifferenceIndividuals*2-1].map -> population[Math.round(Math.random()*(population.length-1))]

        # xnew_i = xchosen_i + scaling * ( diff1_i - diff2_i ) - repeat scaling w params.numberOfDifferenceIndividuals * 2
        scaledMutation = (while (([diff1, diff2] = [chosenDifferenceIndividuals.shift(),chosenDifferenceIndividuals.shift()]).indexOf(undefined) < 0)
          problem.multiply(params.scalingFactor, problem.subtract(diff1, diff2))
        ).reduce (memo, scaled) -> problem.add(memo, scaled) 

        newIndividual = problem.add(chosenIndividual, scaledMutation) 


        #
        # - Perform crossover
        #
        newIndividual = problem.recombine(newIndividual, chosenIndividual, params)

        # Evaluate new individual
        newIndividual.fitness = problem.fitness(newIndividual)

        # Add extra properties to new individual
        newIndividual.generation = generation

        
        #console.log currentBest, newIndividual
        #console.log newIndividual.fitness, chosenIndividual.fitness 
        
        # Perform selection operation
        if newIndividual.fitness < chosenIndividual.fitness 
          newIndividual
        else
          # TODO this is bad as more and more of this guy will be in pop
          chosenIndividual

      # Next generation
      generation++

    

    champion = @findFittest(population)
    champion.totalGenerations = generation

    deferred.resolve champion

    deferred.promise

# Exports.
exports.SimulatedAnnealing = SimulatedAnnealing
exports.Evolution = Evolution
exports.DifferentialEvolution = DifferentialEvolution
