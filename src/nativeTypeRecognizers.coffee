check = Object.prototype.toString

wrapNonContainer = (value, type) ->
  matched: true
  data: value
  typedata:
    type: type
    iscontainer: false

module.exports =
  Int: (x) ->
    res = matched: x == +x && x == (x|0)
    if res.matched then wrapNonContainer(x, 'Int') else res

  Float: (x) ->
    res = matched: x == +x && x != (x|0)
    if res.matched then wrapNonContainer(x, 'Float') else res

  Number: (x) ->
    res = matched: check.call(x) is '[object Number]' and not isNaN x
    if res.matched then wrapNonContainer(x, 'Number') else res

  String:
    (x) ->
      res = matched: check.call(x) is '[object String]'
      if res.matched then wrapNonContainer(x, 'String') else res

  NaN: (x) ->
    res = matched: check.call(x) is '[object Number]' and isNaN x
    if res.matched then wrapNonContainer(x, 'NaN') else res

  Null: (x) ->
    res = matched: x is null
    if res.matched then wrapNonContainer(x, 'Null') else res

  Undefined: (x) ->
    res = matched: x is undefined
    if res.matched then wrapNonContainer(x, 'Undefined') else res

  Array: (x) -> check.call(x) is '[object Array]'
  Object: (x) -> check.call(x) is '[object Object]'
