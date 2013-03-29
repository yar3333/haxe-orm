package ;

import hant.FlashDevelopProject;
import hant.PathTools;
import stdlib.Exception;
import neko.Lib;
import neko.Sys;
import hant.Log;
import orm.Db;
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
		
        if (args.length > 0)
		{
			try
			{
				var project = new FlashDevelopProject("");
				var databaseConnectionString = args[0];
				if (databaseConnectionString != null && databaseConnectionString != "")
				{
					log.start("Generate object related mapping classes");
					new OrmGenerator(log, project).generate(new Db(databaseConnectionString));
					log.finishOk();
				}
				else
				{
					fail(
						  "databaseConnectionString not found.\n"
						+ "You may specify it in the 'src/config.xml' file:\n"
						+ "\t<config>\n"
						+ "\t\t<param name=\"databaseConnectionString\" value=\"mysql://USER:PASSWORD@HOST/DATABASE\" />\n"
						+ "\t</config>\n"
						+ "or in the command line:\n"
						+ "\thaxelib run HaQuery gen-orm mysql://USER:PASSWORD@HOST/DATABASE"
					);
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
			Lib.println("Usage: haxelib run orm <databaseConnectionString>");
			Lib.println("");
			Lib.println("    where:");
			Lib.println("");
			Lib.println("        <databaseConnectionString> Like 'mysql://user:pass@host/dbname'.");
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