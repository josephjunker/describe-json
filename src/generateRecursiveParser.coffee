{isString, getOnlyKeyForObject, beginsWithUpperCase} = require './utilities'
{selectParametersForField} = require './parameterUtilities'

nativeTypes = Object.keys require './nativeTypeRecognizers'

isNativeType = (typeName) -> nativeTypes.indexOf(typeName) isnt -1

#TODO: unit test this, probably move it to a utility
getTypeNameForField = (fieldData, parameters) ->
  if isString(fieldData) and beginsWithUpperCase fieldData
    return fieldData
  if isString(fieldData) and not beginsWithUpperCase fieldData
    #TODO: I'm not sure of the schema of bound parameters, this might not work
    return parameters[fieldData]

  name = getOnlyKeyForObject fieldData
  if beginsWithUpperCase name
    return name
  else
    return parameters[name]

getNameAndTypeFromFieldObject = (x) ->
  fieldName = getOnlyKeyForObject x
  fieldType = x[fieldName]
  [fieldName, fieldType]

parseNested = (fieldTypeName, dataToParse, typeParameters, typeRegistry, typeclassMembers) ->
  parser = typeRegistry.getParserByTypeName fieldTypeName
  if parser is null
    if typeRegistry.nameCorrespondsToTypeclass fieldTypeName
      membersOfThisTypeclass = typeclassMembers[fieldTypeName]
      parser = makeTypeclassParser membersOfThisTypeclass, typeRegistry
    else
      parser = parseFields typeRegistry.getTypeDeclarationForName(fieldTypeName), typeRegistry
  parser dataToParse, typeParameters

packIR = (packedObj, fieldName, ir) ->
  packedObj.data[fieldName] = ir.data
  packedObj.typedata.fields[fieldName] = ir.typedata

recordUseOfUnresolvedType = (typeName) ->
  throw 'Attempted to parse an unresolved type'

# This is probably poorly named. It takes an array of all the already existing parameters, and the declaration of
# the type that we're making a parser for, and it returns a parser for that field.
# Parsers take data, and any currently applied type parameters as arguments, and return an IR of the parsed data
# This IR is not strictly necessary at the moment, but will be important for things like nested pattern matching, or
# external libraries that interface with this one.
parseFields = (typeDeclaration, typeRegistry, typeclassMembers) ->
  (dataToParse, typeParameters) ->

    # This is the schema used by the IR. Data and fields are recursive
    # TODO: Data contains the exact input we were given on a match. It should contain only
    # the matched fields (untyped extra fields should be stripped out)
    #
    # Actually, we should probably take an argument specifying whether we should extract or reject extra fields
    result =
      matched: true
      data: {}
      typedata:
        typeparameters: if typeParameters? then typeParameters else {}
        iscontainer: true
        type: typeDeclaration.name
        fields: {}

    for fieldName, fieldData of typeDeclaration.fields
      fieldExists = dataToParse[fieldName]?
      return matched: false unless fieldExists

      [err, thisFieldsParams] = selectParametersForField fieldData, typeParameters

      fieldTypeName = getTypeNameForField fieldData, typeParameters

      return recordUseOfUnresolvedType fieldTypeName unless fieldTypeName

      if isNativeType fieldTypeName
        parser = typeRegistry.getParserByTypeName fieldTypeName
        ir = parser dataToParse[fieldName]
      else
        ir = parseNested fieldTypeName, dataToParse[fieldName], thisFieldsParams, typeRegistry, typeclassMembers

      return matched: false unless ir.matched
      packIR result, fieldName, ir

    return result

makeTypeclassParser = (membersOfThisTypeclass, typeRegistry) ->
  (dataToParse, typeParameters) ->
    for typeName in membersOfThisTypeclass
      parser = typeRegistry.getParserByTypeName typeName
      if parser is null
        parser = makeTypeclassParser typeRegistry.getTypeDeclarationForName(typeName), typeRegistry
      ir = parser dataToParse, typeParameters
      return ir if ir.matched
    return matched: false

generateParser = (declarationType, newType, typeclassMembers, typeRegistry) ->
  if declarationType is 'type'
    if newType.fields?
      fieldsParser = parseFields newType, typeRegistry, typeclassMembers
      return fieldsParser

  if declarationType is 'typeclass'
    return makeTypeclassParser typeclassMembers[newType.name], typeRegistry

module.exports = generateParser
