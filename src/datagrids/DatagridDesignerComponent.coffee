_ = require 'lodash'
React = require 'react'
H = React.DOM
R = React.createElement

ExprUtils = require("mwater-expressions").ExprUtils
TableSelectComponent = require('mwater-visualization').TableSelectComponent
TabbedComponent = require 'react-library/lib/TabbedComponent'
ExprComponent = require('mwater-expressions-ui').ExprComponent
FilterExprComponent = require('mwater-expressions-ui').FilterExprComponent
ReactReorderable = require 'react-reorderable'

uuid = require 'node-uuid'
update = require 'update-object'


module.exports = class DatagridDesignerComponent extends React.Component
  @propTypes:
    schema: React.PropTypes.object.isRequired     # schema to use
    dataSource: React.PropTypes.object.isRequired # dataSource to use
    design: React.PropTypes.object.isRequired     # Design of datagrid. See README.md of this folder
    onDesignChange: React.PropTypes.func.isRequired # Called when design changes

  handleTableChange: (table) =>
    # Create default columns
    columns = []

    for col in @props.schema.getColumns(table)
      # Skip joins
      if col.type == "join"
        continue 

      columns.push({ 
         id: uuid.v4()
         type: "expr"
         width: 150
         expr: { type: "field", table: table, column: col.id }
         label: null
      })

    design = {
      table: table
      columns: columns
    }

    @props.onDesignChange(design)
 
  handleColumnsChange: (columns) => 
    @props.onDesignChange(update(@props.design, columns: { $set: columns }))

  handleFilterChange: (filter) => 
    @props.onDesignChange(update(@props.design, filter: { $set: filter }))

  # Render the tabs of the designer
  renderTabs: ->
    R TabbedComponent, 
      initialTabId: "columns"
      tabs: [
        { 
          id: "columns"
          label: "Columns"
          elem: R(ColumnsDesignerComponent, {
            schema: @props.schema
            dataSource: @props.dataSource
            table: @props.design.table
            columns: @props.design.columns
            onColumnsChange: @handleColumnsChange
          }) 
        }
        { 
          id: "filter"
          label: "Filter"
          elem: R(FilterExprComponent, {
            schema: @props.schema
            dataSource: @props.dataSource
            table: @props.design.table
            value: @props.design.filter
            onChange: @handleFilterChange
          }) 
        }
      ]

  render: ->
    H.div null,
      H.label null, "Data Source:"
      R TableSelectComponent, 
        schema: @props.schema
        value: @props.design.table
        onChange: @handleTableChange

      if @props.design.table
        @renderTabs()


# Columns list
class ColumnsDesignerComponent extends React.Component
  @propTypes:
    schema: React.PropTypes.object.isRequired     # schema to use
    dataSource: React.PropTypes.object.isRequired # dataSource to use
    table: React.PropTypes.string.isRequired
    columns: React.PropTypes.array.isRequired     # Columns list See README.md of this folder
    onColumnsChange: React.PropTypes.func.isRequired # Called when columns changes

  handleColumnChange: (columnIndex, column) =>
    columns = @props.columns.slice()

    # Handle remove
    if not column
      columns.splice(columnIndex, 1)
    else
      columns[columnIndex] = column
      
    @props.onColumnsChange(columns)

  handleAddColumn: =>
    columns = @props.columns.slice()
    columns.push({ id: uuid.v4(), type: "expr", width: 150 })
    @props.onColumnsChange(columns)

  handleReorder: (elems) =>
    # Extract columns
    columns = _.map(elems, (e) -> e.props.column)
    @props.onColumnsChange(columns)

  handleRemoveAllColumns: => 
    @props.onColumnsChange([])

  render: ->
    H.div style: { height: 800, overflowY: "auto", overflowX: "hidden" }, 
      H.button
        key: "removeall"
        type: "button"
        className: "btn btn-link btn-xs"
        onClick: @handleRemoveAllColumns,
          H.span className: "glyphicon glyphicon-remove"
          " Remove All Columns"

      R ReactReorderable, onDrop: @handleReorder, handle: ".drag-handle",
        _.map @props.columns, (column, columnIndex) =>
          R ColumnDesignerComponent, 
            key: columnIndex
            schema: @props.schema
            table: @props.table
            dataSource: @props.dataSource
            column: column
            onColumnChange: @handleColumnChange.bind(null, columnIndex)

      H.button
        key: "add"
        type: "button"
        className: "btn btn-default"
        onClick: @handleAddColumn,
          H.span className: "glyphicon glyphicon-plus"
          " Add Column"

# Column item
class ColumnDesignerComponent extends React.Component
  @propTypes:
    schema: React.PropTypes.object.isRequired     # schema to use
    dataSource: React.PropTypes.object.isRequired # dataSource to use
    table: React.PropTypes.string.isRequired
    column: React.PropTypes.object.isRequired     # Column See README.md of this folder
    onColumnChange: React.PropTypes.func.isRequired # Called when column changes. Null to remove

  handleExprChange: (expr) =>
    @props.onColumnChange(update(@props.column, expr: { $set: expr }))

  handleLabelChange: (label) =>
    @props.onColumnChange(update(@props.column, label: { $set: label }))

  render: =>
    exprUtils = new ExprUtils(@props.schema)

    H.div className: "row",
      H.div className: "col-xs-1",
        H.span className: "text-muted glyphicon glyphicon-move drag-handle"

      H.div className: "col-xs-5", # style: { border: "solid 1px #DDD", padding: 4 }, 
        R ExprComponent,
          schema: @props.schema
          dataSource: @props.dataSource
          table: @props.table
          value: @props.column.expr
          onChange: @handleExprChange

      H.div className: "col-xs-5",
        H.input
          type: "text"
          className: "form-control"
          placeholder: exprUtils.summarizeExpr(@props.column.expr)
          value: @props.column.label
          onChange: (ev) => @handleLabelChange(ev.target.value)

      H.div className: "col-xs-1",
        H.a onClick: @props.onColumnChange.bind(null, null),
          H.span className: "glyphicon glyphicon-remove"


