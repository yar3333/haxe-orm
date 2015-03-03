package orm;

import Type;
import sys.db.Connection;
import sys.db.Mysql;
import sys.db.ResultSet;
import stdlib.Exception;
import orm.DbDriver;

class DbDriver_mysql implements DbDriver
{
	static inline var renewTimeoutSeconds = 120;
	
	var host : String;
	var user : String;
	var pass : String;
	var database : String;
	var port : Int;
	
	var connection : Connection;
	
	var lastAccessTime = 0.0;
	
	public function new(dbparams:String) : Void
    {
		var re = new EReg('^([_a-zA-Z0-9]+)\\:(.+?)@([-_.a-zA-Z0-9]+)(?:[:](\\d+))?/([-_a-zA-Z0-9]+)$', '');
		if (!re.match(dbparams))
		{
			throw new Exception("Connection string invalid format.");
		}
		
		this.host = re.matched(3);
		this.user = re.matched(1);
		this.pass = re.matched(2);
		this.database = re.matched(5);
		this.port = re.matched(4) != null && re.matched(4) != "" ? Std.parseInt(re.matched(4)) : 0;
		
		renew();
    }
	
	function renew()
	{
		if (Date.now().getTime() - lastAccessTime > renewTimeoutSeconds * 1000)
		{
			if (connection != null)
			{
				try
				{
					connection.request("SELECT 0");
				}
				catch (_:Dynamic)
				{
					close();
				}
			}
			
			if (connection == null)
			{
				connection = Mysql.connect( { host:host, user:user, pass:pass, database:database, port:port != 0 ? port : 3306, socket:null } );
				connection.request("set names utf8");
				connection.request("set character_set_client='utf8'");
				connection.request("set character_set_results='utf8'");
				connection.request("set collation_connection='utf8_general_ci'");
			}
		}
		
		lastAccessTime = Date.now().getTime();
	}

    public function query(sql:String) : ResultSet
    {
		renew();
		
		#if php
		var r = connection.request(sql);
		var errno : Dynamic = untyped __call__("mysql_errno");
		if (errno != 0 && errno != false)
		{
			throw new DbException(errno, untyped __call__("mysql_error"));
		}
		return r;
		#else
		var r = null;
		var errno = 0;
		var errormsg = "";
		try { r = connection.request(sql); }
		catch (e:Dynamic)
		{
			throw new DbException(1, Std.string(e));
		}
		return r;
		#end
    }
	
	public function close() : Void
	{
		try { connection.close(); } catch (_:Dynamic) { }
		connection = null;
	}
	
    public function getTables() : Array<String>
    {
        var r : Array<String> = [];
        var rows = query("SHOW TABLES FROM `" + database + "`");
        for (row in rows)
        {
			var fields = Reflect.fields(row);
			r.push(Reflect.field(row, fields[0]));
		}
        return r;
    }

	
	public function getFields(table:String) : Array<DbTableFieldData>
    {
        var r = new Array<DbTableFieldData>();
        var rows = query("SHOW COLUMNS FROM `" + table + "`");
        for (row in rows)
        {
			var fields = Reflect.fields(row);
			r.push({
                 name : row.Field
                ,type : Reflect.field(row, "Type")
                ,isNull : Reflect.field(row, "Null") == "YES"
                ,isKey : row.Key == "PRI"
                ,isAutoInc : row.Extra == "auto_increment"
			});
        }
        return r;
    }

    public function quote(v:Dynamic) : String
    {
		switch (Type.typeof(v))
        {
            case ValueType.TClass(cls):
                if (Std.is(v, String))
                {
					return connection.quote(v);
                }
                else
                if (Std.is(v, Date))
                {
                    var date : Date = cast(v, Date);
                    return "'" + date.toString() + "'";
                }
            
            case ValueType.TInt:
                return Std.string(v);
            
            case ValueType.TFloat:
                return Std.string(v);
            
            case ValueType.TNull:
                return "NULL";
            
            case ValueType.TBool:
                return cast(v, Bool) ? "1" : "0";
            
            default:
        }
        
        throw new Exception("Unsupported parameter type '" + Type.getClassName(Type.getClass(v)) + "'.");
    }

    public function lastInsertId() : Int
    {
		return connection.lastInsertId();
    }
	
	public function getForeignKeys(table:String) : Array<DbTableForeignKey>
    {
        var sql = "
  SELECT
   u.table_name AS 'table',
   u.column_name AS 'key',
   u.referenced_table_name AS 'parentTable',
   u.referenced_column_name AS 'parentKey'
  FROM information_schema.table_constraints AS c
  INNER JOIN information_schema.key_column_usage AS u
  USING( constraint_schema, constraint_name )
  WHERE c.constraint_type = 'FOREIGN KEY'
    AND c.table_schema = '" + database + "'
    AND u.table_name = '" + table + "';
";
		return Lambda.array(query(sql).results());
    }
	
	public function getUniques(table:String) : Array<Array<String>>
	{
		var rows : ResultSet = query("SHOW INDEX FROM `" + table + "` WHERE Non_unique=0 AND Key_name<>'PRIMARY'");
		var r = new Map<String,Array<String>>();
		for (row in rows)
		{
			var key = row.Key_name;
            if (!r.exists(key))
            {
                r.set(key, []);
            }
            r.get(key).push(row.Column_name);
		}
		return Lambda.array(r);
	}
}
