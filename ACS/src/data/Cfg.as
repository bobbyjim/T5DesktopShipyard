package data
{
	import component.ComponentUtils;
	import component.Living;
	
	import flash.utils.Dictionary;
	
	import flashx.textLayout.tlf_internal;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.mx_internal;
	import mx.utils.ObjectUtil;

	[Bindable]
	public dynamic class Cfg
	{
		private static var instance:Cfg;

		public static var FORMAT:String = 'T5-ACS-1';
		
		public var header:Object = null;
		public var componentList:ArrayCollection = new ArrayCollection();
		public static var stockShips:ArrayCollection = new ArrayCollection();
		
		public var defenses:Object;
		public var drives:Object;
		public var hulls:Object;
		public var payload:Object;
		public var vehicles:Object;
		public var dispositions:Object;
		
		public var templateHull:Object;
		
		public function Cfg()
		{
		}
		
		//
		// Performs a shallow copy of an object.
		//
		public static function copy( src:Object ):Object
		{
			var copy:Object = {};
			for( var key:Object in src ) 
			{
				if (  ( 'mx_internal_uid' != key ) ) 
				{     
					copy[ key ] = src[ key ];
				}
			}
			return copy;
		}
		
		public static function getInstance():Cfg
		{
			if ( instance == null )
				instance = new Cfg();
			
			return instance;
		}

		public static function getHdr():Object
		{
			var hdr:Object = getInstance().header;
			if ( hdr == null )
			{				
				var obj:Object = instance.templateHull;
				hdr = obj[ 'header' ];
				instance.header = hdr; 
				for each ( var item:Object in obj[ 'components' ] )
					instance.componentList.addItem( item );					
			}
			
			return hdr;
		}
		
		public static function cloneHdr():Object
		{
			var hdr:Object = getInstance().header;
			var clone:Object = {};
			
			for ( var key:Object in hdr )
			{
				clone[ key ] = hdr[ key ];
			}
			
			return clone;
		}

		private var hexmap:Array =
			[ '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','G','H','J','K','L','M','N','P','Q','R','S','T','U','V','W','X','Y','Z'];

		public function toHex( value:int ):String
		{
			return hexmap[ value ];
		}
		
		//
		// Makes sure item has QREBS, Sq, tl, and CP
		// Also makes sure the price only has one decimal place.
		// And figure out living space.
		//
		public function sanitize( item:Object ):void
		{
			if ( item == null ) return;
			
			if ( item.hasOwnProperty( 'q' ) == false ) // no QREBS
			{
				item.q = item.r = item.e = item.b = item.s = 0;
			}
			
			if ( item.hasOwnProperty( 'CP' ) == false )
				item[ 'CP' ] = 0;
			
			if ( item.hasOwnProperty( 'tl' ) == false )
				item[ 'tl' ] = Cfg.getHdr().tl;
			
			Living.calculateCrew( item );
			Living.calculatePassengers( item );
		
			ComponentUtils.calculateTN( item );
			ComponentUtils.calculateTotals( item );

			if ( item.tons > 0 )
				item[ 'Sq' ] = item[ 'totalTons' ] * 2;
		}
		
		/**
		 * 
		 * Finds and sanitizes appropriate ship data.
		 * 
		 * */
		public function grepByType( type:String ):Array
		{			
			var out:Array = [];
			for each ( var item:Object in componentList.source )
			{
				if ( item[ 'type' ] == type )
				{
					sanitize( item );
					out.push( item );
				}
			}
			return out;
		}
		
		public function grepByCategory( cat:String ):Array
		{
			var out:Array = [];
			for each (var item:Object in componentList.source )
			{
				if ( item[ 'category' ] == cat )
				{
					//sanitize( item );
					out.push( item );
				}
			}
			return out;
		}

		/**
		 * 
		 * Generalized grepper from a provided array
		 * 
		 * 
		 * */
		public function grepArrayByType( list:Array, type:String ):Array
		{			
			var out:Array = [];
			for each ( var item:Object in list )
			{
				if ( item[ 'type' ] == type )
				{
					sanitize( item );
					out.push( item );
				}
			}
			return out;
		}

		public function grep( list:Array, attr:String, value:String ):Array
		{			
			var out:Array = [];
			for each ( var item:Object in list )
			{
				if ( item[ attr ] == value )
				{
					sanitize( item );
					out.push( item );
				}
			}
			return out;
		}

		
		public function sum( type: String, field: String=null ):Number
		{
			var sum:Number = 0;
			var things:Array = grepByType( type );
			for each ( var item:Object in things )
			{
				if ( field == null )
					sum++;
				else
					if ( item.hasOwnProperty( field ) )
						sum += item[ field ];
			}
			return sum;
		}
		
		public function getNumValue( category:String, field:String ):Number
		{
			var found:Object = find( category );
			if ( found == null )
				return 0;
			else
				return Number(found[ field ]);			
		}
		
		public function getIntValue( category:String, field:String ):int
		{
			return int(getNumValue( category, field ));
		}
		
		public function getValue( category:String, field:String ):String
		{
			var found:Object = find( category );
			if ( found == null )
				return '';
			else
				return found[ field ];
		}
		
		public function find( category:String ):Object
		{
			for each (var item:Object in this.componentList )
			{
				if ( item[ 'category' ] == category )
				{
					return item;
				}
			}
			return null;
		}
		
		private function shallowCopyOf( dict:Object ):Object
		{
			var out:Object = {};
			for ( var key:String in dict )
			{
				out[ key ] = dict[ key ];
			}
			return out;
		}
		
		public function getShipObject():Object
		{
    	    var myHdr:Object     = Cfg.getHdr();
			var hdr:Object       = shallowCopyOf( myHdr ); // ObjectUtil.copy( myHdr );
			var components:Object = ObjectUtil.copy( componentList.source );
			
			var out:Object = 
				{
					'header' 	 : hdr,
					'components' : components
				};
	
			return out;
		}
		
		private var hullcode:Array =
			[
				'A','B','C','D','E','F','G','H','J','K','L','M','N','P','Q','R','S','T','U','V','W','X','Y','Z'
			];
		
		public function calcQSP():void
		{
			var hdr:Object = Cfg.getHdr();

			var mja:Array = Drives.getDriveHelper().getManeuverAndJumpDriveRating();
			
			var hullCode:String = '';
			var hullMult:int    = hdr.mult || 1;
			var hullPreMult:int = hdr.preMult || 1;
			
			if ( hdr.mission.toString().substr(0,1) == 'Q' ) // && hdr.tons < 100 ) 
				hullCode = '' + int(hdr.tons / 10);
			else
			    hullCode = hullcode[ ((hdr.tons/hullMult/hullPreMult)/100 - 1) ];

			hdr.qsp = hdr.mission + '-' + hullCode;
			
			if ( hdr.preMult > 1 )
			{
				if ( hdr.preMult < 10 )
					hdr.qsp = hdr.mission + '-' + hdr.preMult + hullCode;
				else
					hdr.qsp = hdr.mission + '-' + hullcode[ hdr.preMult - 10 ] + hullCode;
			}
			
			if ( hdr.mult > 1 )
			{
				if ( hdr.mult < 10 )
					hdr.qsp += hdr.mult;
				else
					hdr.qsp += hullcode[ hdr.mult - 10 ];
			}
			
			hdr.qsp += hdr.config + mja[0] + mja[1];

			if ( hdr.hasOwnProperty( 'comments' ) == false || hdr.comments == '' )
			{
				hdr.comments = '';
			}
		}
		
		//
		//  Sanitization process before new list is refreshed on the ship grid.
		//  Hopefully this will help adapt some earlier formats.
		//
		public function removeByLabel( label:String ):void
		{
			var result:Array = [];
			for each ( var item:Object in this.componentList.source )
			{
				if ( item[ 'label' ] != label )
					result.push( item );
			}
			this.componentList.source = result;
		}
		
		public function load( data:Object ):void
		{
			if ( data == null )
				return;
			
			if ( data[ 'header' ] != null )
			{
				this.header = ObjectUtil.copy( data[ 'header' ] );
			}

			if ( data[ 'components' ] != null )
			{
				this.componentList.removeAll(); // hope this is not a problem.
				this.componentList.source = data[ 'components' ];
			}
			
			Cfg.checkFormat();
		}
		
		public static function checkFormat():void
		{
			//Cfg.getInstance().removeByLabel( 'Landing legs with pads' );
			
			if ( Cfg.getHdr().hasOwnProperty( 'format' ) == false )
			{
				Alert.show( "The design is of an unknown version. Results will likely be unpredictable.", "Format Not Detected", Alert.OK );				
			}
			else if ( Cfg.getHdr().format != Cfg.FORMAT )
			{
				Alert.show( "The design is of a different format (\"" + Cfg.getHdr().format + "\"). Results may be unpredictable.", "Older Format Detected", Alert.OK );
			}	
		}
	}
}