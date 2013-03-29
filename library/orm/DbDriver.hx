package orm;

import sys.db.Connection;
import sys.db.ResultSet;

typedef HaqDbTableFieldData = {
	var name : String;
	var type : String;
	var isNull : Bool;
	var isKey : Bool;
	var isAutoInc : Bool;
}

typedef HaqDbTableForeignKey = {
   var schema : String;
   var table : String;
   var key : String;
   var parentSchema : String;
   var parentTable : String;
   var parentKey : String;
}

interface DbDriver 
{
	function query(sql:String) : ResultSet;
    function quote(s:Dynamic) : String;
    function lastInsertId() : Int;
	function close() : Void;
    
	function getTables() : Array<String>;
    function getFields(table:String) : Array<HaqDbTableFieldData>;
	function getForeignKeys(table:String) : Array<HaqDbTableForeignKey>;
	function getUniques(table:String) : Hash<Array<String>>;
}
