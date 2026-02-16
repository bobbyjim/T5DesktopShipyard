package generators.acs
{
	public class AcsComponentFactory
	{
		public static function parseThing( thing:Object ):AcsImportable
		{
			var component:AcsImportable;
			
			var type:String = "none";
			var value:String = "none";
			
			var p1:RegExp = /^(\w+): (\w+)$/;
			var p2:RegExp = /^(\w+): (\d+)t (.*)$/;
			var p3:RegExp = /^(\w+): \((\d+)\) (\d+)t (.*)$/;
			
			for ( var prop:String in thing )
			{
				type = prop;
				value = thing[type];
			}
			
			switch( prop )
			{
				case "format": 
					component = new Unsupported( type, value ); // Format( value );
					break;
				
				case "qsp":
					component = new Hull( value );
					break;
				
				/*
				case "name":
					break;
				
				case "armor":
					break;
				
				case "bridge":
					break;
				
				case "ops":
					break;
				
				case "powerFuel":
					break;
				
				case "jumpFuel":
					break;
				
				case "drive":
					break;
				
				case "sensor":
					break;
				
				case "weapon":
					break;
				
				case "defense":
					break;
				
				case "passenger":
					break;
				
				case "crew":
					break;
				
				case "payload":
					break;
				*/
				
				default:
					component = new Unsupported( type, value );
					break;
			}
			return component;
		}
	}
}