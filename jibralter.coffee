_ = require("underscore")

class Env
  constructor: (params, args, outer = null) ->
    @variables = {}
    @outer = outer

    if params and args
      @update(_.zip(params, args))

  find: (variable) ->
    if _.has(@variables, variable) then this else outer.find(variable)

  update: (params) -> _.extend(@variables, params)

  set: (variable, value) ->
    @variables[variable] = value

addGlobals = (env) ->
  operators =
    '+': (x, y) -> x + y
    '-': (x, y) -> x - y
    '*': (x, y) -> x * y
    '/': (x, y) -> x / y
    '>': (x, y) -> x > y
    '<': (x, y) -> x < y
    '=': (x, y) -> x == y
    '>=': (x, y) -> x >= y
    '<=': (x, y) -> x <= y
  env.update _.extend(operators, { 'True': true, 'False': false })

createGlobalEnv = ->
  env = new Env
  addGlobals(env)
  env

globalEnv = createGlobalEnv()

evaluate = (x, env = globalEnv) ->
  [head, tail] = x

  if _.isString(head)
    env.find(head)[head]
  else if not _.isArray(head)
    head
  else
    switch head
      when 'quote', 'q'
        tail
      when 'atom?'
        not _.isArray(evaluate(tail, env))
      when 'eq?'
        [exp1, exp2] = tail
        val1 = evaluate(exp1, env)
        val2 = evaluate(exp2, env)
        (not _.isArray(val1)) and (val1 == val2)
      when 'car'
        _.first evaluate(tail, env)
      when 'cdr'
        _.rest evaluate(tail, env)
      when 'cons'
        _.map(tail, evaluate)
      when 'cond'
        _.each tail, (predicate, exp) ->
          if evaluate(predicate, env) then evaluate(exp, env)
      when 'null?'
        _.isEmpty(evaluate(tail, env))
      when 'if'
        [test, conseq, alt] = tail
        if evaluate(test, env)
          evaluate(conseq, env)
        else
          evaluate(alt, env)
      when 'set!'
        [variable, exp] = tail
        env.find(variable).set variable, eval(exp, env)
      when 'define'
        [variable, exp] = tail
        env.set variable, evaluate(exp)
      when 'lambda'
        [variables, exp] = tail
        (args) -> evaluate(exp, (new Env(variables, args, env)))
      when 'begin'
        for exp in tail
          val = evaluate(exp, env)
        val
      else
        [exp, args...] = evaluate(exp, env) for exp in x
        exp(args)


parse = (string) -> readFrom(tokenize(string))

tokenize = (string) ->
  _.compact string.replace(/\(/gm, " ( ").replace(/\)/gm, " ) ").split(" ")

readFrom = (tokens) ->
  throw "Syntax Error: unexpected EOF while reading" if _.isEmpty(tokens)
  [token, tokens...] = tokens
  if '(' == token
    list = []
    while _.first(tokens) != ')'
      list.push(readFrom(tokens))
      tokens = _.rest(tokens)
    list
  else if ')' == token
    throw "Syntax Error: unexpected ')'"
  else atom(token)

atom = (token) ->
  if _.isFinite(+token)
    +token
  else
    token.toString()

toString = (exp) ->
  unless _.isArray(exp)
    exp.toString()
  else
    '(' + _.join(_.map(exp, toString), ' ') + ')'

runningParenSums = (program) ->
  countOpenParens = (line) ->
    line.match(/\(/g).length - line.match(/\)/).length
  parenCounts = _.map(program, countOpenParens)
  rps = []
  total = 0
  for parenCount in parensCount
    total += parenCount
    rps.push(total) && rps

repl = (prompt = 'jibralter > ') ->
  readline = require("readline")
  rl = readline.createInterface(process.stdin, process.stdout)
  try
    rl.on 'line', (line) ->
      val = evaluate(parse(line))
      console.log(val) unless _.isEmpty(val)
      rl.prompt()

    rl.on 'close', ->
      console.log("\n Exiting")
      process.exit(0)

    rl.setPrompt(prompt, prompt.length)
    rl.prompt()
  catch err
    console.log "An error occurred: #{err}"

repl()
