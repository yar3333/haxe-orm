package orm;

import stdlib.Exception;

class DbConectionString
{
    public var type(default, null) : String;
    public var host(default, null) : String;
    public var user(default, null) : String;
    public var password(default, null) : String;
    public var port(default, null) : Int;
    public var dbname(default, null) : String;
	
    public function new(connectionString:String)
    {
		var re = new EReg('^([a-z]+)\\://([_a-zA-Z0-9]+)\\:(.+?)@([-_.a-zA-Z0-9]+)(?:[:](\\d+))?/([-_a-zA-Z0-9]+)$', '');
		if (!re.match(connectionString))
		{
			throw new Exception("Connection string invalid format.");
		}
		
		type = re.matched(1);
		host = re.matched(4);
		user = re.matched(2);
		password = re.matched(3);
		port = re.matched(5) != null && re.matched(5) != "" ? Std.parseInt(re.matched(5)) : 0;
		dbname = re.matched(6);
    }

}
