package orm;

import sys.db.ResultSet;

typedef DbTableFieldData = {
	var name : String;
	var type : String;
	var isNull : Bool;
	var isKey : Bool;
	var isAutoInc : Bool;
}

typedef DbTableForeignKey = {
   var key : String;
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
    function getFields(table:String) : Array<DbTableFieldData>;
	function getForeignKeys(table:String) : Array<DbTableForeignKey>;
	function getUniques(table:String) : Array<Array<String>>;
}
