_ = require("underscore")

jibralter = {}

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

jibralter.addGlobals = (env) ->
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

jibralter.globalEnv = do ->
  env = new Env
  jibralter.addGlobals(env)
  env

jibralter.evaluate = (x, env = jibralter.globalEnv) =>
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
        not _.isArray(jibralter.evaluate(tail, env))
      when 'eq?'
        [exp1, exp2] = tail
        val1 = jibralter.evaluate(exp1, env)
        val2 = jibralter.evaluate(exp2, env)
        (not _.isArray(val1)) and (val1 == val2)
      when 'car'
        _.first jibralter.evaluate(tail, env)
      when 'cdr'
        _.rest jibralter.evaluate(tail, env)
      when 'cons'
        _.map(tail, jibralter.evaluate)
      when 'cond'
        _.each tail, (predicate, exp) ->
          if jibralter.evaluate(predicate, env) then jibralter.evaluate(exp, env)
      when 'null?'
        _.isEmpty(jibralter.evaluate(tail, env))
      when 'if'
        [test, conseq, alt] = tail
        if jibralter.evaluate(test, env)
          jibralter.evaluate(conseq, env)
        else
          jibralter.evaluate(alt, env)
      when 'set!'
        [variable, exp] = tail
        env.find(variable).set variable, jibralter.evaluate(exp, env)
      when 'define'
        [variable, exp] = tail
        env.set variable, jibralter.evaluate(exp)
      when 'lambda'
        [variables, exp] = tail
        (args) -> jibralter.evaluate(exp, (new Env(variables, args, env)))
      when 'begin'
        for exp in tail
          val = jibralter.evaluate(exp, env)
        val
      else
        [exp, args...] = jibralter.evaluate(exp, env) for exp in x
        exp(args)

jibralter.parse = (string) => jibralter.readFrom(jibralter.tokenize(string))

jibralter.tokenize = (string) ->
  _.compact string.replace(/\(/gm, " ( ").replace(/\)/gm, " ) ").split(" ")

jibralter.readFrom = (tokens) =>
  throw "Syntax Error: unexpected EOF while reading" if _.isEmpty(tokens)
  [token, tokens...] = tokens
  if '(' == token
    list = []
    while _.first(tokens) != ')'
      console.log(list)
      list.push(jibralter.readFrom(tokens))
      tokens = _.rest(tokens)
    return list
  else if ')' == token
    throw "Syntax Error: unexpected ')'"
  else jibralter.atom(token)

jibralter.atom = (token) =>
  if _.isFinite(+token)
    +token
  else
    jibralter.toString(token)

jibralter.toString = (exp) =>
  unless _.isArray(exp)
    exp.toString()
  else
    "(#{ _.join(_.map(exp, jibralter.toString), ' ') })"

jibralter.repl = (prompt = 'jibralter > ') =>
  readline = require("readline")
  rl = readline.createInterface(process.stdin, process.stdout)
  try
    rl.on 'line', (line) ->
      val = jibralter.evaluate(jibralter.parse(line))
      console.log(jibralter.parse(line))
      console.log(val) unless _.isEmpty(val)
      rl.prompt()

    rl.on 'close', ->
      console.log("\n Exiting")
      process.exit(0)

    rl.setPrompt(prompt, prompt.length)
    rl.prompt()
  catch err
    console.log "An error occurred: #{err}"

exports.jibralter = jibralter
