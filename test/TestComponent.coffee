React = require('react')
ReactDOM = require('react-dom')
TestUtils = require('react-addons-test-utils')
H = React.DOM

module.exports = class TestComponent
  constructor: (elem) ->
    @comp = TestUtils.renderIntoDocument(
      React.createElement(ComponentWrapper, elem: elem))

  setElement: (elem) ->
    @comp.setElement(elem)

  getComponent: ->
    return @comp.getComponent()

  getComponentNode: ->
    return @comp.getComponentNode()

# Wraps a react component, re-render
class ComponentWrapper extends React.Component
  constructor: (props) ->
    super
    @state = { elem: @props.elem }

  setElement: (elem) =>
    @setState(elem: elem)

  getComponent: ->
    return @refs.comp

  getComponentNode: ->
    return ReactDOM.findDOMNode(@refs.comp)

  render: ->
    H.div null,
      React.cloneElement(@state.elem, ref: "comp")

