package generators
{
	import flash.utils.Dictionary;
	
	import generators.acs.AcsComponentFactory;
	import generators.acs.AcsImportable;
	
	import org.as3yaml.YAML;
	
	public class AcsCodec
	{
		public static function encode( ship:Object ): String
		{
			return "--- # encoder not implemented\n\n";
		}

		public static function decode( text:String ): Object
		{
			var ship:Object = {};
			var elements:Object = org.as3yaml.YAML.decode( text );
			var status:String = '';
			
			for each( var thing:Object in elements )
			{
				var comp:AcsImportable = AcsComponentFactory.parseThing( thing ); 
				trace( comp.importIntoShip() );
				//status = component
			}
			return ship;
		}		
	}
}