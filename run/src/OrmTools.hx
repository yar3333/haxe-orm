import orm.DbDriver;
import HaxeClass.HaxeVar;
using stdlib.StringTools;
using stdlib.Lambda;

class OrmTools 
{
	public static function capitalize(s:String) : String
	{
		return s.length == 0 ? s : s.charAt(0).toUpperCase() + s.substr(1);
	}
	
	public static function decapitalize(s:String) : String
	{
		return s.length == 0 ? s : s.charAt(0).toLowerCase() + s.substr(1);
	}
	
	static function sqlTypeCheck(checked:String, type:String) : Bool
	{
		var re = new EReg("^" + type + "(\\(|$)", "");
		return re.match(checked);
	}
	
	public static function sqlType2haxeType(sqlType:String) : String
	{
		sqlType = sqlType.toUpperCase();
		if (sqlType == "TINYINT(1)")            return "Bool";
		if (sqlTypeCheck(sqlType, "TINYINT"))   return "Int";
		if (sqlTypeCheck(sqlType, "SMALLINT"))  return "Int";
		if (sqlTypeCheck(sqlType, "MEDIUMINT")) return "Int";
		if (sqlTypeCheck(sqlType, "SHORT"))     return "Int";
		if (sqlTypeCheck(sqlType, "LONG"))      return "Int";
		if (sqlTypeCheck(sqlType, "INT"))       return "Int";
		if (sqlTypeCheck(sqlType, "INTEGER"))   return "Int";
		if (sqlTypeCheck(sqlType, "INT24"))     return "Int";
		if (sqlTypeCheck(sqlType, "BIGINT"))    return "Float";
		if (sqlTypeCheck(sqlType, "LONGLONG"))  return "Float";
		if (sqlTypeCheck(sqlType, "DECIMAL"))   return "Float";
		if (sqlTypeCheck(sqlType, "FLOAT"))     return "Float";
		if (sqlTypeCheck(sqlType, "DOUBLE"))    return "Float";
		if (sqlTypeCheck(sqlType, "REAL"))      return "Float";
		if (sqlTypeCheck(sqlType, "DATE"))      return "Date";
		if (sqlTypeCheck(sqlType, "DATETIME"))  return "Date";
		return "String";
	}
	
	public static function createVar(haxeName:String, haxeType:String, ?haxeDefVal:String) : HaxeVar
	{
		return
		{
			 haxeName : haxeName
			,haxeType : haxeType
			,haxeDefVal : haxeDefVal
		};
	}
	
	static function field2var(table:String, f:DbTableFieldData, positions:OrmPositions) : OrmHaxeVar
	{ 
		return
		{
			 table : table
			,haxeName : f.name
			,haxeType : sqlType2haxeType(f.type)
			,haxeDefVal : positions.is({ table:table, name:f.name}) ? "null" : null
			
			,name : f.name
			,type : f.type
			,isNull : f.isNull
			,isKey : f.isKey
			,isAutoInc : f.isAutoInc
		};
	}
	
	public static function fields2vars(table:String, fields:Iterable<DbTableFieldData>, positions:OrmPositions) : Array<OrmHaxeVar>
	{
		return fields.map.fn(OrmTools.field2var(table, _, positions)).array();
	}
}