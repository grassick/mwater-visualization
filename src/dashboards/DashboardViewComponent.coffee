PropTypes = require('prop-types')
React = require 'react'
H = React.DOM
R = React.createElement

uuid = require 'uuid'

HTML5Backend = require('react-dnd-html5-backend')
NestableDragDropContext = require  "react-library/lib/NestableDragDropContext"
ImplicitFilterBuilder = require '../ImplicitFilterBuilder'

DashboardUtils = require './DashboardUtils'
ExprCompiler = require('mwater-expressions').ExprCompiler
ExprCleaner = require('mwater-expressions').ExprCleaner
WidgetFactory = require '../widgets/WidgetFactory'
WidgetScoper = require '../widgets/WidgetScoper'
ReactElementPrinter = require 'react-library/lib/ReactElementPrinter'
LayoutManager = require '../layouts/LayoutManager'
WidgetScopesViewComponent = require '../widgets/WidgetScopesViewComponent'

# Displays a dashboard, handling removing of widgets. No title bar or other decorations.
# Handles scoping and stores the state of scope
module.exports = class DashboardViewComponent extends React.Component
  @propTypes: 
    schema: PropTypes.object.isRequired # schema to use
    dataSource: PropTypes.object.isRequired # data source to use. Only used when designing, for display uses dashboardDataSource
    dashboardDataSource: PropTypes.object.isRequired # dashboard data source

    design: PropTypes.object.isRequired
    onDesignChange: PropTypes.func      # Leave unset for readonly

    width: PropTypes.number
    standardWidth: PropTypes.number   # Width for scaling

    onRowClick: PropTypes.func     # Called with (tableId, rowId) when item is clicked
    namedStrings: PropTypes.object # Optional lookup of string name to value. Used for {{branding}} and other replacement strings in text widget

    # Filters to add to the dashboard
    filters: PropTypes.arrayOf(PropTypes.shape({
      table: PropTypes.string.isRequired    # id table to filter
      jsonql: PropTypes.object.isRequired   # jsonql filter with {alias} for tableAlias
    }))

  @defaultProps:
    standardWidth: 1440 # Standard width. Matches 8.5x11" paper with 0.5" margin at 192dpi

  @childContextTypes:
    locale: PropTypes.string

  # Pass locale down. Both here and DashboardViewComponent to ensure that quickfilters also get context
  getChildContext: -> { locale: @props.design.locale }

  constructor: (props) ->
    super
    @state = {
      widgetScoper: new WidgetScoper() # Empty scoping
    }

  handleScopeChange: (id, scope) => 
    @setState(widgetScoper: @state.widgetScoper.applyScope(id, scope))

  handleRemoveScope: (id) =>
    @setState(widgetScoper: @state.widgetScoper.applyScope(id, null))    

  handleItemsChange: (items) =>
    design = _.extend({}, @props.design, items: items)
    @props.onDesignChange(design)

  # Call to print the dashboard
  print: =>
    # Create element at 96 dpi (usual for browsers) and 7.5" across (letter - 0.5" each side). 1440 is double, so scale down
    # props are immutable in React 0.14+
    elem = H.div style: { transform: "scale(0.5)", transformOrigin: "top left" },
      H.div style: { width: 1440 }, 
        R(DashboardViewComponent, _.extend({}, @props, { width: 1440, standardWidth: 1440, onDesignChange: null }))
    
    printer = new ReactElementPrinter()
    printer.print(elem, { delay: 5000 })

  # Get filters from props filters combined with dashboard filters
  getCompiledFilters: ->
    exprCompiler = new ExprCompiler(@props.schema)
    exprCleaner = new ExprCleaner(@props.schema)

    compiledFilters = []

    # Compile filters to JsonQL expected by widgets
    for table, expr of (@props.design.filters or {})
      # Clean expression first TODO remove this when dashboards are properly cleaned before being rendered
      expr = exprCleaner.cleanExpr(expr, { table: table })

      jsonql = exprCompiler.compileExpr(expr: expr, tableAlias: "{alias}")
      if jsonql
        compiledFilters.push({ table: table, jsonql: jsonql })

    # Add props filters
    if @props.filters
      compiledFilters = compiledFilters.concat(@props.filters)

    return compiledFilters

  renderScopes: ->
    R(WidgetScopesViewComponent, scopes: @state.widgetScoper.getScopes(), onRemoveScope: @handleRemoveScope)

  render: ->
    layoutManager = LayoutManager.createLayoutManager(@props.design.layout)

    compiledFilters = @getCompiledFilters()

    # Get filterable tables
    filterableTables = DashboardUtils.getFilterableTables(@props.design, @props.schema)

    renderWidget = (options) =>
      widget = WidgetFactory.createWidget(options.type)

      # Get filters (passed in plus dashboard widget scoper filters)
      filters = compiledFilters.concat(@state.widgetScoper.getFilters(options.id))

      # Extend the filters to include implicit filters (filter children in 1-n relationships)
      if @props.design.implicitFiltersEnabled or not @props.design.implicitFiltersEnabled? # Default is true
        implicitFilterBuilder = new ImplicitFilterBuilder(@props.schema)
        filters = implicitFilterBuilder.extendFilters(filterableTables, filters)
      
      return widget.createViewElement({
        schema: @props.schema
        dataSource: @props.dataSource
        widgetDataSource: @props.dashboardDataSource.getWidgetDataSource(options.id)
        design: options.design
        scope: @state.widgetScoper.getScope(options.id)
        filters: filters
        onScopeChange: @handleScopeChange.bind(null, options.id)
        onDesignChange: options.onDesignChange
        width: options.width
        height: options.height
        standardWidth: options.standardWidth 
        onRowClick: @props.onRowClick
        namedStrings: @props.namedStrings
      })  

    style = {
      height: "100%"
      position: "relative"
    }

    # Render widget container
    # TODO REMOVE DragDropContextComponent and change to H.div when grid layout is gone.
    return R DragDropContextComponent, style: style, 
      @renderScopes()

      layoutManager.renderLayout({
        width: @props.width 
        standardWidth: @props.standardWidth
        items: @props.design.items
        onItemsChange: if @props.onDesignChange? then @handleItemsChange
        style: @props.design.style
        renderWidget: renderWidget
      })

# Wrapper that has a nestable drag drop context
class DragDropContextComponent extends React.Component
  render: ->
    return H.div @props
        
DragDropContextComponent = NestableDragDropContext(HTML5Backend)(DragDropContextComponent)
