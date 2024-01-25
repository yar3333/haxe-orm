import hant.FlashDevelopProject;
import hant.Log;
import hant.Path;
import orm.Db;
import stdlib.FileSystem;
import sys.io.File;
import HaxeClass.HaxeVar;
using stdlib.StringTools;
using stdlib.Lambda;

class OrmManagerGenerator 
{
	var project : FlashDevelopProject;
	
	public function new(project:FlashDevelopProject)
    {
		this.project = project;
	}
	
	public function make(db:Db, table:OrmTable, customOrmClassName:String, srcPath:String, positions:OrmPositions) : Void
	{
		Log.start(table.tableName + " => " + table.customManagerClassName);
		
		var vars = OrmTools.fields2vars(table.tableName, db.connection.getFields(table.tableName), positions);
		
		var autoGeneratedManager = getAutogenManager(db, table.tableName, vars, table.customModelClassName, table.autogenManagerClassName, customOrmClassName, positions);
		var destFileName = srcPath + table.autogenManagerClassName.replace('.', '/') + '.hx';
		FileSystem.createDirectory(Path.directory(destFileName));
		File.saveContent(
			 destFileName
			,"// This is autogenerated file. Do not edit!\n\n" + autoGeneratedManager.toString()
		);
		
		if (project.findFile(table.customManagerClassName.replace('.', '/') + '.hx') == null)
		{
			var customManager = getCustomManager(table.tableName, vars, table.customModelClassName, table.customManagerClassName, table.autogenManagerClassName);
			var destFileName = srcPath + table.customManagerClassName.replace('.', '/') + '.hx';
			FileSystem.createDirectory(Path.directory(destFileName));
			File.saveContent(destFileName, customManager.toString());
		}
		
		Log.finishSuccess();
	}
	
