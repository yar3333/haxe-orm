package orm;

import stdlib.Exception;

class DbException extends Exception
{
	public var code(default, null) : Int;
	
	public function new(code:Int, message:String) 
	{
		super(message);
		this.code = code;
	}
}