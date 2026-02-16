package
{
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	public class ExternalDataLoader
	{
		public function ExternalDataLoader()
		{
		}
		
		public static function load( main:ACSBuilder ):void
		{
			var path:String = "app:/T5ShipyardCfg/";


			var defenses:URLLoader = new URLLoader();
			defenses.addEventListener(Event.COMPLETE, main.handleDefensesLoaded);
			defenses.load( new URLRequest( path + "acs-defenses.yml") );	
				
			var drives:URLLoader = new URLLoader();
			drives.addEventListener(Event.COMPLETE, main.handleDrivesLoaded);  	
			drives.load( new URLRequest(path + "acs-drives.yml") );	
				
			var hull:URLLoader = new URLLoader();
			hull.addEventListener(Event.COMPLETE, main.handleHullsLoaded);
			hull.load( new URLRequest(path + "acs-hulls.yml" ) );	
				
			var hab:URLLoader = new URLLoader();
			hab.addEventListener(Event.COMPLETE, main.handleLivingSpaceLoaded);
			hab.load( new URLRequest(path + "acs-payload.yml" ) );   
				
			var veh:URLLoader = new URLLoader();
			veh.addEventListener(Event.COMPLETE, main.handleVehiclesLoaded);
			veh.load( new URLRequest(path + "acs-vehicles.yml" ) );   
				
			var disp:URLLoader = new URLLoader();
			disp.addEventListener(Event.COMPLETE, main.handleDispositionsLoaded);
			disp.load( new URLRequest( path + "acs-dispositions.yml" ) );
				
			var template:URLLoader = new URLLoader();
			template.addEventListener( Event.COMPLETE, main.handleTemplateLoaded );
			template.load( new URLRequest( path + "acs-ship-template.yml" ) );
				
			var stock:URLLoader = new URLLoader();
			stock.addEventListener( Event.COMPLETE, main.handleStockShipsLoaded );
			stock.load( new URLRequest( path + "acs-stock-ships.yml" ) );
		}
	}
}