	function getAutogenManager(db:Db, table:String, vars:Array<OrmHaxeVar>, modelClassName:String, autogenManagerClassName:String, customOrmClassName:String, positions:OrmPositions) : HaxeClass
	{
		var model:HaxeClass = new HaxeClass(autogenManagerClassName);
		
		model.addVar({ haxeName:"db", haxeType:"orm.Db", haxeDefVal:null }, true);
		model.addVar({ haxeName:"orm", haxeType:customOrmClassName, haxeDefVal:null }, true);
		model.addVar({ haxeName:"query(get, never)", haxeType:"orm.SqlQuery<" + modelClassName + ">", haxeDefVal:null });
		
		model.addMethod
		(
			'get_query',
			[],
			'orm.SqlQuery<' + modelClassName + '>',
			"return new orm.SqlQuery<" + modelClassName + ">(\"" + table + "\", db, this);",
			true
		);
		
		model.addMethod
		(
			  "new"
			, [ 
				  { haxeName:"db", haxeType:"orm.Db", haxeDefVal:null } 
				, { haxeName:"orm", haxeType:customOrmClassName, haxeDefVal:null } 
			  ]
			, "Void"
			, "this.db = db;\nthis.orm = orm;"
		);
        
        model.addMethod
		(
			'newModelFromParams',
			vars,
			modelClassName,
			  "var _obj = new " + modelClassName + "(db, orm);\n"
			+ vars.map((x) -> '_obj.' + x.haxeName + ' = ' + x.haxeName + ';').join('\n') + "\n"
			+ "return _obj;",
			true
		);
		
		model.addMethod
		(
			'newModelFromRow',
			[ OrmTools.createVar('d', 'Dynamic') ],
			modelClassName,
			  "var _obj = new " + modelClassName + "(db, orm);\n"
			+ vars.map((x) -> '_obj.' + x.haxeName + " = Reflect.field(d, '" + x.haxeName + "');").join('\n') + "\n"
			+ "return _obj;"
			, true
		);
		
		model.addMethod
		(
			'where',
			[ OrmTools.createVar('field', 'String'), OrmTools.createVar('op', 'String'), OrmTools.createVar('value', 'Dynamic') ],
			'orm.SqlQuery<' + modelClassName + '>',
			"return query.where(field, op, value);"
		);
		
		var getVars = vars.filter((x) -> x.isKey);
		if (getVars.length > 0)
		{
			model.addMethod
			(
				'get',
				getVars,
				modelClassName,
				"return getBySqlOne('SELECT * FROM `" + table + "`" + getWhereSql(getVars) + ");"
			);
		}
		
		var createVars = vars.filter((x) -> !x.isAutoInc);
		
		model.addMethod
		(
			'create',
			createVars,
			modelClassName,
			createVars.filter(positions.is).map((x) -> 
				  "if (" + x.haxeName + " == null)\n"
				+ "{\n"
				+ "\tposition = db.query('SELECT MAX(`" + x.name + "`) FROM `" + table + "`" 
					+ getWhereSql(getForeignKeyVars(db, table, vars))
					+ ").getIntResult(0) + 1;\n"
				+ "}\n\n"
			).join("")
			+"db.query('INSERT INTO `" + table + "`("
				+ createVars.map((x) -> "`" + x.name + "`").join(", ")
			+") VALUES (' + "
				+ createVars.map((x) -> "db.quote(" + x.haxeName + ")").join(" + ', ' + ")
			+" + ')');\n"
			+"return newModelFromParams(" + vars.map((x) -> x.isAutoInc ? 'db.lastInsertId()' : x.haxeName).join(", ") + ");"
		);
		
		model.addMethod
		(
			'createNamed',
			[ OrmTools.createVar("data", "{ " + createVars.map((x) -> x.haxeName + ":" + x.haxeType).join(", ") + " }") ],
			modelClassName,
			createVars.filter(positions.is).map((x) ->
				"if (data." + x.haxeName + " == null)\n"
				+ "{\n"
				+ "\tdata." + x.haxeName + " = db.query('SELECT MAX(`" + x.name + "`) FROM `" + table + "`" 
					+ getWhereSql(getForeignKeyVars(db, table, vars))
					+ ").getIntResult(0) + 1;\n"
				+ "}\n\n"
			).join("")
			+"db.query('INSERT INTO `" + table + "`("
				+ createVars.map((x) -> "`" + x.name + "`").join(", ")
			+") VALUES (' + "
				+ createVars.map((x) -> "db.quote(data." + x.haxeName + ")").join(" + ', ' + ")
			+" + ')');\n"
			+"return newModelFromParams(" + vars.map((x) -> x.isAutoInc ? 'db.lastInsertId()' : "data." + x.haxeName).join(", ") + ");"
		);
		
		var dataVars = [ OrmTools.createVar("data", "{ " + createVars.map((x) -> (x.isKey ? "" : "?") + x.haxeName + ":" + x.haxeType).join(", ") + " }") ];
		
		if (vars.exists((x) -> x.isKey))
		{
			model.addMethod
			(
				'createOptional',
				dataVars,
				modelClassName,
				 "createOptionalNoReturn(data);\n"
				+"return get(" + getVars.map((x) -> x.isAutoInc ? 'db.lastInsertId()' : "data." + x.haxeName).join(", ") + ");"
			);
		}
		
		model.addMethod
		(
			'createOptionalNoReturn',
			dataVars,
			"Void",
			createVars.filter(positions.is).map((x) -> 
				"if (data." + x.haxeName + " == null)\n"
				+ "{\n"
				+ "\tdata." + x.haxeName + " = db.query('SELECT MAX(`" + x.name + "`) FROM `" + table + "`" 
					+ getWhereSql(getForeignKeyVars(db, table, vars))
					+ ").getIntResult(0) + 1;\n"
				+ "}\n\n"
			).join("")
			+"var fields = [];\n"
			+"var values = [];\n"
			+createVars.map((x) -> 
				x.isKey
					? "fields.push('`" + x.name + "`'); values.push(db.quote(data." + x.haxeName + "));\n"
					: "if (Reflect.hasField(data, '" + x.haxeName + "')) { fields.push('`" + x.name + "`'); values.push(db.quote(data." + x.haxeName + ")); }\n"
			).join("")
			+"db.query('INSERT INTO `" + table + "`(' + fields.join(\", \") + ') VALUES (' + values.join(\", \") + ')');\n"
		);
		
		var deleteVars = vars.filter((x) -> x.isKey);
		if (deleteVars.length == 0) deleteVars = vars;
		model.addMethod
		(
			'delete',
			deleteVars,
			'Void',
			"db.query('DELETE FROM `" + table + "`" + getWhereSql(deleteVars) + " + ' LIMIT 1');"
		);
		
		model.addMethod
		(
			'getAll',
			[ OrmTools.createVar('_order', 'String', getOrderDefVal(vars, positions)) ],
			'Array<' + modelClassName + '>',
			"return getBySqlMany('SELECT * FROM `" + table + "`' + (_order != null ? ' ORDER BY ' + _order : ''));"
		);
		
		model.addMethod
		(
			'getBySqlOne',
			[ OrmTools.createVar('sql', 'String') ],
			modelClassName,
			 "var rows = db.query(sql + ' LIMIT 1');\n"
			+"if (rows.length == 0) return null;\n"
			+"return newModelFromRow(rows.next());"
		);
		
		model.addMethod
		(
			'getBySqlMany',
			[ OrmTools.createVar('sql', 'String') ], 'Array<' + modelClassName + '>',
			 "var rows = db.query(sql);\n"
			+"var list : Array<" + modelClassName + "> = [];\n"
			+"for (row in rows)\n"
			+"{\n"
			+"	list.push(newModelFromRow(row));\n"
			+"}\n"
			+"return list;"
		);
		
        for (fields in db.connection.getUniques(table))
		{
            var vs = vars.filter((x) -> fields.has(x.name));
			createGetByMethodOne(table, vars, modelClassName, vs, model);
		}
		
        for (v in getForeignKeyVars(db, table, vars))
        {
            createGetByMethodMany(table, vars, modelClassName, [v], model, positions);
        }
		
		return model;
	}
	
