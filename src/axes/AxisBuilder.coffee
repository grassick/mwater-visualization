_ = require 'lodash'
ExprCompiler = require('mwater-expressions').ExprCompiler
ExprUtils = require('mwater-expressions').ExprUtils
ExprCleaner = require('mwater-expressions').ExprCleaner
d3Format = require 'd3-format'
moment = require 'moment'
React = require 'react'
H = React.DOM

xforms = [
  { type: "bin", input: "number", output: "enum" }
  { type: "date", input: "datetime", output: "date" }
  { type: "year", input: "date", output: "date" }
  { type: "year", input: "datetime", output: "date" }
  { type: "yearmonth", input: "date", output: "date" }
  { type: "yearmonth", input: "datetime", output: "date" }
  { type: "month", input: "date", output: "enum" }
  { type: "month", input: "datetime", output: "enum" }
]

# Understands axes. Contains methods to clean/validate etc. an axis of any type. 
module.exports = class AxisBuilder
  # Options are: schema
  constructor: (options) ->
    @schema = options.schema
    @exprUtils = new ExprUtils(@schema)
    @exprCleaner = new ExprCleaner(@schema)

  # Clean an axis with respect to a specific table
  # Options:
  #  axis: axis to clean
  #  table: table that axis is to be for
  #  aggrNeed is "none", "optional" or "required"
  #  types: optional list of types to require it to be one of
  cleanAxis: (options) ->
    if not options.axis
      return

    # TODO always clones
    axis = _.clone(options.axis)

    # Clean expression
    axis.expr = @exprCleaner.cleanExpr(axis.expr, { table: options.table })

    # Remove if null or no type 
    type = @exprUtils.getExprType(axis.expr)
    if not type
      return

    # Validate xform type
    if axis.xform
      # Find valid xform
      xform = _.find(xforms, (xf) ->
        # xform type must match
        if xf.type != axis.xform.type
          return false

        # Input type must match
        if xf.input != type
          return false

        # Output type must match
        if options.types and xf.output not in options.types
          return false
        return true
        )
      if not xform
        delete axis.xform

    # If no xform and using an xform would allow satisfying output types, pick first
    if not axis.xform and options.types and type not in options.types
      xform = _.find(xforms, (xf) -> xf.input == type and xf.output in options.types)
      if xform
        axis.xform = { type: xform.type }
        type = xform.output
      else
        # Unredeemable if no xform possible and cannot use count to get number
        if options.aggrNeed == "none" 
          return null
        if "number" not in options.types
          return null

    # Always 
    # Add number of bins
    if axis.xform and axis.xform.type == "bin" and not axis.xform.numBins
      axis.xform.numBins = 6

    # Only allow aggr if not xform
    if axis.xform
      delete axis.aggr
    else
      # Clean aggr
      aggrs = @exprUtils.getAggrs(axis.expr)
      # Remove latest, as it is tricky to group by. TODO
      aggrs = _.filter(aggrs, (aggr) -> aggr.id != "last")

      # Remove existing if not in list
      if axis.aggr and axis.aggr not in _.pluck(aggrs, "id")
        delete axis.aggr

      # Remove if need is none
      if options.aggrNeed == "none"
        delete axis.aggr

      # Default aggr if required
      if options.aggrNeed == "required" and aggrs[0] and not axis.aggr
        axis.aggr = aggrs[0].id

      # Set aggr to count if expr is type id and aggr possible
      if options.aggrNeed != "none" and not axis.aggrs
        if @exprUtils.getExprType(axis.expr) == "id"
          axis.aggr = "count"

      # Set aggr to count if needed to satisfy types
      if options.types and "number" in options.types and type not in options.types
        axis.aggr = "count"

    return axis

  # Checks whether an axis is valid
  #  axis: axis to validate
  validateAxis: (options) ->
    # Nothing is ok
    if not options.axis
      return

    # xform validation
    if options.axis.xform and options.axis.xform.type == "bin"
      if not options.axis.xform.numBins
        return "Missing numBins"

      if not options.axis.xform.min?
        return "Missing min"

      if not options.axis.xform.max?
        return "Missing max"

    return

  # Pass axis, tableAlias
  compileAxis: (options) ->
    if not options.axis
      return null

    exprCompiler = new ExprCompiler(@schema)
    compiledExpr = exprCompiler.compileExpr(expr: options.axis.expr, tableAlias: options.tableAlias, aggr: options.axis.aggr)

    # Bin
    if options.axis.xform 
      if options.axis.xform.type == "bin"
        compiledExpr = {
          type: "op"
          op: "width_bucket"
          exprs: [
            compiledExpr
            options.axis.xform.min
            options.axis.xform.max
            options.axis.xform.numBins
          ]
        }

      if options.axis.xform.type == "date"
        compiledExpr = {
          type: "op"
          op: "substr"
          exprs: [
            compiledExpr
            1
            10
          ]
        }

      if options.axis.xform.type == "year"
        compiledExpr = {
          type: "op"
          op: "rpad"
          exprs: [
            { type: "op", op: "substr", exprs: [compiledExpr, 1, 4] }
            10
            "-01-01"
          ]
        }

      if options.axis.xform.type == "yearmonth"
        compiledExpr = {
          type: "op"
          op: "rpad"
          exprs: [
            { type: "op", op: "substr", exprs: [compiledExpr, 1, 7] }
            10
            "-01"
          ]
        }

      if options.axis.xform.type == "month"
        compiledExpr = {
          type: "op"
          op: "substr"
          exprs: [
            compiledExpr
            6
            2
          ]
        }

    # Aggregate
    if options.axis.aggr
      compiledExpr = {
        type: "op"
        op: options.axis.aggr
        exprs: _.compact([compiledExpr])
      }

    return compiledExpr

  # Get underlying expression types that will give specified output expression types
  #  types: array of types
  #  aggrNeed is "none", "optional" or "required"
  getExprTypes: (types, aggrNeed) ->
    if not types
      return null
      
    # Allow any if count is an option
    if aggrNeed != "none" and "number" in types
      return ["text", "number", "date", "datetime", "boolean", "enum"]

    types = types.slice()

    # Add xformed types
    for xform in xforms
      if xform.output in types
        types = _.union(types, [xform.input])

    return types

  # Get all categories for a given axis type given the known values
  # Returns array of { value, label }
  getCategories: (axis, values, locale) ->
    # Handle binning first
    if axis.xform and axis.xform.type == "bin"
      min = axis.xform.min
      max = axis.xform.max
      numBins = axis.xform.numBins

      # Calculate precision
      precision = d3Format.precisionFixed((max - min) / numBins)
      format = d3Format.format(",." + precision + "f")

      categories = []
      categories.push({ value: 0, label: "< #{format(min)}"})
      for i in [1..numBins]
        start = (i-1) / numBins * (max - min) + min
        end = (i) / numBins * (max - min) + min
        categories.push({ value: i, label: "#{format(start)} - #{format(end)}"})
      categories.push({ value: axis.xform.numBins + 1, label: "> #{format(max)}"})

      return categories

    if axis.xform and axis.xform.type == "month"
      return [
        { value: "01", label: "January" }
        { value: "02", label: "February" }
        { value: "03", label: "March" }
        { value: "04", label: "April" }
        { value: "05", label: "May" }
        { value: "06", label: "June" }
        { value: "07", label: "July" }
        { value: "08", label: "August" }
        { value: "09", label: "September" }
        { value: "10", label: "October" }
        { value: "11", label: "November" }
        { value: "12", label: "December" }
      ]

    if axis.xform and axis.xform.type == "year"
      values = _.compact(values)
      if values.length == 0 
        return []

      # Get min and max
      min = _.min(_.map(values, (date) -> parseInt(date.substr(0, 4))))
      max = _.max(_.map(values, (date) -> parseInt(date.substr(0, 4))))
      categories = []
      for year in [min..max]
        categories.push({ value: "#{year}-01-01", label: "#{year}"})
      return categories

    if axis.xform and axis.xform.type == "yearmonth"
      values = _.compact(values)
      if values.length == 0 
        return []

      # Get min and max
      min = values.sort()[0]
      max = values.sort().slice(-1)[0]

      # Use moment to get range
      current = moment(min, "YYYY-MM-DD")
      end = moment(max, "YYYY-MM-DD")
      categories = []
      while not current.isAfter(end)
        categories.push({ value: current.format("YYYY-MM-DD"), label: current.format("MMM YYYY")})
        current.add(1, "months")
      return categories

    switch @getAxisType(axis)
      when "enum", "enumset"
        # If enum, return enum values
        return _.map(@exprUtils.getExprEnumValues(axis.expr), (ev) -> { value: ev.id, label: ExprUtils.localizeString(ev.name, locale) })
      # Removed since integer is no longer a fundamental type. TODO REMOVE
      # when "integer"
      #   values = _.compact(values)
      #   if values.length == 0 
      #     return []

      #   # Integers are sometimes strings from database, so always parseInt (bigint in node-postgres)
      #   min = _.min(_.map(values, (v) -> parseInt(v)))
      #   max = _.max(_.map(values, (v) -> parseInt(v)))

      #   return _.map(_.range(min, max + 1), (v) -> { value: v, label: "#{v}"})
      when "text"
        # Return unique values
        return _.map(_.uniq(values), (v) -> { value: v, label: v or "None" })
      when "date"
        values = _.compact(values)
        if values.length == 0 
          return []

        # Get min and max
        min = values.sort()[0]
        max = values.sort().slice(-1)[0]

        # Use moment to get range
        current = moment(min, "YYYY-MM-DD")
        end = moment(max, "YYYY-MM-DD")
        categories = []
        while not current.isAfter(end)
          categories.push({ value: current.format("YYYY-MM-DD"), label: current.format("ll")})
          current.add(1, "days")
        return categories

    return []

  # Get type of axis output
  getAxisType: (axis) ->
    if not axis
      return null

    if axis.aggr == "count"
      return "number"

    type = @exprUtils.getExprType(axis.expr)

    if axis.xform 
      xform = _.findWhere(xforms, { type: axis.xform.type, input: type })
      return xform.output

    return type

  # Summarize axis as a string
  summarizeAxis: (axis, locale) ->
    if not axis
      return "None"

    exprType = @exprUtils.getExprType(axis.expr)

    # Add aggr if not a count type
    if axis.aggr and exprType != "id"
      aggrName = _.findWhere(@exprUtils.getAggrs(axis.expr), { id: axis.aggr }).name
      return aggrName + " " + @exprUtils.summarizeExpr(axis.expr, locale)
    else
      return @exprUtils.summarizeExpr(axis.expr, locale)
    # TODO add xform support

  # Get a string (or React DOM actually) representation of an axis value
  formatValue: (axis, value, locale) ->
    if not value?
      return "None"

    type = @getAxisType(axis)

    # If has categories, use those
    categories = @getCategories(axis, [], locale)
    if categories.length > 0
      if type == "enumset"
        return _.map(value, (v) ->
          category = _.findWhere(categories, value: v)
          if category
            return category.label
          else
            return "???"
        ).join(", ")
      else
        category = _.findWhere(categories, value: value)
        if category
          return category.label
        else
          return "???"

    switch type
      when "text"
        return value
      when "number"
        num = parseFloat(value)
        return d3Format.format(",")(num)
      when "text[]"
        return H.div(null, _.map(value, (v, i) -> H.div(key: i, v)))

    # TODO format dates
    return "" + value

  # Creates a filter (jsonql with {alias} for table name) based on a specific value
  # of the axis. Used to filter by a specific point.
  createValueFilter: (axis, value) ->
    if value?
      return {
        type: "op"
        op: "="
        exprs: [
          @compileAxis(axis: axis, tableAlias: "{alias}")
          { type: "literal", value: value }
        ]
      }
    else
      return {
        type: "op"
        op: "is null"
        exprs: [
          @compileAxis(axis: axis, tableAlias: "{alias}")
        ]
      }
