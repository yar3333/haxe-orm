package ;

class OrmTable
{
	public var tableName(default, null) : String;
	public var varName(default, null) : String;
	
	public var autogenManagerClassName(default, null) : String;
	public var customManagerClassName(default, null) : String;
	
	public var autogenModelClassName(default, null) : String;
	public var customModelClassName(default, null) : String;
	
	public function new(tableName:String, autogenPackage:String, customPackage:String)
	{
		this.tableName = tableName;
		this.varName = getVarName();
		
		var className = getClassName();
		
		this.autogenManagerClassName = autogenPackage + "." + className + "Manager";
		this.customManagerClassName = customPackage + "." + className + "Manager";
		
		this.autogenModelClassName = autogenPackage + "." + className;
		this.customModelClassName = customPackage + "." + className;
	}
	
	function getVarName() : String
	{
		var s = "";
		
		var packs = tableName.toLowerCase().split("__");
		while (packs.length > 1)
		{
			var pack = packs.shift();
			var words = pack.split("_");
			s += words.shift();
			s += Lambda.map(words, function(w) return OrmTools.capitalize(w)).join("");
			s += "_";
		}
		
		s += Lambda.mapi(packs[0].split("_"), function(n, w) return n == 0 ? w : OrmTools.capitalize(w)).join("");
		
		return s;
	}
	
	function getClassName() : String
    {
		var s = "";
		
		var packs = tableName.toLowerCase().split("__");
		while (packs.length > 1)
		{
			var pack = packs.shift();
			var words = pack.split("_");
			s += words.shift();
			s += Lambda.map(words, function(w) return OrmTools.capitalize(w)).join("");
			s += ".";
		}
		
		s += Lambda.map(packs[0].split("_"), function(w) return OrmTools.capitalize(w)).join("");
		
		return s;
    }
}