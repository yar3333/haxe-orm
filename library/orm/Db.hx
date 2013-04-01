package orm;

import stdlib.Exception;
import stdlib.Profiler;
import sys.db.ResultSet;
import orm.DbDriver_mysql;

class Db
{
	var connectionString : String;
	
    /**
     * Level of tracing SQL:
	 * 0 - show errors only;
	 * 1 - show queries;
	 * 2 - show queries and times.
     */
	public var logLevel : Int;
	
	public var profiler : Profiler;
	
	public var connection(default , null) : DbDriver;
	
    public function new(connectionString:String, ?logLevel:Int, ?profiler:Profiler) : Void
	{
		this.connectionString = connectionString;
		this.logLevel = logLevel != null ? logLevel : 0;
		this.profiler = profiler != null ? profiler : new Profiler(false);
		
		var params = new DbConectionString(connectionString);
		
		this.profiler.begin("Db.open");
		var klassName = "orm.DbDriver_" + params.type;
		var klass = Type.resolveClass(klassName);
		if (klass == null) throw new Exception("Class " + klassName + " is not found.");
		connection = Type.createInstance(klass, [ params.host, params.user, params.password, params.dbname, params.port ]);
		this.profiler.end();
		
    }

	public function query(sql:String, ?params:Dynamic) : ResultSet
    {
		try
		{
			profiler.begin('Db.query');
			if (params != null) sql = bind(sql, params);
			if (logLevel >= 1) trace("SQL QUERY: " + sql);
			var startTime = logLevel >= 2 ? Sys.time() : 0;
			var r = connection.query(sql);
			if (logLevel >= 2) trace("SQL QUERY FINISH " + Math.round((Sys.time() - startTime) * 1000) + " ms");
			profiler.end();
			return r;
		}
		catch (e:DbException)
		{
            profiler.end();
			throw new Exception("DATABASE\n\tSQL QUERY: " + sql + "\n\tSQL RESULT: error code = " + e.code + ".", e);
		}
		catch (e:Dynamic)
		{
			profiler.end();
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
}
