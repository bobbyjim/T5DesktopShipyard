package generators.acs
{
	import data.Cfg;

	public class Format extends AcsComponent implements AcsImportable
	{
		public function Format(value:String)
		{
			super( 'format', value );
		}		
		
		public function importIntoShip():String
		{
			Cfg.getHdr().format = this.value;
			return "ACS set header: " + this.value;
		}		
	}
}