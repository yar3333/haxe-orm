package orm;

private typedef Manager<T> =
{
	var table : String;
	var db : Db;
	
	function getBySqlMany(sql:String) : Array<T>;
	function getBySqlOne(sql:String) : T;
}

class SqlSelectQuery<T>
{
	var manager : Manager<T>;
	var conditions = new Array<String>();
	
	public function new(manager:Manager<T>)
	{
		this.manager = manager;
	}
	
	public function where(field:String, op:String, value:Dynamic) : SqlSelectQuery<T>
	{
		conditions.push(field + " " + op + " " + manager.db.quote(value));
		return this;
	}
	
	public function findMany() : Array<T>
	{
		return manager.getBySqlMany(getSQL(null));
	}
	
	public function findOne() : T
	{
		return manager.getBySqlOne(getSQL(null));
	}
	
	public function findManyFields<TT:{}>(fields:TT) : TypedResultSet<TT>
	{
		return cast manager.db.query(getSQL(fields));
	}
	
	public function findOneFields<TT:{}>(fields:TT) : TT
	{
		var rr = manager.db.query(getSQL(fields) + "\nLIMIT 1");
		if (rr.hasNext()) return cast rr.next();
		return null;
	}
	
	function getSQL<TT:{}>(fields:TT) : String
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
		
		return "SELECT " + f.join(", ") + "\nFROM `" + manager.table + "`"
		     + (conditions.length > 0 ? "\nWHERE " + conditions.join("\n\tAND ") : "");
	}
}