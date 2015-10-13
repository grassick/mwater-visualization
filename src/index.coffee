ui = require './UIComponents'

exports.Schema = require './Schema'
exports.LogicalExprComponent = require './expressions/LogicalExprComponent'
exports.ExpressionBuilder = require './expressions/ExpressionBuilder'
exports.ExpressionCompiler = require './expressions/ExpressionCompiler'
exports.ScalarExprComponent = require './expressions/ScalarExprComponent'
exports.ScalarExprEditorComponent = require './expressions/ScalarExprEditorComponent'

exports.DataSource = require './DataSource'
exports.CachingDataSource = require './CachingDataSource'
exports.WidgetFactory = require './widgets/WidgetFactory'

exports.UndoStack = require './UndoStack'

exports.PopoverComponent = require './PopoverComponent'
exports.DashboardComponent = require './widgets/DashboardComponent'
exports.AutoSizeComponent = require './AutoSizeComponent'

exports.BingLayer = require './maps/BingLayer'
exports.UtfGridLayer = require './maps/UtfGridLayer'
exports.LeafletMapComponent = require './maps/LeafletMapComponent'

exports.LayerFactory = require './maps/LayerFactory'
exports.MapViewComponent = require './maps/MapViewComponent'
exports.MapDesignerComponent = require './maps/MapDesignerComponent'
exports.MapComponent = require './maps/MapComponent'

exports.VerticalLayoutComponent = require './VerticalLayoutComponent'
exports.ActionCancelModalComponent = require './ActionCancelModalComponent'
exports.RadioButtonComponent = require './RadioButtonComponent'
exports.CheckboxComponent = require './CheckboxComponent'

exports.DateRangeComponent = require './DateRangeComponent'

exports.injectTableAlias = require './injectTableAlias'
exports.TabbedComponent = require './TabbedComponent'

# exports.UIComponents = require './UIComponents'
exports.ToggleEditComponent = ui.ToggleEditComponent
exports.OptionListComponent = ui.OptionListComponent

# http://stackoverflow.com/questions/19305821/multiple-modals-overlay
$ = require 'jquery'

`
$(document).on('show.bs.modal', '.modal', function () {
    var zIndex = 1040 + (10 * $('.modal:visible').length);
    $(this).css('z-index', zIndex);
    setTimeout(function() {
        $('.modal-backdrop').not('.modal-stack').css('z-index', zIndex - 1).addClass('modal-stack');
    }, 0);
});
$(document).on('hidden.bs.modal', '.modal', function () {
    $('.modal:visible').length && $(document.body).addClass('modal-open');
});
`