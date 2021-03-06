var ExpressionBuilder, ExpressionCompiler, _, injectTableAlias,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

_ = require('lodash');

injectTableAlias = require('../injectTableAlias');

ExpressionBuilder = require('./ExpressionBuilder');

module.exports = ExpressionCompiler = (function() {
  function ExpressionCompiler(schema) {
    this.compileExpr = bind(this.compileExpr, this);
    this.schema = schema;
  }

  ExpressionCompiler.prototype.compileExpr = function(options) {
    var compiledExpr, expr;
    expr = options.expr;
    if (!expr) {
      return null;
    }
    switch (expr.type) {
      case "field":
        compiledExpr = this.compileFieldExpr(options);
        break;
      case "scalar":
        compiledExpr = this.compileScalarExpr(options);
        break;
      case "comparison":
        compiledExpr = this.compileComparisonExpr(options);
        break;
      case "logical":
        compiledExpr = this.compileLogicalExpr(options);
        break;
      case "literal":
        compiledExpr = {
          type: "literal",
          value: expr.value
        };
        break;
      case "count":
        compiledExpr = null;
        break;
      default:
        throw new Error("Expr type " + expr.type + " not supported");
    }
    return compiledExpr;
  };

  ExpressionCompiler.prototype.compileFieldExpr = function(options) {
    var column, expr;
    expr = options.expr;
    column = this.schema.getColumn(expr.table, expr.column);
    if (!column) {
      throw new Error("Column " + expr.table + "." + expr.column + " not found");
    }
    return this.compileColumnRef(column.jsonql || column.id, options.tableAlias);
  };

  ExpressionCompiler.prototype.compileScalarExpr = function(options) {
    var expr, extraWhere, from, i, j, join, limit, orderBy, ordering, ref, scalar, scalarExpr, table, tableAlias, where;
    expr = options.expr;
    where = null;
    from = null;
    orderBy = null;
    limit = null;
    table = expr.table;
    tableAlias = options.tableAlias;
    if (expr.joins && expr.joins.length > 0) {
      join = this.schema.getColumn(expr.table, expr.joins[0]).join;
      where = {
        type: "op",
        op: join.op,
        exprs: [this.compileColumnRef(join.toColumn, "j1"), this.compileColumnRef(join.fromColumn, tableAlias)]
      };
      from = this.compileTable(join.toTable, "j1");
      table = join.toTable;
      tableAlias = "j1";
    }
    if (expr.joins.length > 1) {
      for (i = j = 1, ref = expr.joins.length; 1 <= ref ? j < ref : j > ref; i = 1 <= ref ? ++j : --j) {
        join = this.schema.getColumn(table, expr.joins[i]).join;
        from = {
          type: "join",
          left: from,
          right: this.compileTable(join.toTable, "j" + (i + 1)),
          kind: "left",
          on: {
            type: "op",
            op: join.op,
            exprs: [this.compileColumnRef(join.fromColumn, "j" + i), this.compileColumnRef(join.toColumn, "j" + (i + 1))]
          }
        };
        table = join.toTable;
        tableAlias = "j" + (i + 1);
      }
    }
    if (expr.where) {
      extraWhere = this.compileExpr({
        expr: expr.where,
        tableAlias: tableAlias
      });
      if (where) {
        where = {
          type: "op",
          op: "and",
          exprs: [where, extraWhere]
        };
      } else {
        where = extraWhere;
      }
    }
    scalarExpr = this.compileExpr({
      expr: expr.expr,
      tableAlias: tableAlias
    });
    if (expr.aggr) {
      switch (expr.aggr) {
        case "last":
          ordering = this.schema.getTable(table).ordering;
          if (!ordering) {
            throw new Error("No ordering defined");
          }
          limit = 1;
          orderBy = [
            {
              expr: this.compileColumnRef(ordering, tableAlias),
              direction: "desc"
            }
          ];
          break;
        case "sum":
        case "count":
        case "avg":
        case "max":
        case "min":
        case "stdev":
        case "stdevp":
          if (!scalarExpr) {
            scalarExpr = {
              type: "op",
              op: expr.aggr,
              exprs: []
            };
          } else {
            scalarExpr = {
              type: "op",
              op: expr.aggr,
              exprs: [scalarExpr]
            };
          }
          break;
        default:
          throw new Error("Unknown aggregation " + expr.aggr);
      }
    }
    if (!from && !where && !orderBy && !limit) {
      return scalarExpr;
    }
    scalar = {
      type: "scalar",
      expr: scalarExpr
    };
    if (from) {
      scalar.from = from;
    }
    if (where) {
      scalar.where = where;
    }
    if (orderBy) {
      scalar.orderBy = orderBy;
    }
    if (limit) {
      scalar.limit = limit;
    }
    return scalar;
  };

  ExpressionCompiler.prototype.compileComparisonExpr = function(options) {
    var expr, exprBuilder, exprs, lhsExpr, rhsExpr;
    expr = options.expr;
    exprBuilder = new ExpressionBuilder(this.schema);
    if (exprBuilder.getComparisonRhsType(exprBuilder.getExprType(expr.lhs), expr.op) && (expr.rhs == null)) {
      return null;
    }
    lhsExpr = this.compileExpr({
      expr: expr.lhs,
      tableAlias: options.tableAlias
    });
    if (expr.rhs) {
      rhsExpr = this.compileExpr({
        expr: expr.rhs,
        tableAlias: options.tableAlias
      });
      exprs = [lhsExpr, rhsExpr];
    } else {
      exprs = [lhsExpr];
    }
    switch (expr.op) {
      case '= true':
        return {
          type: "op",
          op: "=",
          exprs: [
            lhsExpr, {
              type: "literal",
              value: true
            }
          ]
        };
      case '= false':
        return {
          type: "op",
          op: "=",
          exprs: [
            lhsExpr, {
              type: "literal",
              value: false
            }
          ]
        };
      case '= any':
        return {
          type: "op",
          op: "=",
          modifier: "any",
          exprs: exprs
        };
      case 'between':
        return {
          type: "op",
          op: "between",
          exprs: [
            lhsExpr, {
              type: "literal",
              value: expr.rhs.value[0]
            }, {
              type: "literal",
              value: expr.rhs.value[1]
            }
          ]
        };
      default:
        return {
          type: "op",
          op: expr.op,
          exprs: exprs
        };
    }
  };

  ExpressionCompiler.prototype.compileLogicalExpr = function(options) {
    var compiledExprs, expr;
    expr = options.expr;
    compiledExprs = _.map(expr.exprs, (function(_this) {
      return function(e) {
        return _this.compileExpr({
          expr: e,
          tableAlias: options.tableAlias
        });
      };
    })(this));
    compiledExprs = _.compact(compiledExprs);
    if (compiledExprs.length === 1) {
      return compiledExprs[0];
    }
    if (compiledExprs.length === 0) {
      return null;
    }
    return {
      type: "op",
      op: expr.op,
      exprs: compiledExprs
    };
  };

  ExpressionCompiler.prototype.compileColumnRef = function(column, tableAlias) {
    if (_.isString(column)) {
      return {
        type: "field",
        tableAlias: tableAlias,
        column: column
      };
    }
    return injectTableAlias(column, tableAlias);
  };

  ExpressionCompiler.prototype.compileTable = function(tableId, alias) {
    var table;
    table = this.schema.getTable(tableId);
    if (!table.jsonql) {
      return {
        type: "table",
        table: tableId,
        alias: alias
      };
    } else {
      return {
        type: "subquery",
        query: table.jsonql,
        alias: alias
      };
    }
  };

  return ExpressionCompiler;

})();
