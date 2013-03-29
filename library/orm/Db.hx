package orm;

import stdlib.Exception;
import stdlib.Profiler;
import sys.db.ResultSet;
import orm.DbDriver_mysql;

class Db
{
	static var pool = new Hash<DbDriver>();
	
	var connectionString : String;
	
	public var connection(default ,null) : DbDriver = null;
	
    /**
     * Level of tracing SQL:
	 * 0 - show errors only;
	 * 1 - show queries;
	 * 2 - show queries and times.
     */
	public var logLevel : Int;
	
	public var profiler : Profiler = null;
	
	public var orm : models.server.Orm; 
	
    public function new(connectionString:String, logLevel=0, ?profiler:Profiler) : Void
	{
		this.connectionString = connectionString;
		
		var params = new DbConectionString(connectionString);
		
		if (profiler != null) profiler.begin("Db.open");
		var klassName = "orm.DbDriver_" + params.type;
		var klass = Type.resolveClass(klassName);
		if (klass == null) throw new Exception("Class " + klassName + " is not found.");
		connection = Type.createInstance(klass, [ params.host, params.user, params.password, params.dbname, params.port ]);
		if (profiler != null) profiler.end();
		
		this.logLevel = logLevel;
		this.profiler = profiler;
		
		this.orm = new models.server.Orm(this);
    }

	public function query(sql:String, ?params:Dynamic) : ResultSet
    {
		try
		{
			if (profiler != null) profiler.begin('Db.query');
			if (params != null) sql = bind(sql, params);
			if (logLevel >= 1) trace("SQL QUERY: " + sql);
			var startTime = logLevel >= 2 ? Sys.time() : 0;
			var r = connection.query(sql);
			if (logLevel >= 2) trace("SQL QUERY FINISH " + Math.round((Sys.time() - startTime) * 1000) + " ms");
			if (profiler != null) profiler.end();
			return r;
		}
		catch (e:DbException)
		{
            if (profiler != null) profiler.end();
			throw new Exception("DATABASE\n\tSQL QUERY: " + sql + "\n\tSQL RESULT: error code = " + e.code + ".", e);
		}
		catch (e:Dynamic)
		{
			if (profiler != null) profiler.end();
			Exception.rethrow(e);
			return null;
		}
    }

    public function quote(v:Dynamic) : String
    {
		return connection.quote(v);
    }

    public function lastInsertId() : Int
    {
        return connection.lastInsertId();
    }
	
	public function close() : Void
	{
		try connection.close() catch (e:Dynamic) {}
		connection = null;
	}
	
	public function bind(sql:String, params:Dynamic) : String
	{
		return new EReg("[{]([_a-zA-Z][_a-zA-Z0-9]*)[}]", "").customReplace(sql, function(re) 
		{
			var name = re.matched(1);
			if (Reflect.hasField(params, name))
			{
				return quote(Reflect.field(params, name));
			}
			throw "Param '" + name + "' not found while binding sql query '" + sql + "'.";
		});
	}
	
	public function makePooled()
	{
		if (!pool.exists(connectionString))
		{
			pool.set(connectionString, connection);
		}
		else
		{
			try connection.close() catch (e:Dynamic) {}
			connection = pool.get(connectionString);	
		}
	}
}
