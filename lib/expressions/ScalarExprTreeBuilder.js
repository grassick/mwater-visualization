var ExpressionBuilder, ScalarExprTreeBuilder,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

ExpressionBuilder = require('./ExpressionBuilder');

module.exports = ScalarExprTreeBuilder = (function() {
  function ScalarExprTreeBuilder(schema) {
    this.schema = schema;
  }

  ScalarExprTreeBuilder.prototype.getTree = function(options) {
    var fn, i, len, nodes, ref, table;
    if (options == null) {
      options = {};
    }
    nodes = [];
    if (!options.table) {
      ref = this.schema.getTables();
      fn = (function(_this) {
        return function(table) {
          var node;
          node = {
            name: table.name,
            desc: table.desc,
            initiallyOpen: options.table != null
          };
          node.children = function() {
            return _this.createChildNodes({
              startTable: table.id,
              table: table.id,
              joins: [],
              types: options.types,
              initialValue: options.initialValue
            });
          };
          return nodes.push(node);
        };
      })(this);
      for (i = 0, len = ref.length; i < len; i++) {
        table = ref[i];
        fn(table);
      }
    } else {
      nodes = this.createChildNodes({
        startTable: options.table,
        table: options.table,
        joins: [],
        types: options.types,
        includeCount: options.includeCount,
        initialValue: options.initialValue
      });
    }
    return nodes;
  };

  ScalarExprTreeBuilder.prototype.createChildNodes = function(options) {
    var column, exprBuilder, fn, i, len, nodes, ref;
    nodes = [];
    exprBuilder = new ExpressionBuilder(this.schema);
    if (options.includeCount) {
      nodes.push({
        name: "Number of " + (this.schema.getTable(options.table).name),
        value: {
          table: options.startTable,
          joins: options.joins,
          expr: null
        }
      });
    }
    ref = this.schema.getColumns(options.table);
    fn = (function(_this) {
      return function(column) {
        var fieldExpr, initVal, joins, node, ref1, types;
        node = {
          name: column.name,
          desc: column.desc
        };
        if (column.type === "join") {
          joins = options.joins.slice();
          joins.push(column.id);
          initVal = options.initialValue;
          node.children = function() {
            var includeCount;
            includeCount = exprBuilder.isMultipleJoins(options.startTable, joins);
            return _this.createChildNodes({
              startTable: options.startTable,
              table: column.join.toTable,
              joins: joins,
              types: options.types,
              includeCount: includeCount,
              initialValue: initVal
            });
          };
          if (initVal && initVal.joins && _.isEqual(initVal.joins.slice(0, joins.length), joins)) {
            node.initiallyOpen = true;
          }
        } else {
          fieldExpr = {
            type: "field",
            table: options.table,
            column: column.id
          };
          if (options.types) {
            if (exprBuilder.isMultipleJoins(options.startTable, options.joins)) {
              types = exprBuilder.getAggrTypes(fieldExpr);
              if (_.intersection(types, options.types).length === 0) {
                return;
              }
            } else {
              if (ref1 = column.type, indexOf.call(options.types, ref1) < 0) {
                return;
              }
            }
          }
          node.value = {
            table: options.startTable,
            joins: options.joins,
            expr: fieldExpr
          };
        }
        return nodes.push(node);
      };
    })(this);
    for (i = 0, len = ref.length; i < len; i++) {
      column = ref[i];
      fn(column);
    }
    return nodes;
  };

  return ScalarExprTreeBuilder;

})();