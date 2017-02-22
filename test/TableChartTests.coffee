_ = require 'lodash'
assert = require('chai').assert
fixtures = require './fixtures'
TableChart = require '../src/widgets/charts/TableChart'
canonical = require 'canonical-json'

compare = (actual, expected) ->
  assert.equal canonical(actual), canonical(expected), "\ngot:#{canonical(actual)}\nexp:#{canonical(expected)}\n"

describe "TableChart", ->
  before ->
    @schema = fixtures.simpleSchema()
    @dataSource = {
      performQuery: (query) =>
        @query = query
    }

    @chart = new TableChart()

    @exprNumber = { type: "field", table: "t1", column: "number" }
    @exprText = { type: "field", table: "t1", column: "text" }
    @exprDate = { type: "field", table: "t1", column: "date" }
    @exprEnum = { type: "field", table: "t1", column: "enum" }
    @exprEnumset = { type: "field", table: "t1", column: "enumset" }

    @axisNumber = { expr: @exprNumber }
    @axisNumberSum = { expr: { type: "op", op: "sum", table: "t1", exprs: [@exprNumber] } }
    @axisEnum = { expr: @exprEnum } 
    @axisEnumset = { expr: @exprEnumset } 
    @axisText = { expr: @exprText } 
    @axisDate = { expr: @exprDate } 

  describe "createQueries", ->
    # it "includes _id if no grouping", ->

    it "does group all if no aggr", ->
      design = {
        table: "t1"
        columns: [
          { textAxis: @axisText }
          { textAxis: @axisNumber }
        ]
        orderings: []
      }

      @chart.getData(design, @schema, @dataSource, [])
      expectedQuery = {
        type: "query"
        selects: [
          { type: "select", expr: { type: "field", tableAlias: "main", column: "text" }, alias: "c0" }
          { type: "select", expr: { type: "field", tableAlias: "main", column: "number" }, alias: "c1" }
          { type: "select", expr: { type: "op", op: "min", exprs: [{ type: "field", tableAlias: "main", column: "primary" }] }, alias: "id" }
          { type: "select", expr: { type: "op", op: "count", exprs: [] }, alias: "num_ids" }
        ]
        from: { type: "table", table: "t1", alias: "main" }
        groupBy: [1, 2]
        orderBy: []
        limit: 1000
      }

      compare(@query, expectedQuery)

    it "groups all non-aggr", ->
      design = {
        table: "t1"
        columns: [
          { textAxis: @axisText }
          { textAxis: @axisNumberSum }
        ]
        orderings: []
      }

      @chart.getData(design, @schema, @dataSource, [])
      expectedQuery = {
        type: "query"
        selects: [
          { type: "select", expr: { type: "field", tableAlias: "main", column: "text" }, alias: "c0" }
          { type: "select", expr: { type: "op", op: "sum", exprs: [{ type: "field", tableAlias: "main", column: "number" }] }, alias: "c1" }
          { type: "select", expr: { type: "op", op: "min", exprs: [{ type: "field", tableAlias: "main", column: "primary" }] }, alias: "id" }
          { type: "select", expr: { type: "op", op: "count", exprs: [] }, alias: "num_ids" }
        ]
        from: { type: "table", table: "t1", alias: "main" }
        groupBy: [1]
        orderBy: []
        limit: 1000
      }

      compare(@query, expectedQuery)

    it "adds order with groupBy", ->
      design = {
        table: "t1"
        columns: [
          { textAxis: @axisText }
          { textAxis: @axisNumberSum }
        ]
        orderings: [
          { axis: @axisNumber, direction: "desc" }
        ]
      }

      @chart.getData(design, @schema, @dataSource, [])
      expectedQuery = {
        type: "query"
        selects: [
          { type: "select", expr: { type: "field", tableAlias: "main", column: "text" }, alias: "c0" }
          { type: "select", expr: { type: "op", op: "sum", exprs: [{ type: "field", tableAlias: "main", column: "number" }] }, alias: "c1" }
          { type: "select", expr: { type: "field", tableAlias: "main", column: "number" }, alias: "o0" }
          { type: "select", expr: { type: "op", op: "min", exprs: [{ type: "field", tableAlias: "main", column: "primary" }] }, alias: "id" }
          { type: "select", expr: { type: "op", op: "count", exprs: [] }, alias: "num_ids" }
        ]
        from: { type: "table", table: "t1", alias: "main" }
        groupBy: [1, 3]
        orderBy: [{ ordinal: 3, direction: "desc", nulls: "last" }]
        limit: 1000
      }

      compare(@query, expectedQuery)

  # describe "cleanDesign", ->
  #   it "cleans column expressions", ->
  #     design = {
  #       table: "t1"
  #       columns: [
  #         { expr: { type: "field", table: "t2", column: "text "} } # Wrong table
  #       ]
  #     }

  #     design = @chart.cleanDesign(design)

  #     expectedDesign = {
  #       table: "t1"
  #       columns: [
  #         { expr: null }
  #       ]
  #     }        

  #     compare(design, expectedDesign)

  #   it "removes invalid aggrs", ->
  #     design = {
  #       table: "t1"
  #       columns: [
  #         { expr: @exprText, aggr: "sum" }
  #       ]
  #     }

  #     design = @chart.cleanDesign(design)

  #     expectedDesign = {
  #       table: "t1"
  #       columns: [
  #         { expr: @exprText }
  #       ]
  #     }        

  #     compare(design, expectedDesign)

  #   it "defaults aggr to count if no expression type", ->
  #     design = {
  #       table: "t1"
  #       columns: [
  #         { expr: { type: "scalar", table: "t1", expr: null, joins: [] }, aggr: "sum" }
  #       ]
  #     }

  #     design = @chart.cleanDesign(design)

  #     expectedDesign = {
  #       table: "t1"
  #       columns: [
  #         { expr: { type: "scalar", table: "t1", expr: null, joins: [] }, aggr: "count" }
  #       ]
  #     }        

  #     compare(design, expectedDesign)

  #   it "cleans filter"

  describe "validateDesign", ->
    it "allows valid design", ->
      design = {
        table: "t1"
        columns: [
          { textAxis: @axisText }
        ]
        orderings: []
      }

      assert not @chart.validateDesign(design, @schema)

    it "validates column expressions", ->
      design = {
        table: "t1"
        columns: [
          { textAxis: null }
        ]
        orderings: []
      }

      assert @chart.validateDesign(design, @schema)

    it "validates filter"


