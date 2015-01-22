import hant.FlashDevelopProject;
import hant.PathTools;
import stdlib.Exception;
import neko.Lib;
import hant.Log;
import orm.Db;
import hant.CmdOptions;
using StringTools;

class Main 
{
	static function main()
	{
		var exeDir = PathTools.normalize(Sys.getCwd());
        
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
		options.add("hxproj", "", [ "-p", "--hxproj" ], "Path to the FlashDevelop *.hxproj file.\nUsed to detect class paths.\nIf not specified then *.hxproj from the current folder will be used.");
		options.add("autogenPackage", "models.autogenerated", [ "-a", "--autogenerated-package" ], "Package name for autogenerated classes.\nDefault is 'models.autogenerated'.");
		options.add("customPackage", "models", [ "-c", "--custom-package" ], "Package name for your custom classes.\nDefault is 'models'.");
		options.add("srcPath", "", [ "-s", "--src-path" ], "Path to your source files directory.\nThis is a base path for generated files.\nRead last src path from the project file if not specified.");
		options.parse(args);
        
		if (args.length > 0)
		{
			try
			{
				var project = FlashDevelopProject.load(options.get("hxproj"));
				var databaseConnectionString = options.get("databaseConnectionString");
				if (databaseConnectionString != "")
				{
					Log.start("Generate object related mapping classes");
					new OrmGenerator(project, options.get("srcPath")).generate(new Db(databaseConnectionString), options.get("autogenPackage"), options.get("customPackage"));
					Log.finishSuccess();
				}
				else
				{
					fail("Database connection string must be specified.");
				}
					
			}
			catch (e:Exception)
			{
				Log.echo(e.message);
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