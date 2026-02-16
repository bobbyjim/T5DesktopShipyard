package component
{
	public class ComponentUtils
	{
		public function ComponentUtils()
		{
		}
	
		protected static function calculateTotalsOf( attr:String, obj:Object ):void
		{
			if ( obj.hasOwnProperty( attr ) )
			{
				var totalName:String = 'total' + attr.substr(0,1).toUpperCase() + attr.substr(1);
				var total:int = obj[ attr ];
				
				if ( obj.hasOwnProperty( 'howMany' ) && obj.howMany > 0 )
				{
					obj[ totalName ] = total * obj.howMany;
				}
				else
				{
					obj[ totalName ] = total;
				}
			}
		}

		public static function calculateTN( item:Object ):void
		{
			item.target = parseInt(item.tl);
			
			if ( item.hasOwnProperty( 'mod' ) )
			{
				item.target += parseInt(item.mod);
			}
			
			if ( isNaN( item.target ) )
			{
				item.target = item.tl;
			}			
		}
		
		// tonnage and MCr
		public static function calculateTotals( item:Object ):void
		{
			if ( item[ 'mcr' ] >= 0.1 )
			{
			   item.totalMCr =
				   item['mcr'] = int(item['mcr']*10)/10;
			}
			else
			{
				item.totalMCr =
					item['mcr'] = int(item['mcr']*1000)/1000;
			}
			
			item.totalTons =
				item[ 'tons' ] = int( item[ 'tons' ] * 100 ) / 100;	
			
			if ( item.howMany > 1 )
			{
				item.totalTons *= item.howMany;
				item.totalMCr  *= item.howMany;
				item.totalMCr = int(item.totalMCr*10)/10;
			}
			else
				item.howMany = 1;			
		}
	}
}