	function getCustomManager(table:String, vars:Array<OrmHaxeVar>, modelClassName:String, fullClassName:String, baseClassName:String=null) : HaxeClass
	{
		var model = new HaxeClass(fullClassName, baseClassName);
		
		model.addImport(modelClassName);
		
		return model;
	}
	
	function createGetByMethodOne(table:String, vars:Array<OrmHaxeVar>, modelClassName:String, whereVars:Array<OrmHaxeVar>, model:HaxeClass) : Void
	{
		if (whereVars == null || whereVars.length == 0) return;
        
        model.addMethod
		(
			'getBy' + whereVars.map((x) -> x.haxeName.capitalize()).join('And'),
			whereVars, 
			modelClassName,
			"return getBySqlOne('SELECT * FROM `" + table + "`" + getWhereSql(whereVars) + ");"
		);
	}
	
	function createGetByMethodMany(table:String, vars:Array<OrmHaxeVar>, modelClassName:String, whereVars:Array<OrmHaxeVar>, model:HaxeClass, positions:OrmPositions) : Void
	{
		if (whereVars == null || !whereVars.iterator().hasNext()) return;

		model.addMethod
		(
			'getBy' + whereVars.map(function(v) return v.haxeName.capitalize()).join('And'),
			(cast whereVars:Array<HaxeVar>).concat([ OrmTools.createVar('_order', 'String', getOrderDefVal(vars, positions)) ]), 
			'Array<' + modelClassName + '>',
			"return getBySqlMany('SELECT * FROM `" + table + "`" + getWhereSql(whereVars) + " + (_order != null ? ' ORDER BY ' + _order : ''));"
		);
	}
	
	function getOrderDefVal(vars:Array<OrmHaxeVar>, positions:OrmPositions) : String
	{
		var positionVar = vars.filter((x) -> positions.is(x));
		return positionVar.length == 0 ? "null" : "'" + positionVar.map((x) -> x.name).join(", ") + "'";
	}
    
    function getWhereSql(vars:Array<OrmHaxeVar>) : String
    {
        return vars.iterator().hasNext()
            ? " WHERE " + vars.map(function(v) return "`" + v.name + "` = ' + db.quote(" + v.haxeName + ")").join("+ ' AND ")
            : "'";
    }
    
    function getForeignKeyVars(db:Db, table:String, vars:Array<OrmHaxeVar>) : Array<OrmHaxeVar>
    {
        var foreignKeys = db.connection.getForeignKeys(table);
        var foreignKeyVars = vars.filter(function(v)
		{
            return foreignKeys.exists(function(fk) return fk.key == v.name);
        });
        return foreignKeyVars;
    }

}