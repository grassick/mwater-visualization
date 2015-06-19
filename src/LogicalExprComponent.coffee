React = require 'react'
H = React.DOM
ComparisonExprComponent = require './ComparisonExprComponent'

module.exports = class LogicalExprComponent extends React.Component
  @propTypes: 
    value: React.PropTypes.object
    onChange: React.PropTypes.func.isRequired 
    schema: React.PropTypes.object.isRequired
    table: React.PropTypes.string.isRequired 

  handleExprChange: (i, expr) =>
    # Replace exprs
    exprs = @props.value.exprs.slice()
    exprs[i] = expr
    @props.onChange(_.extend({}, @props.value, exprs: exprs))

  handleAdd: =>
    expr = @props.value or { type: "logical", table: @props.table, op: "and", exprs: [] }
    exprs = expr.exprs.concat([{ type: "comparison", table: @props.table }])
    @props.onChange(_.extend({}, expr, exprs: exprs))

  handleRemove: (i) =>
    exprs = @props.value.exprs.slice()
    exprs.splice(i, 1)
    @props.onChange(_.extend({}, @props.value, exprs: exprs))    

  render: ->
    if @props.value
      childElems = _.map @props.value.exprs, (e, i) =>
        H.div key: "#{i}",
          React.createElement(ComparisonExprComponent, 
            value: e, 
            schema: @props.schema, 
            table: @props.table, 
            onChange: @handleExprChange.bind(null, i))
          H.button 
            type: "button", 
            className: "btn btn-sm btn-link", 
            onClick: @handleRemove.bind(null, i),
              H.span(className: "glyphicon glyphicon-remove")
 
    # Render all expressions (comparisons for now)
    H.div null,
      childElems
      H.button className: "btn btn-sm btn-link", type: "button", onClick: @handleAdd,
        H.span className: "glyphicon glyphicon-plus"
        " Add Filter"

