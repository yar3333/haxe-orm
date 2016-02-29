package orm;

typedef TypedResultSet<T:{}> =
{
	var length(get, null) : Int;
	var nfields(get, null) : Int;

	function hasNext() : Bool;
	function next() : T;
	function results() : List<T>;
	function getResult(n:Int) : String;
	function getIntResult(n:Int) : Int;
	function getFloatResult(n:Int) : Float;
	function getFieldsNames() : Null<Array<String>>;
}