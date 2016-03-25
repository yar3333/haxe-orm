class OrmPositions
{
	var names : Array<String>;
	
	public function new(names:Array<String>) 
	{
		this.names = names;
	}
	
	public function is(v:{ table:String, name:String })
	{
		return names.indexOf(v.table + "." + v.name) >= 0
		    || names.indexOf("*." + v.name) >= 0
			|| names.indexOf(v.name) >= 0;
	}
}