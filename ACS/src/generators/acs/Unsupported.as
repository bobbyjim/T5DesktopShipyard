package generators.acs
{
	public class Unsupported extends AcsComponent implements AcsImportable
	{
		public function Unsupported(type: String, value:String)
		{
			super(type, value);
		}
		
		public function importIntoShip():String
		{
			return "Unsupported item or format - not imported. [" + type + ": " + value + "]";
		}
	}
}