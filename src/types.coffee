console = {log: ->}
pj = try require 'prettyjson'
render = (obj) -> pj?.render obj
CS = require './nodes'

# Exec down casting
# pass obj :: {x :: Number, name :: String} = {x : 3, y : "hello"}
# ng   obj :: {x :: Number, name :: String} = {x : 3, y : 5 }
checkAcceptableObject = (left, right) ->
  console.log 'check', left, right
  # "Number" <> "Number"
  if ((typeof left) is 'string') and ((typeof right) is 'string')
    if (left is right) or (left is 'Any') or (right is 'Any')
      'ok'
    else
      throw (new Error "object deep equal mismatch #{left}, #{right}")

  # {array: "Number"} <> {array: "Number"}
  else if left?.array?
    # TODO: fix it
    console.log 'left', left, 'right', right

  # {x: "Nubmer", y: "Number"} <> {x: "Nubmer", y: "Number"}
  else if ((typeof left) is 'object') and ((typeof right) is 'object')
    for key, lval of left
      # when {x: Number} = {z: Number}
      if right[key] is undefined
        return if key in ['returns', 'type'] # TODO ArrayTypeをこっちで吸収してないから色々きちゃう
        throw new Error "'#{key}' is not defined on right"
      checkAcceptableObject(lval, right[key])
  else if (left is undefined) or (right is undefined)
    # TODO: valid code later
    "ignore now"
  else
    throw (new Error "object deep equal mismatch #{left}, #{right}")

# Initialize primitive types
# Number, Boolean, Object, Array, Any
initializeGlobalTypes = (node) ->
  # Primitive
  node.addTypeObject 'String', new TypeSymbol {
    type: 'String'
    instanceof: (expr) -> (typeof expr.data) is 'string'
  }

  node.addTypeObject 'Number', new TypeSymbol {
    type: 'Number'
    instanceof: (expr) -> (typeof expr.data) is 'number'
  }

  node.addTypeObject 'Boolean', new TypeSymbol {
    type: 'Boolean'
    instanceof: (expr) -> (typeof expr.data) is 'boolean'
  }

  node.addTypeObject 'Object', new TypeSymbol {
    type: 'Object'
    instanceof: (expr) -> (typeof expr.data) is 'object'
  }

  node.addTypeObject 'Array', new TypeSymbol {
    type: 'Array'
    instanceof: (expr) -> (typeof expr.data) is 'object'
  }

  # Any
  node.addTypeObject 'Any', new TypeSymbol {
    type: 'Any'
    instanceof: (expr) -> true
  }

# Known vars in scope
class VarSymbol
  # type :: String
  # implicit :: Bolean
  constructor: ({@type, @implicit}) ->

# Known types in scope
class TypeSymbol
  # type :: String or Object
  # instanceof :: (Any) -> Boolean
  constructor: ({@type, @instanceof}) ->
    @instanceof ?= (t) -> t instanceof @constructor

# Var and type scope as node
class Scope
  # constructor :: (Scope) -> Scope

  # Get registered type in my scope
  # addType  :: (String, String) -> ()

  # Get registered type included in parents
  # addTypeInScope  :: (String, String) -> ()

  # for debug
  @dump: (node, prefix = '') ->
    console.log prefix + "[#{node.name}]"
    for key, val of node._vars
      console.log prefix, ' +', key, '::', val
    for next in node.nodes
      Scope.dump next, prefix + '  '

  constructor: (@parent = null) ->
    @parent?.nodes.push this

    @name = ''
    @nodes  = [] #=> scopeeNode...

    # スコープ変数
    @_vars  = {} #=> symbol -> type

    # 登録されている型
    @_types = {} #=> typeName -> type

    # TODO: This Scope
    @_this  = null #=> null or {}

    # このブロックがReturn する可能性があるもの
    @_returnables = [] #=> [ReturnableType...]

  addReturnable: (symbol, type) ->
    @_returnables.push type

  getReturnables: -> @_returnables

  addType: (symbol, type) ->
    @_types[symbol] = new TypeSymbol {type}

  addTypeObject: (symbol, type_object) ->
    @_types[symbol] = type_object

  getType: (symbol) ->
    @_types[symbol]?.type ? undefined

  getTypeInScope: (symbol) ->
    @getType(symbol) or @parent?.getTypeInScope(symbol) or undefined

  addVar: (symbol, type, implicit = true) ->
    @_vars[symbol] = new VarSymbol {type, implicit}

  getVar: (symbol) ->
    @_vars[symbol]?.type ? undefined

  getVarInScope: (symbol) ->
    @getVar(symbol) or @parent?.getVarInScope(symbol) or undefined

  isImplicitVar: (symbol) -> !! @_vars[symbol]?.implicit

  isImplicitVarInScope: (symbol) ->
    @isImplicitVar(symbol) or @parent?.isImplicitVarInScope(symbol) or undefined

  # Extend symbol to type object
  # ex. {name : String, p : Point} => {name : String, p : { x: Number, y: Number}}
  extendTypeLiteral: (node) ->
    switch (typeof node)
      when 'object'
        # array
        if node instanceof Array
          return (@extendTypeLiteral(i) for i in node)
        # object
        else
          ret = {}
          for key, val of node
            ret[key] = @extendTypeLiteral(val)
          return ret
      when 'string'
        type = @getTypeInScope(node)
        switch typeof type
          when 'object'
            return @extendTypeLiteral(type)
          when 'string'
            return type
            
  # check object literal with extended object
  checkAcceptableObject: (left, right) ->
    l = @extendTypeLiteral(left)
    r = @extendTypeLiteral(right)
    checkAcceptableObject(l, r)

  # Check arguments
  checkFunctionLiteral: (left, right) ->
    # flat extend
    left  = @extendTypeLiteral left
    right = @extendTypeLiteral right
    # check args
    for l_arg, i in left.args
      r_arg = right.args[i]
      checkAcceptableObject(l_arg, r_arg)

    # check return type
    # TODO: Now I will not infer function return type
    if right.returns isnt 'Any'
      checkAcceptableObject(left.returns, right.returns)

  # Check arrays
  # TODO: no use yet
  checkArrayLiteral: (left, right) ->
    left  = @extendTypeLiteral left
    right = @extendTypeLiteral right

    # check args
    for l_arg, i in left.args
      r_arg = right.args[i]
      checkAcceptableObject(l_arg, r_arg)

    # return type
    checkAcceptableObject(left.returns, right.returns)




module.exports = {checkAcceptableObject, initializeGlobalTypes, VarSymbol, TypeSymbol, Scope}