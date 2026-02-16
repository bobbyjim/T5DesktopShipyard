package data
{
	import mx.collections.ArrayCollection;

	public class Drives
	{
		private static var instance:Drives = null;
		
		public var shipGrid:ShipGrid;		
		
		private var letters:Array 
		= ['A','B','C','D','E','F','G','H','J','K','L','M','N','P','Q','R','S','T','U','V','W','X','Y','Z'];

		public function Drives()
		{
		}
		
		public static function getDriveHelper():Drives
		{
			if ( instance == null )
				instance = new Drives();
			
			return instance;
		}
		
		public function getManeuverAndJumpDriveRating():Array
		{
			var j:int = 0;
			var m:int = 0;
			
			for each ( var obj:Object in Cfg.getInstance().componentList )
			{
				if ( obj.category == 'Maneuver Drive' )
					m = Math.max( m, obj.rating );
				
				if ( obj.category == 'Jump Drive' )
					j = Math.max( j, obj.rating );
			}
			
			return [m, j];
		}
		
		public function get components():Array
		{
			if ( Cfg.getInstance().drives != null )
				return Cfg.getInstance().drives.drives;
			else
				return []; // empty
		}
		
		private function getCoreDataOf( drive:Object ):Object
		{
			for each ( var item:Object in components )
			{
				if ( item.label == drive.category )
					return item;
			}
			return null;
		}
		
		public function handleVolumeChanged():void
		{
			if ( shipGrid == null ) return;
			
			// holy crap, the user went and changed out the volume in his ship.
			// now I have to go and recalculate the drives.
			var add:Array = [];
			var del:Array = [];
			
			for each ( var obj:Object in Cfg.getInstance().componentList )
			{
				if ( obj.hasOwnProperty( 'autoAdjust' ) )
				{
					var coreData:Object = getCoreDataOf( obj );
					if ( coreData != null )
					{
						var rating:int = obj.rating;
						
						// don't forget staging, dude.
						var stage:String = obj.stage;
						var original:Object = obj.original;
						
						del.push( obj );
						var drive:Object = getDrive( coreData, rating, stage, original );
						add.push( drive );
					}
				}
			}

			for each ( var delMe:Object in del )
				shipGrid.removeItem( delMe );
	
			for each ( var addMe:Object in add )
				shipGrid.addComponent( addMe );
				
			shipGrid.refreshShipGrid();
			
			var hdr:Object = Cfg.getHdr();

			var jf:Number = hdr.jf || 0;
			var pf:Number = hdr.pf || 0;
			
			setFuel( jf, pf );
		}
		
		/////////////////////////////////////////////////////////////////////////
		//
		//  New Drive Functions
		//
		/////////////////////////////////////////////////////////////////////////
		
		//
		// This function returns the true EP required, based on *drive* EP requirements.
		//
		private function getTrueEP( value: int ):int
		{
			var ep:int        = getEP( value );
			var mult:int      = getDriveMult( ep );
			var eachEP:int    = Math.ceil( ep/mult );
			var index:int     = Math.ceil( eachEP/100 ) - 1;
			
			//
			//  Once we know the drive index and multiplier, we know the true EPs required.
			//
			var EP:int        = (index+1) * 100 * mult;
			
			return EP;
		}
		
		//
		//  Warning: this is only an estimate for multiple drive calculations!
		//
		private function getEP( value:int ):int
		{
			var tons:int = Cfg.getHdr().tons;
			var EP:int = Math.ceil( value * tons / 200 ) * 100;
			if ( EP > 2400 )
				EP = Math.ceil( EP/200 ) * 200;
			
			return EP;
		}
		
		private function getDriveMult( EP:int ):int
		{
			return 1+int( (EP-1) / 2400 );				
		}
		
		private function getDriveLetter( EP:int ):String
		{
			var mult:int = getDriveMult( EP );
			var eachEP:int = Math.ceil( EP/mult );
			var index:int  = Math.ceil( eachEP/100 )-1;
			var letter:String = letters[ Math.ceil(index) ];
			
			if ( mult > 1 )
				return letter + mult;
			else
				return letter; // single drive
		}
		
		private function getDriveTons( tonsPerEP:String, EP:int, minTons:int ):Number
		{
			var equation:Array = tonsPerEP.split( '+' );
			var sPercent:String = equation[0].toString().replace( '%', '' );
			var percent:Number  = parseFloat(sPercent) / 100;
			var constant:Number = parseFloat(equation[1]);
			
			var mult:int = getDriveMult( EP ); // this was commented out
			var tons:Number = (constant * mult + EP * percent); // was: (constant + EP * percent);
			tons = Math.max( tons, minTons );
			
			return tons;
		}
		
		private function getDriveNote( rating:int, prefix:String, suffix:String ):String
		{
			var note:String = prefix;
			
			if ( note == null ) 
				note = '' + rating;
			else
				note += ' ' + rating;
			
			if ( suffix != null )
				note += ' ' + suffix;
			
			return note;
		}
		
		private function findBaseTL( base:int, dat:Array, r:int ):int
		{
			for( var i:int=0; i<dat.length; i++ )
			{
				if ( dat[i] < r ) 
					base++;
			}
			
			return base;
		}
		
		public function getDrive( coreData:Object, value:int, stage:String=null, original:Object=null ):Object
		{
			var EP:int = getTrueEP( value ); // getEP( value );
			var letter:String = getDriveLetter( EP );
			
			var tons:Number = getDriveTons( coreData[ 'tons by EP' ], EP, coreData[ 'min' ] );
			var mcr:Number = tons * coreData[ 'mcr' ];
			var actualValue:Number = value;
			
			if ( coreData.hasOwnProperty( 'rating multiplier' ) )
			{
				actualValue *= coreData[ 'rating multiplier' ];
			}
			var note:String = getDriveNote( actualValue, coreData.prefix, coreData.suffix );
			
			var basetl:int = findBaseTL( coreData[ 'tl' ], coreData[ 'ratingFromTL' ], value );
			var tl:int = basetl;
			
			//
			//  Now adjust upwards based on ship's TL.
			//
			var hdr:Object = Cfg.getHdr();
			if ( tl < hdr.tl )
				tl = hdr.tl;
			
			var drive:Object = 
				{
					type: 'Drive',
					code: letter,
					autoAdjust: 1,
					category: coreData.label,
					basetl: basetl,
					tl: tl,
					label: coreData.label + '-' + value + ' (' + letter + ')',
					name: coreData.label,
					tons: tons,
					mcr: mcr,
					rating: value,
					notes: note,
					CP: Math.ceil( tons / 35 ),
					Q: 0,
					R: 0,
					E: 0,
					B: 0,
					S: 0,
					Sq: tons * 2
				};

			if ( coreData.hasOwnProperty( 'jumpFuelUsage' ) )
				drive.jumpFuelUsage = coreData.jumpFuelUsage;
			
			if ( coreData.hasOwnProperty( 'powerFuelUsage' ) )
				drive.powerFuelUsage = coreData.powerFuelUsage;
			
			//
			//  Now apply stage, if relevant
			//
			if ( stage != null && stage != '' && stage != 'Std' )
			{
				drive.original = original;
				drive = Stages.setStage( drive, stage );
			}
			

			return drive;
		}
		
		//////////////////////////////////////////////////////////////////
		//
		//  Fuel
		//
		//////////////////////////////////////////////////////////////////
		public function setFuel( jf:Number, pf:Number ):void
		{
			setJumpFuel( jf );
			setPowerFuel( pf );
		}
		
		public function setJumpFuel( jf:Number ):void
		{
			var hdr:Object = Cfg.getHdr();
			var parsecs:int = jf;
			hdr.jf = parsecs;
			
			var jumpPercentage:Number = hdr.jumpFuelPercentage * jf;
			var value:Number = jumpPercentage;
			
			var tons:int = hdr.tons * value;
			var tonsPerJump:int = hdr.jumpFuelPercentage * hdr.tons;
			
			var fuel:Object = Cfg.getInstance().find( 'Jump Fuel' );
			var newfuel:Boolean = fuel == null;
				
			if ( newfuel )
				fuel = {};
			
			var distlabel:String = ' parsec';
			if ( parsecs > 1 ) distlabel += 's';
						
			fuel.type = 'Drive';
			fuel.category = 'Jump Fuel';
			fuel.label = 'Jump Fuel (' + parsecs + ' ' + distlabel + ')';
			fuel.tons = tons;
			fuel.notes = parsecs + ' parsec jump, at ' + tonsPerJump + 't per parsec';
			fuel.CP = 0;
			
			if ( newfuel && shipGrid != null )
				shipGrid.addComponent( fuel );
			
			if ( shipGrid != null )
				shipGrid.refreshShipGrid();
		}
		
		public function setPowerFuel( pf:Number ):void
		{
			var hdr:Object = Cfg.getHdr();
			var months:Number  = pf;			
			hdr.pf = months;
			
			var powerPercentage:Number = hdr.powerFuelPercentage * pf;
			var value:Number = powerPercentage;
			
			var tons:Number = int(hdr.tons * value * 10)/10;
			var tonsPerMonth:int = hdr.powerFuelPercentage * hdr.tons;
			
			var fuel:Object = Cfg.getInstance().find( 'Powerplant Fuel' );
			var newfuel:Boolean = fuel == null;
			
			if ( newfuel )
				fuel = {};
			
			var label:String = months + ' months';
			if ( months == 1 )
				label = 'one month';
			
			fuel.type = 'Drive';
			fuel.category = 'Powerplant Fuel';
			fuel.label = 'Plant Fuel (' + label + ')';
			fuel.tons = tons;
			fuel.notes = label;
			fuel.CP = 0;
			
			if ( newfuel && shipGrid != null )
				shipGrid.addComponent( fuel );
			
			if ( shipGrid != null )
				shipGrid.refreshShipGrid();
		}
		
	}
}