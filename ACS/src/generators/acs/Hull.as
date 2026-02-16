package generators.acs
{
	import data.Cfg;

	public class Hull extends AcsComponent implements AcsImportable
	{
		private var mission:String  = '';
		private var tons:int        = 200;
		private var volmult:int     = 0;
		private var config:String   = 'U';
		private var maneuver:int    = 1;
		private var jump:int        = 1;
		private var tl:int          = 12;

		public function Hull(qsp:String)
		{
			super('hull', value);
			parseQSP( qsp );
		}
		
		public function parseQSP( qsp:String ):void
		{
			//qsp.
			var elements:Array = qsp.match( /^([A-Z][A-Z0-9]?)-([A-Z])(\d*)([A-Z])(\d)(\d)-(\d+)\s*$/ );
			mission  = elements[1];
			tons     = parseInt(elements[2]);
			volmult  = parseInt(elements[3]);
			config   = elements[4];
			maneuver = parseInt(elements[5]);
			jump     = parseInt(elements[6]);
			tl       = parseInt(elements[7]);
			
			trace( qsp + " parsed." );
		}
		
		/*
		
		The minimum initial ship structure is as follows:
		
		---
		header:
			format: 'T5-ACS-1'
			tons: 200
			tl: 12
			mission: 'A'
			config: 'S'
			spaciousness: 2
			shifts: 1
		
		components:
		- 	type: 'Hull', 
			category: 'Hull', 
			label: 'Streamlined hull', 
			eff: 1, 
			name: 'Hull', 
			config: 'Streamlined', 
			code: 'S', 
			mcr: 14, 
			tons: 200, 
			mult: 1
		
		- 	type: 'Payload'
			category: 'Cargo'
			label: 'Cargo Hold Basic'
			mcr: 0
			eff: 1
			tons: '20'
			notes: ''
		
		*/
		public function importIntoShip():String
		{
			var ship:Object = Cfg.getInstance().templateHull; // for overwriting
			
			Cfg.getHdr();
		//	Cfg.getInstance().componentList.addItem( hull );
			return null;
		}
	}
}