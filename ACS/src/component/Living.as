package component
{
	import data.Cfg;

	public class Living extends ComponentUtils
	{
		public function Living()
		{
			super();
		}
		
		public static function calculateCrew( obj:Object ):void			
		{
			ComponentUtils.calculateTotalsOf( 'crewSpace', obj );
			ComponentUtils.calculateTotalsOf( 'sleeps', obj );
		}
		
		public static function calculatePassengers( obj:Object ):void
		{
			ComponentUtils.calculateTotalsOf( 'passengerSpace', obj );
			ComponentUtils.calculateTotalsOf( 'sleeps', obj );
		}
		
		public static function updateLifeSupport( shipGrid:ShipGrid ):void
		{

		}
	}
}