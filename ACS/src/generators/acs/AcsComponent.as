package generators.acs
{
	public class AcsComponent
	{
		public var type:String = 'none';
		public var value:String = 'none';
			
		public function AcsComponent( type:String, value:String )
		{
			this.type = type;
			this.value = value;
		}
				
/*		public function thisType( thing:Object ):Boolean
		{
			return thing.hasOwnProperty( type );
		}
*/	}
}