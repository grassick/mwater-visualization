React = require 'react'
H = React.DOM
R = React.createElement

CheckboxComponent = require '../CheckboxComponent'
ClickOutHandler = require('react-onclickout')
MapLayersDesignerComponent = require './MapLayersDesignerComponent'
MapFiltersDesignerComponent = require './MapFiltersDesignerComponent'
BaseLayerDesignerComponent = require './BaseLayerDesignerComponent'
PopoverHelpComponent = require 'react-library/lib/PopoverHelpComponent'

module.exports = class MapDesignerComponent extends React.Component
  @propTypes:
    schema: React.PropTypes.object.isRequired # Schema to use
    dataSource: React.PropTypes.object.isRequired # Data source to use
    design: React.PropTypes.object.isRequired  # See Map Design.md
    onDesignChange: React.PropTypes.func.isRequired # Called with new design

  handleAttributionChange: (text) =>
    design = _.extend({}, @props.design, {attribution: text})
    @props.onDesignChange(design)

  handleAutoBoundsChange: (value) =>
    design = _.extend({}, @props.design, {autoBounds: value})
    @props.onDesignChange(design)

  render: ->
    H.div style: { padding: 5 },
      R MapLayersDesignerComponent, 
        schema: @props.schema
        dataSource: @props.dataSource
        design: @props.design
        onDesignChange: @props.onDesignChange
        allowEditingLayers: true

      R MapFiltersDesignerComponent, 
        schema: @props.schema
        dataSource: @props.dataSource
        design: @props.design
        onDesignChange: @props.onDesignChange

      H.div className: "form-group",
        H.label className: "text-muted", 
          "Map Style"
  
        R BaseLayerDesignerComponent,
          design: @props.design
          onDesignChange: @props.onDesignChange

      R CheckboxComponent, 
        checked: @props.design.autoBounds
        onChange: @handleAutoBoundsChange,
          H.span className: "text-muted", 
            "Automatic zoom "
            R PopoverHelpComponent, placement: "left",
              '''Automatically zoom to the complete data whenever the map is loaded or the filters change'''


      R AttributionComponent,
        text: @props.design.attribution
        onTextChange: @handleAttributionChange


# Attribution inline editing
class AttributionComponent extends React.Component
  @propTypes:
    text: React.PropTypes.string
    onTextChange: React.PropTypes.func.isRequired

  @defaultProps:
    text: null

  constructor: ->
    super

    @state = {
      editing: false
    }

  handleTextChange: (e) =>
    @props.onTextChange(e.target.value)

  handleClickOut: () =>
    @setState(editing: false)

  renderEditor: ->
    R ClickOutHandler, onClickOut: @handleClickOut,
      H.input { ref: "attributionInput", onChange: @handleTextChange, value: @props.text, className: 'form-control'}

  handleTextClick: =>
    @setState(editing: true)

  render: ->
    elem = H.div style: { marginLeft: 5 }, 
      if @state.editing
        @renderEditor()
      else
        if @props.text
          H.span onClick: @handleTextClick, style: { cursor: "pointer" },
            @props.text
        else
          H.a onClick: @handleTextClick, style: { fontSize: 12 },
            "+ Add attribution"

    if @props.text or @state.editing
      elem = H.div className: "form-group",
        H.label className: "text-muted",
          "Attribution"
        elem

    return elem
