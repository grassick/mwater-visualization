React = require 'react'
H = React.DOM
Dashboard = require './Dashboard'
WidgetFactory = require './WidgetFactory'

# Playground for a dashboard
module.exports = class DashboardTestComponent extends React.Component
  constructor: ->
    super

  componentDidMount: ->
    schema = createSchema()
    dataSource = new SimpleDataSource()

    # Create dashboard
    @dashboard = new Dashboard({
      design: dashboardDesign
      viewNode: React.findDOMNode(@refs.view)
      isDesigning: true
      onShowDesigner: => React.findDOMNode(@refs.designer)
      onHideDesigner: => alert("Designer hidden")
      width: 800
      widgetFactory: new WidgetFactory(schema, dataSource)
    })

    console.log "Rendering dashboard"
    @dashboard.render()

  render: ->
    H.div className: "row", style: { },
      H.div className: "col-xs-8", ref: "view"
      H.div className: "col-xs-4", ref: "designer"

data = {"main":[{"x":"broken","y":"48520"},{"x":null,"y":"2976"},{"x":"ok","y":"173396"},{"x":"maint","y":"12103"},{"x":"missing","y":"3364"}]}    

chartDesign = {
  "aesthetics": {
    "x": {
      "expr": {
        "type": "scalar",
        "table": "a",
        "joins": [],
        "expr": {
          "type": "field",
          "table": "a",
          "column": "enum"
        }
      }
    },
    "y": {
      "expr": {
        "type": "scalar",
        "table": "a",
        "joins": [],
        "expr": {
          "type": "field",
          "table": "a",
          "column": "decimal"
        }
      },
      "aggr": "sum"
    }
  },
  "table": "a",
  "filter": {
    "type": "logical",
    "table": "a",
    "op": "and",
    "exprs": [
      {
        "type": "comparison",
        "table": "a",
        "lhs": {
          "type": "scalar",
          "table": "a",
          "joins": [],
          "expr": {
            "type": "field",
            "table": "a",
            "column": "integer"
          }
        },
        "op": "=",
        "rhs": {
          "type": "literal",
          "valueType": "integer",
          "value": 5
        }
      }
    ]
  }
}


dashboardDesign = {
  items: {
    a: {
      layout: { x: 0, y: 0, w: 12, h: 12 }
      widget: {
        type: "BarChart"
        version: "0.0.0"
        design: chartDesign
      }
    }
    b: {
      layout: { x: 12, y: 0, w: 12, h: 12 }
      widget: {
        type: "BarChart"
        version: "0.0.0"
        design: _.cloneDeep(chartDesign)
      }
    }
  }
}

DataSource = require './DataSource'

class SimpleDataSource extends DataSource 
  performQueries: (queries, cb) ->
    cb(null, data)

Schema = require './Schema'

createSchema = ->
  # Create simple schema with subtree
  schema = new Schema()
  schema.addTable({ id: "a", name: "A" })
  schema.addColumn("a", { id: "x", name: "X", type: "id" })
  schema.addColumn("a", { id: "y", name: "Y", type: "text" })
  schema.addColumn("a", { id: "integer", name: "Integer", type: "integer" })
  schema.addColumn("a", { id: "decimal", name: "Decimal", type: "decimal" })
  schema.addColumn("a", { id: "enum", name: "Enum", type: "enum", values: [
    { id: "apple", name: "Apple" }
    { id: "banana", name: "Banana" }
    ] })
  schema.addColumn("a", 
    { id: "b", name: "A to B", type: "join", join: {
      fromTable: "a", fromColumn: "x", toTable: "b", toColumn: "q", op: "=", multiple: true }})

  schema.addTable({ id: "b", name: "B" })
  schema.addColumn("b", { id: "q", name: "Q", type: "id" }) 
  schema.addColumn("b", { id: "r", name: "R", type: "integer" })
  schema.addColumn("b", { id: "s", name: "S", type: "text" })
  return schema