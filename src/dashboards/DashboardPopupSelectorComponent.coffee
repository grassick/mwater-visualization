_ = require 'lodash'
React = require 'react'
H = React.DOM
R = React.createElement

uuid = require 'uuid'
ui = require 'react-library/lib/bootstrap'

DashboardPopupComponent = require './DashboardPopupComponent'

# Allows selecting/adding/removing/editing a popup
module.exports = class DashboardPopupSelectorComponent extends React.Component
  @propTypes:
    # All dashboard popups
    popups: React.PropTypes.arrayOf(React.PropTypes.shape({ id: React.PropTypes.string.isRequired, design: React.PropTypes.object.isRequired })).isRequired
    onPopupsChange: React.PropTypes.func               # If not set, readonly

    schema: React.PropTypes.object.isRequired
    dataSource: React.PropTypes.object.isRequired
    getPopupDashboardDataSource: React.PropTypes.func.isRequired # get popup dashboard data source given popup id

    onSystemAction: React.PropTypes.func # Called with (actionId, tableId, rowIds) when an action is performed on rows. actionId is id of action e.g. "open"
    namedStrings: React.PropTypes.object # Optional lookup of string name to value. Used for {{branding}} and other replacement strings in text widget

    # Gets available system actions for a table. Called with (tableId). 
    # Returns [{ id: id of action, name: name of action, multiple: true if for multiple rows support, false for single }]
    getSystemActions: React.PropTypes.func 

    # Filters to add to the dashboard
    filters: React.PropTypes.arrayOf(React.PropTypes.shape({
      table: React.PropTypes.string.isRequired    # id table to filter
      jsonql: React.PropTypes.object.isRequired   # jsonql filter with {alias} for tableAlias
    }))

    popupId: React.PropTypes.string
    onPopupIdChange: React.PropTypes.func.isRequired

  handleAddPopup: =>
    # Create popup
    popup = {
      id: uuid()
      design: { items: { id: "root", type: "root", blocks: [] }, layout: "blocks" } 
    }

    # Add to list
    popups = (@props.popups or []).slice()
    popups.push(popup)

    @props.onPopupsChange(popups)
    @props.onPopupIdChange(popup.id)

    # Display
    @dashboardPopupComponent.show(popup.id)

  handleEditPopup: =>
    popup = _.findWhere(@props.popups, id: @props.popupId)
    if not popup
      return

    # Display
    @dashboardPopupComponent.show(popup.id)

  handleRemovePopup: =>
    popups = _.filter(@props.popups, (popup) => popup.id != @props.popupId)
    @props.onPopupsChange(popups)
    @props.onPopupIdChange(null)

  render: ->
    H.div null, 
      R DashboardPopupComponent,
        ref: (c) => @dashboardPopupComponent = c
        popups: @props.popups
        onPopupsChange: @props.onPopupsChange
        schema: @props.schema
        dataSource: @props.dataSource
        getPopupDashboardDataSource: @props.getPopupDashboardDataSource
        onSystemAction: @props.onSystemAction
        getSystemActions: @props.getSystemActions
        namedStrings: @props.namedStrings
        filters: @props.filters

      if not @props.popupId
        H.a className: "btn btn-link", onClick: @handleAddPopup,
          H.i className: "fa fa-pencil"
          " Design Popup"
      else
        H.div null, 
          H.a className: "btn btn-link", onClick: @handleEditPopup,
            H.i className: "fa fa-pencil"
            " Customize Popup"

          H.a className: "btn btn-link", onClick: @handleRemovePopup,
            H.i className: "fa fa-times"
            " Remove Popup"

