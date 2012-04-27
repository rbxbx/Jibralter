Env = require('../jibralter').env

describe "Environment", ->
  env = new Env
  variables = { foo: 1, bar: 2 }

  describe "#update", ->

    it "puts variables into the store", ->
      env.update(variables)
      expect(env.variables).toEqual(variables)

    it "updates existing variables with new values", ->
      newValues = { foo: 3, bar: 4 }
      env.update(variables)
      env.update(newValues)

      expect(env.variables).toEqual(newValues)

  describe "#set", ->
    it "sets a single variable in the store", ->
      env.set("foo", 4)
      expect(env.variables.foo).toEqual(4)

  describe "#find", ->
    env.set("foo", 4)

    it "returns the environment containing a variable", ->
      expect(env.find("foo")).toEqual(env)

    it "looks up parent scopes until the variable is found", ->
      childEnv = new Env({}, {}, env)
      expect(childEnv.find("foo")).toEqual(env)

    it "shadows variables", ->
      childEnv = new Env(["foo", "bar", "baz"], [6, 7, 8], env)

      expect(childEnv.find("foo").variables.foo).toEqual(6)
      expect(childEnv.find("bar").variables.bar).toEqual(7)
      expect(childEnv.find("baz").variables.baz).toEqual(8)
