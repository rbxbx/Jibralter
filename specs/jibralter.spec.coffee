Jibralter = require('../jibralter').jibralter
Env = require('../jibralter').env

describe "Jibralter", ->

  it 'tokenizes', ->
    tokens = Jibralter.tokenize("(+ 1 2)")
    expect(tokens).toEqual([ '(', '+', '1', '2', ')' ])

  it 'parses', ->
    ast = Jibralter.parse("(+ 1 2)")
    expect(ast).toEqual([ '+', 1, 2])

    ast = Jibralter.parse('1')
    expect(ast).toEqual(1)

  it 'parses nested expressions', ->
    ast = Jibralter.parse("(1 (2 3))")
    expect(ast).toEqual([1, [2, 3]])

    ast = Jibralter.parse("((1 2))")
    expect(ast).toEqual([[1, 2]])

    ast = Jibralter.parse("(1 (2 3) 4)")
    expect(ast).toEqual([ 1, [ 2, 3 ], 4 ])

    ast = Jibralter.parse("(+ 1 (+ 2 3))")
    expect(ast).toEqual([ '+', 1, [ '+', 2, 3 ] ])

    ast = Jibralter.parse("((1 2) 3)")
    expect(ast).toEqual([ [ 1, 2], 3 ])

    ast = Jibralter.parse("(()()())")
    expect(ast).toEqual([ [], [], [], ])

  describe "#evaluate", ->
    evaluate = Jibralter.evaluate

    it "variables", ->
      ast = [ "foo" ]
      env = new Env
      env.set("foo", 1)

      evaluation = evaluate(ast, env)
      expect(evaluation).toEqual(1)

    it "constant literal", ->
      ast = [ 1 ]

      evaluation = evaluate(ast)
      expect(evaluation).toEqual(1)

    it "quotes", ->
      ast = [ "quote", [1]]
      evaluation = Jibralter.evaluate(ast)
      expect(evaluation).toEqual([1])




