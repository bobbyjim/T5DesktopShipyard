package data
{
	public class Stages
	{
		public function Stages()
		{
		}
		
		public static function setStage( thingy:Object, code:String ):Object
		{
			var stage:Object = Cfg.getInstance().drives.stage[ code ];
			var original:Object = {};
						
			if ( thingy.hasOwnProperty( 'original' ) == false )
			{
				thingy = checkCodes( thingy, ['mod', 'q','r','e','b','s','eff'] );
				
				thingy.original =
					{
						tl: thingy.tl,
						basetl: thingy.basetl,
						mcr: thingy.mcr,
						tons: thingy.tons,
						label: thingy.label,
						mod: thingy.mod,
						q: thingy.q,
						r: thingy.r,
						e: thingy.e,
						b: thingy.b,
						s: thingy.s,
						eff: thingy.eff
					};
			}
			original = thingy.original;
			
			thingy.tl  = original.tl - stage[ 'tl' ];
			
			//
			//  Include stage[ 'fuel' ] here ONLY IF you're not incorporating efficiency ('eff') in ShipGrid.
			//
			thingy.jumpFuelUsage = original.jumpFuelUsage; // * stage[ 'fuel' ];
			thingy.powerFuelUsage = original.powerFuelUsage; // * stage[ 'fuel' ];
			
			
			thingy.eff = stage[ 'efficiency' ];
			thingy.mcr = original.mcr * stage[ 'cost mult' ];
			thingy.tons = original.tons * stage[ 'tons mult' ];
			thingy.label = code + ' ' + original.label;
			thingy.stage = code;
			
			if ( code == 'Std' ) thingy.label = original.label;
			
			if ( stage.hasOwnProperty( 'mod mult' ) )
				thingy.mod = -original.tl * stage[ 'mod mult' ] ;
			else
				thingy.mod = stage[ 'mod' ];
			
			return thingy;
		}
		
		public static function setQuality( newthingy:Object, code:String ):void
		{
			var stage:Object = Cfg.getInstance().drives.stage[ code ];
			var q:String = stage[ 'q' ];
			// q can be 'no' (=0), 'flux', or a number representing a single mod applied to all qualities
			
			newthingy.q 
				= newthingy.r
				= newthingy.e
				= newthingy.b
				= newthingy.s = 0;
			
			var dm:int = 0;
			switch( q )
			{
				case '-5':
				case '-4':
				case '-3':
				case '-2':
				case '-1':
				case '0':
				case '1':
				case '2':
				case '3':
				case '4':
				case '5':
					dm = parseInt( q );
				case 'flux': 
					qrebs( dm, dm, dm, -dm, dm );	
			}
			
			//  newThingyList.refresh();
		}

		private static function checkCodes( obj:Object, codes:Array ):Object
		{
			for each (var code:String in codes )
			if ( obj.hasOwnProperty( code ) == false )
				obj[ code ] = 0;
			
			return obj;
		}

		private static function qrebs( newthingy:Object, qm:int=0, rm:int=0, em:int=0, bm:int=0, sm:int=0):void
		{
			newthingy.q	= flux(qm) + 5; // i.e. 0 to 10
			newthingy.r	= flux(rm);
			newthingy.e	= flux(em);
			newthingy.b = flux(bm);
			newthingy.s = flux(sm);				
		}
		
		private static function flux( dm:int=0 ):int
		{
			var num:int = Math.random()*6 - Math.random()*6 + dm;
			if ( num < -5 ) return -5;
			if ( num >  5 ) return 5;
			return num;
		}	
	}
}