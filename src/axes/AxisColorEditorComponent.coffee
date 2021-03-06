PropTypes = require('prop-types')
_ = require 'lodash'
React = require 'react'
H = React.DOM
R = React.createElement
CategoryMapComponent = require './CategoryMapComponent'
ColorSchemeFactory = require '../ColorSchemeFactory'
ColorPaletteCollectionComponent = require './ColorPaletteCollectionComponent'
update = require 'update-object'
AxisBuilder = require './AxisBuilder'

# Color editor for axis. Allows switching between editing individial colors (using CategoryMapComponent) 
# and setting the colors from a palette (using ColorPaletteCollectionComponent)
module.exports = class AxisColorEditorComponent extends React.Component
  @propTypes:
    schema: PropTypes.object.isRequired
    dataSource: PropTypes.object.isRequired
    axis: PropTypes.object.isRequired
    onChange: PropTypes.func.isRequired # Called with new axis
    categories: PropTypes.array # Categories of the axis
    reorderable: PropTypes.bool # is the color map reorderable
    defaultColor: PropTypes.string
    allowExcludedValues: PropTypes.bool # True to allow excluding of values via checkboxes
    initiallyExpanded: PropTypes.bool  # True to start values expanded

  @defaultProps:
    reorderable: false

  constructor: (props) ->
    super(props)

    @state = {
      mode: "normal"
    }

  componentWillMount: ->
    @updateColorMap(@props.categories)

  componentDidUpdate: ->
    @updateColorMap(@props.categories)

  # Update color map if categories no longer match
  updateColorMap: (categories) ->
    axisBuilder = new AxisBuilder(schema: @props.schema)

    # If no categories, can't do anything
    if not categories
      return

    # If no color map or color map values have changed
    if not @props.axis.colorMap or not _.isEqual(_.pluck(@props.axis.colorMap, "value").sort(), _.pluck(categories, "value").sort())
      colorMap = ColorSchemeFactory.createColorMapForCategories(categories, axisBuilder.isCategorical(@props.axis))
      @handlePaletteChange(colorMap)
      @setState(mode: "normal")

  handleSelectPalette: =>
    @setState(mode: "palette")

  handlePaletteChange: (palette) =>
    @props.onChange(update(@props.axis, { colorMap: { $set: palette }, drawOrder: { $set: _.pluck(palette, "value") }}))
    @setState(mode: "normal")

  handleCancelCustomize: =>
    @setState(mode: "normal")

  renderPreview: ->
    H.div className: "axis-palette",
      _.map @props.categories.slice(0,6), (category, i) =>
        color = _.find(@props.axis.colorMap, {value: category.value})
        cellStyle =
          display: 'inline-block'
          height: 20
          width: 20
          backgroundColor: if color then color.color else @props.defaultColor
        H.div style: cellStyle, key: i, " "

  render: ->
    H.div null,
      if @state.mode == "palette"
        if @props.categories
          R ColorPaletteCollectionComponent, {
            onPaletteSelected: @handlePaletteChange
            axis: @props.axis
            categories: @props.categories
            onCancel: @handleCancelCustomize
          }
      if @state.mode == "normal"
        H.div null,
          H.p null,
            H.a style: { cursor: "pointer" }, onClick: @handleSelectPalette, key: "select-palette", "Change color scheme"
          if @props.axis.colorMap
            H.div key: "selected-palette",
              H.div null,
                R CategoryMapComponent,
                  schema: @props.schema
                  dataSource: @props.dataSource
                  axis: @props.axis
                  onChange: @props.onChange
                  categories: @props.categories
                  key: "colorMap"
                  reorderable: @props.reorderable
                  allowExcludedValues: @props.allowExcludedValues
                  showColorMap: true
                  initiallyExpanded: @props.initiallyExpanded

