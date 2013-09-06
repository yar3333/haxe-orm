package ;

import hant.PathTools;
import hant.FlashDevelopProject;
import stdlib.FileSystem;
import orm.Db;
import hant.Log;
import haxe.io.Path;
import sys.io.File;
using stdlib.StringTools;

class OrmModelGenerator 
{
	var log : Log;
	var project : FlashDevelopProject;
	
	public function new(log:Log, project:FlashDevelopProject)
    {
		this.log = log;
		this.project = project;
	}
	
	public function make(db:Db, table:OrmTable, customOrmClassName:String, srcPath:String) : Void
	{
		log.start(table.tableName + " => " + table.customModelClassName);
		
		var vars = OrmTools.fields2vars(db.connection.getFields(table.tableName));
		
		var autogenModel = getAutogenModel(table.tableName, vars, table.autogenModelClassName, customOrmClassName);
		var destFileName = srcPath + table.autogenModelClassName.replace(".", "/") + ".hx";
		FileSystem.createDirectory(Path.directory(destFileName));
		File.saveContent(
			  destFileName
			, "// This is autogenerated file. Do not edit!\n\n" + autogenModel.toString()
		);
		
		if (project.findFile(table.customModelClassName.replace(".", "/") + ".hx") == null) 
		{
			var customModel = getCustomModel(table.tableName, vars, table.customModelClassName, table.autogenModelClassName, table.customManagerClassName);
			var destFileName = srcPath + table.customModelClassName.replace(".", "/") + ".hx";
			FileSystem.createDirectory(Path.directory(destFileName));
			File.saveContent(destFileName, customModel.toString());
		}
		
		log.finishOk();
	}
	
	function getAutogenModel(table:String, vars:List<OrmHaxeVar>, modelClassName:String, customOrmClassName:String) : HaxeClass
	{
		var model = new HaxeClass(modelClassName);
		
		model.addVar({ haxeName:"db", haxeType:"orm.Db", haxeDefVal:null }, true);
		model.addVar({ haxeName:"orm", haxeType:customOrmClassName, haxeDefVal:null }, true);
		
		for (v in vars)
		{
			model.addVar(v);
		}
		
		model.addMethod(
			  "new"
			, [
				  { haxeName:"db", haxeType:"orm.Db", haxeDefVal:null }
				, { haxeName:"orm", haxeType:customOrmClassName, haxeDefVal:null } 
			  ]
			, "Void"
			, "this.db = db;\nthis.orm = orm;"
		);
        
        if (Lambda.exists(vars, function(v) return v.isKey) && Lambda.exists(vars, function(v) return !v.isKey))
		{
			var settedVars = Lambda.filter(vars, function(v) return !v.isKey && !v.isAutoInc);
			if (settedVars.length > 0)
			{
				model.addMethod("set", settedVars, "Void",
					Lambda.map(settedVars, function(v) return "this." + v.haxeName + " = " + v.haxeName + ";").join("\n")
				);
			}
			
			var savedVars = Lambda.filter(vars, function(v) return !v.isKey);
			var whereVars = Lambda.filter(vars, function(v) return v.isKey);
			model.addMethod("save", new List<OrmHaxeVar>(), "Void",
				  "db.query(\n"
				    + "\t 'UPDATE `" + table + "` SET '\n"
					+ "\t\t+  '" + Lambda.map(savedVars, function(v) return "`" + v.name + "` = ' + db.quote(" + v.haxeName + ")").join("\n\t\t+', ")
					+ "\n\t+' WHERE " 
					+ Lambda.map(whereVars, function(v) return "`" + v.name + "` = ' + db.quote(" + v.haxeName + ")").join("+' AND ")
					+ "\n\t+' LIMIT 1'"
				+ "\n);"
			);
		}
		
		return model;
	}

	function getCustomModel(table:String, vars:List<OrmHaxeVar>, customModelClassName:String, autogenModelClassName:String, customManagerClassName:String) : HaxeClass
	{
		return new HaxeClass(customModelClassName, autogenModelClassName);
	}
}