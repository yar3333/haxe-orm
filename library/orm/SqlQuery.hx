package orm;

private typedef Manager<T> =
{
	function getBySqlMany(sql:String) : Array<T>;
	function getBySqlOne(sql:String) : T;
}

class SqlQuery<T>
{
	var table : String;
	var db : Db;
	var manager : Manager<T>;
	
	var conditions = new Array<String>();
	var orderBys = new Array<String>();
	
	public function new(table:String, db:Db, manager:Manager<T>)
	{
		this.table = table;
		this.db = db;
		this.manager = manager;
	}
	
	public function where(field:String, op:String, value:Dynamic) : SqlQuery<T>
	{
		conditions.push(field + " " + op + " " + quoteValue(value));
		return this;
	}
	
	public function orderAsc(value:Dynamic) : SqlQuery<T>
	{
		orderBys.push(quoteValue(value));
		return this;
	}
	
	public function orderDesc(value:Dynamic) : SqlQuery<T>
	{
		orderBys.push(quoteValue(value) + " DESC");
		return this;
	}
	
	public function findMany(?limit:Int,?offset) : Array<T>
	{
		return manager.getBySqlMany(getSelectSql(null) + getLimitSql(limit));
	}
	
	public function findOne() : T
	{
		return manager.getBySqlOne(getSelectSql(null));
	}
	
	public function findManyFields<TT:{}>(fields:TT, ?limit:Int, ?offset:Int) : TypedResultSet<TT>
	{
		return cast db.query(getSelectSql(fields) + getLimitSql(limit) + getOffsetSql(offset));
	}
	
	public function findOneFields<TT:{}>(fields:TT) : TT
	{
		var rr = db.query(getSelectSql(fields) + "\nLIMIT 1");
		if (rr.hasNext()) return cast rr.next();
		return null;
	}
	
	public function update(fields:Map<String, Dynamic>, ?limit:Int, ?offset:Int) : Void
	{
		var sets = [];
		for (name in fields.keys())
		{
			sets.push("`" + name + "` = " + quoteValue(fields.get(name)));
		}
		db.query("UPDATE `" + table + "`\nSET\n\t" + sets.join("\n\t") + getWhereSql() + getLimitSql(limit));
	}
	
	public function delete(?limit:Int, ?offset:Int) : Void
	{
		db.query("DELETE FROM `" + table + "`" + getWhereSql() + getLimitSql(limit) + getOffsetSql(offset));
	}
	
	public function count() : Int
	{
		var r = db.query("SELECT COUNT(*) FROM `" + table + "`" + getWhereSql());
		if (!r.hasNext()) return 0;
		return r.getIntResult(0);
	}
	
	public function exists() : Bool
	{
		return findOneFields({ "1":"" }) != null;
	}
	
	function getSelectSql<TT:{}>(fields:TT) : String
	{
		var f = []; 
		
		if (fields != null)
		{
			for (name in Reflect.fields(fields)) f.push("`" + name + "`");
		}
		else
		{
			f.push("*");
		}
		
		return "SELECT " + f.join(", ") + "\nFROM `" + table + "`" + getWhereSql() + getOrderBySql();
	}
	
	function getWhereSql() : String
	{
		return conditions.length > 0 ? "\nWHERE " + conditions.join("\n\tAND ") : "";
	}
	
	function getOrderBySql() : String
	{
		return orderBys.length > 0 ? "\nORDER BY " + orderBys.join(", ") : "";
	}
	
	function getLimitSql(limit:Int) : String
	{
		return limit != null ? "\nLIMIT " + limit : "";
	}
	function getOffsetSql(offset:Int) : String
	{
		return offset != null ? "\nOFFSET " + offset : "";
	}
	function quoteValue(v:Dynamic) : String
	{
		if (Std.is(v, SqlValues))
		{
			switch (cast v:SqlValues)
			{
				case SqlValues.SqlExpression(s): return s;
				case SqlValues.SqlField(s): return "`" + s + "`";
			}
		}
		
		#if php
		if (untyped __call__("is_array", v)) v = php.Lib.toHaxeArray(v);
		#end
		
		if (Std.is(v, Array))
		{
			return "(" + (cast v:Array<Dynamic>).map(db.quote).join(", ") + ")";
		}
		
		return db.quote(v);
	}
}