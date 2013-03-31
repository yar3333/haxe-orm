package ;

import hant.FlashDevelopProject;
import hant.PathTools;
import stdlib.Exception;
import neko.Lib;
import neko.Sys;
import hant.Log;
import orm.Db;
import hant.CmdOptions;
using StringTools;

class Main 
{
	static function main()
	{
		var exeDir = PathTools.path2normal(Sys.getCwd());
        
		var args = Sys.args();
		if (args.length > 0)
		{
			Sys.setCwd(args.pop());
		}
		else
		{
			fail("run this program via haxelib utility.");
		}
		
		var log = new Log(2);
		
		var options = new CmdOptions();
		options.add("databaseConnectionString", "", null, "Database connecting string like 'mysql://user:pass@localhost/mydb'.");
		options.add("hxproj", "", [ "--fd-haxe-project", "-hxproj" ], "Path to the FlashDevelop *.hxproj file.\nUsed to detect class paths.\nIf not specified then *.hxproj from the current folder will be used.");
		options.add("autogenPackage", "models.server.autogenerated", [ "--autogenerated-package", "-a" ], "Package name for autogenerated classes.\nDefault is 'models.server.autogenerated'.");
		options.add("customPackage", "models.server", [ "--custom-package", "-c" ], "Package name for your custom classes.\nDefault is 'models.server'.");
		options.parse(args);
        
		if (args.length > 0)
		{
			try
			{
				var project = new FlashDevelopProject(options.get("hxproj"));
				var databaseConnectionString = options.get("databaseConnectionString");
				if (databaseConnectionString != "")
				{
					log.start("Generate object related mapping classes");
					new OrmGenerator(log, project).generate(new Db(databaseConnectionString), options.get("autogenPackage"), options.get("customPackage"));
					log.finishOk();
				}
				else
				{
					fail("Database connection string must be specified.");
				}
					
			}
			catch (e:Exception)
			{
				log.trace(e.message);
				fail();
			}
        }
		else
		{
			
			Lib.println("Generating set of the haxe classes from database tables.");
			Lib.println("\nUsage:\n\thaxelib run orm <databaseConnectionString> [options]");
			Lib.println("\nOptions:\n");
			Lib.println(options.getHelpMessage());
		}
        
        Sys.exit(0);
	}
	
	static function fail(?message:String)
	{
		if (message != null)
		{
			Lib.println("ERROR: " + message);
		}
		Sys.exit(1);
	}
}