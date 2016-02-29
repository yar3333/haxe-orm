package orm;

private typedef Manager<T> =
{
	var table : String;
	var db : Db;
	
	function getBySqlMany(sql:String) : Array<T>;
	function getBySqlOne(sql:String) : T;
}

class SqlQuery<T>
{
	var manager : Manager<T>;
	var conditions = new Array<String>();
	
	public function new(manager:Manager<T>)
	{
		this.manager = manager;
	}
	
	public function where(field:String, op:String, value:Dynamic) : SqlQuery<T>
	{
		conditions.push(field + " " + op + " " + manager.db.quote(value));
		return this;
	}
	
	public function findMany(?limit:Int) : Array<T>
	{
		return manager.getBySqlMany(getSelectSql(null) + getLimitSql(limit));
	}
	
	public function findOne() : T
	{
		return manager.getBySqlOne(getSelectSql(null));
	}
	
	public function findManyFields<TT:{}>(fields:TT, ?limit:Int) : TypedResultSet<TT>
	{
		return cast manager.db.query(getSelectSql(fields) + getLimitSql(limit));
	}
	
	public function findOneFields<TT:{}>(fields:TT) : TT
	{
		var rr = manager.db.query(getSelectSql(fields) + "\nLIMIT 1");
		if (rr.hasNext()) return cast rr.next();
		return null;
	}
	
	public function update(fields:Dynamic, ?limit:Int) : Void
	{
		var sets = [];
		for (name in Reflect.fields(fields))
		{
			var v = Reflect.field(fields, name);
			
			if (Std.is(v, SqlValues))
			{
				switch (cast v:SqlValues)
				{
					case SqlValues.SqlExpression(s): sets.push("`" + name + "`= " + v);
				}
			}
			else
			{
				sets.push("`" + name + "`= " + manager.db.quote(v));
			}
		}
		manager.db.query("UPDATE `" + manager.table + "`\nSET\n\t" + sets.join("\n\t") + getWhereSql() + getLimitSql(limit));
	}
	
	public function delete(?limit:Int) : Void
	{
		manager.db.query("DELETE FROM `" + manager.table + "`" + getWhereSql() + getLimitSql(limit));
	}
	
	public function count() : Int
	{
		var r = manager.db.query("SELECT COUNT(*) FROM `" + manager.table + "`" + getWhereSql());
		if (!r.hasNext()) return 0;
		return r.getIntResult(0);
	}
	
	public function exists() : Bool
	{
		var r = findOneFields({ "1":Int });
		return r != null && Reflect.field(r, "1") != null;
	}
	
	function getSelectSql<TT:{}>(fields:TT) : String
	{
		var f = []; 
		
		if (fields != null)
		{
			for (name in Reflect.fields(fields)) f.push(name);
		}
		else
		{
			f.push("*");
		}
		
		return "SELECT " + f.join(", ") + "\nFROM `" + manager.table + "`" + getWhereSql();
	}
	
	function getWhereSql() : String
	{
		return conditions.length > 0 ? "\nWHERE " + conditions.join("\n\tAND ") : "";
	}
	
	function getLimitSql(limit:Int) : String
	{
		return limit != null ? "\nLIMIT " + limit : "";
	}
}