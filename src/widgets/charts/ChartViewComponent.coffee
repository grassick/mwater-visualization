React = require 'react'
H = React.DOM
asyncLatest = require 'async-latest'

# Inner view part of the chart widget. Uses a query data loading component
# to handle loading and continues to display old data if design becomes
# invalid
module.exports = class ChartViewComponent extends React.Component
  @propTypes:
    chart: React.PropTypes.object.isRequired # Chart object to use
    design: React.PropTypes.object.isRequired # Design of chart
    dataSource: React.PropTypes.object.isRequired # Data source to use for chart

    width: React.PropTypes.number
    height: React.PropTypes.number
    standardWidth: React.PropTypes.number

    scope: React.PropTypes.any # scope of the widget (when the widget self-selects a particular scope)
    filters: React.PropTypes.array  # array of filters to apply. Each is { table: table id, jsonql: jsonql condition with {alias} for tableAlias }. Use injectAlias to correct
    onScopeChange: React.PropTypes.func # called with (scope) as a scope to apply to self and filter to apply to other widgets. See WidgetScoper for details

  constructor: ->
    super

    @state = {
      validDesign: null     # last valid design
      data: null            # data for chart
      dataLoading: false    # True when loading data
      dataError: null       # Set when data loading returned error
    }

    # Ensure that only one load at a time
    @loadData = asyncLatest(@loadData, { serial: true })

    @state = {}

  # Get options in react-select format
  componentDidMount: ->
    @updateData(@props)

  componentWillReceiveProps: (nextProps) ->
    if not _.isEqual(nextProps.design, @props.design) or not _.isEqual(nextProps.filters, @props.filters)
      @updateData(nextProps)

  updateData: (props) ->
    # Clean design first (needed to validate properly)
    design = props.chart.cleanDesign(props.design)

    # If design is not valid, do nothing as can't query invalid design
    errors = props.chart.validateDesign(design)
    if errors
      return

    # Loading data
    @setState(dataLoading: true)

    @loadData(props, (error, data) =>
      @setState(dataLoading: false, dataError: error, data: data, validDesign: design)
    )

  loadData: (props, callback) ->
    # Get data from chart
    props.chart.getData(props.design, props.filters, callback)

  render: ->
    style = { width: @props.width, height: @props.height }

    # Faded if loading
    if @state.dataLoading
      style.opacity = 0.5

    # Faded if design is different than valid design (clean first to ensure that consistent)
    if not _.isEqual(@props.chart.cleanDesign(@props.design), @state.validDesign)
      style.opacity = 0.5

    # If nothing to show, show grey
    if not @state.validDesign
      # Invalid. Show faded with background
      style.backgroundColor = "#E0E0E0"
      style.opacity = 0.35

    return H.div style: style,
      if @state.validDesign
        @props.chart.createViewElement({
          design: @state.validDesign
          data: @state.data
          scope: @props.scope
          onScopeChange: @props.onScopeChange
          width: @props.width
          height: @props.height
          standardWidth: @props.standardWidth
          })
