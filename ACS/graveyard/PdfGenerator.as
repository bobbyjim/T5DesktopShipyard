package generators
{
	import data.Cfg;
	
	import flash.geom.Rectangle;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;
	import mx.utils.ObjectUtil;

	public class PdfGenerator
	{
		import mx.collections.ArrayCollection;
		
		import org.alivepdf.colors.GrayColor;
		import org.alivepdf.colors.RGBColor;
		import org.alivepdf.data.Grid;
		import org.alivepdf.data.GridColumn;
		import org.alivepdf.fonts.CoreFont;
		import org.alivepdf.fonts.FontFamily;
		import org.alivepdf.layout.Align;
		import org.alivepdf.layout.Orientation;
		import org.alivepdf.layout.Size;
		import org.alivepdf.layout.Unit;
		import org.alivepdf.pdf.PDF;
		import org.alivepdf.saving.Method;

		public var pdf:PDF;
		
		public var groupColumns:Array;
		public var displayGrid:Grid;
		public var crewColumns:Array;
        public var crewDisplayGrid:Grid;
		
		private var Helvetica:CoreFont = new CoreFont( FontFamily.HELVETICA );
		private var HelveticaBold:CoreFont = new CoreFont( FontFamily.HELVETICA_BOLD );
		
		private var MAX_PAGE_Y:int = 700;
		
		private var ehex:String = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
		
		public function PdfGenerator()
		{
//			var comp:GridColumn 		= new GridColumn("Component",   "type",         65 );
			var count:GridColumn        = new GridColumn("#",           "howMany",      18 );
			var comment:GridColumn 		= new GridColumn("Component",	"label", 		160 );
			var target:GridColumn       = new GridColumn("TN",          'target',       20 );
			var mod:GridColumn		 	= new GridColumn('Mod',			'mod',			15 );
			var q:GridColumn			= new GridColumn("Q",           "q",            15 );
			var r:GridColumn			= new GridColumn("R",           "r",            15 );
			var e:GridColumn			= new GridColumn("E",           "e",            15 );
			var b:GridColumn			= new GridColumn("B",           "b",            15 );
			var s:GridColumn			= new GridColumn("S",           "s",            15 );
//			var code:GridColumn 		= new GridColumn("Code", 		"Code", 		40 );
			var cp:GridColumn			= new GridColumn("CP",          "CP",           20 );
			var tl:GridColumn			= new GridColumn("TL",          "tl",           20 );
			var sq:GridColumn			= new GridColumn("Sq",          "Sq",           48 );
			var tons:GridColumn 		= new GridColumn("Tons", 		"totalTons",	40 );
			var mcr:GridColumn			= new GridColumn("MCr",         "totalMCr",     35 );
//			var kcr:GridColumn			= new GridColumn("KCr",         "KCr",          25 );
			
			//groupColumns = [ comp, comment, q, r, e, b, s, code, cp, sq, tl, tons, mcr, kcr ];
			//               count  label    target  q  r  e  b  s  CP  Sq  tl  tons  mcr 
			groupColumns = [ count, comment, target, q, r, e, b, s, cp, sq, tl, tons, mcr ];
			
			displayGrid = new Grid( [],
				0, 0, 
				new RGBColor(0x888888), new RGBColor(0xcccccc), 
				true,
				new RGBColor( 0x888888 ), 
				0.1, 
				null,
				groupColumns );		
			
			var c1:GridColumn			= new GridColumn( 'S1', 's1', 90 );
			var c2:GridColumn			= new GridColumn( 'S2', 's2', 90 );
			var c3:GridColumn			= new GridColumn( 'S3', 's3', 90 );
			var c4:GridColumn			= new GridColumn( 'S4', 's4', 90 );
			
			crewColumns = [ c1, c2, c3, c4 ]; // , tons, mcr ];
			
			crewDisplayGrid = new Grid( [],
				0, 0,
				new RGBColor( 0x888888 ), new RGBColor( 0xcccccc ),
				true,
				new RGBColor( 0x888888 ),
				0.1, 
				null,
				crewColumns );
		}
			
		public function generate():ByteArray
		{
			pdf = new PDF(Orientation.PORTRAIT, Unit.POINT, Size.LETTER );
			generateCurrentShip( pdf, Cfg.getHdr(), Cfg.getInstance().componentList.source );
			var bytes:ByteArray = pdf.save( Method.LOCAL );
			return bytes;
		}
		
		public function generateArchive():ByteArray
		{
			pdf = new PDF(Orientation.PORTRAIT, Unit.POINT, Size.LETTER );
			for each ( var design:Object in Cfg.stockShips )
			{
				var hdr:Object = design[ 'header' ];
				var components:Array = design[ 'components' ];
				generateCurrentShip( pdf, hdr, components );				
			}
			var bytes:ByteArray = pdf.save( Method.LOCAL );
			return bytes;
		}
		
		private function fix( item:Object, attr:String ):void
		{
			if ( item.hasOwnProperty( attr ) == false 
			  || item[ attr ] == 0 )
			{
				item[ attr ] = '';
			}
		}
		
		private function clean( src:Array ):Array
		{
			var out:Array = [];
			for each ( var z:Object in src )
			{
				var item:Object = ObjectUtil.copy(z);
				fix( item, 'q' );
				fix( item, 'r' );
				fix( item, 'e' );
				fix( item, 'b' );
				fix( item, 's' );
				fix( item, 'CP' );
				fix( item, 'sq' );
				
				if ( item.hasOwnProperty( 'q' ) && item.q > 9 )
				{
					// ehex
					item.q = ehex.charAt( item.q - 10 );
				}
				
				out.push( item );
			}
			return out;
		}
		
		private function generateCurrentShip( pdf:PDF, hdr:Object, list:Array ):void
		{
			list = clean( list ); // qrebs
			var xoffset:int = 50;

			pdf.addPage();
			
			// print title
			pdf.setFont(new CoreFont(), 20);
			pdf.textStyle(new GrayColor( 0.0 ), 0.8 );
			
			var title:String = hdr.qsp + ' ' + hdr.shipname;
			
			if ( hdr.hasOwnProperty( 'missionLabel' ) )
			   title = title.replace( /^(\w+)-/, "$1(" + hdr.missionLabel + ")-" );
			
			pdf.writeFlashHtmlText( 0, "<I>" + title + "</I>" );

			pdf.setFont(new CoreFont(), 10);

			var y:Number = 50;
			pdf.setXY( xoffset, y );

			var notes:String = '';
			
			if ( hdr.hasOwnProperty( 'comments' ) && hdr.comments != null )
			{
				if ( notes.length > 0 ) notes += "\n";
				
				notes += hdr.comments;
			}
			
			if ( notes.length > 0 )
				pdf.writeText( 12, notes );
			
			pdf.setY( pdf.getY() + 20 );
			
			y = pdf.getY();

			addHeaderGroup( pdf, "03", "", hdr, xoffset, y, 'STARSHIP FILLFORM 04-09' );
			y += 24;			
			pdf.setY( pdf.getY() + 24 );
			
			var hulldata:Array    	 = Cfg.getInstance().grepArrayByType( list, 'Hull' );
			addGroup( pdf, "04-07", "Hull",   	hulldata,  	hdr, xoffset, pdf.getY(), true );  // show column headers
			
			var armorData:Array	  	 = Cfg.getInstance().grepArrayByType( list, 'Armor' );
			addGroup( pdf, "08", "Armor",  	armorData, 	hdr, xoffset, pdf.getY() );
			
			var driveData:Array   	 = Cfg.getInstance().grepArrayByType( list, 'Drive' );  
			addGroup( pdf, "10-11", "Drives", 	driveData, 	hdr, xoffset, pdf.getY(), true );

			var operationsData:Array = Cfg.getInstance().grepArrayByType( list, 'Ops' );
			addGroup( pdf, "16", "Control", operationsData, hdr, xoffset, pdf.getY(), true ); // show column headers 			

			var vehicleData:Array    = Cfg.getInstance().grepArrayByType( list, 'Vehicle' );
			addGroup( pdf, "16b", "Vehicles", vehicleData, hdr, xoffset, pdf.getY(), false, true );			

			var crewList:Array = [
				{ 	
					s1: 'Ctl Consoles=' + hdr.controlConsoles,
					s2: 'Op Consoles=' + hdr.operatingConsoles,
					s3: 'Workstations=' + hdr.workstations,
					s4: ''
/*					s1: 'Pilot=' + hdr.pilot, 
				  	s2: 'Astrogator=' + hdr.astrogator, 
				  	s3: 'Sensop=' + hdr.sensop, 
				  	s4: 'Medic=' + hdr.medic */
				},
/*				{ 	
					s1: 'Engineer=' + hdr.engineer, 
					s2: 'Gunner=' + hdr.gunner, 
					s3: 'Steward=' + hdr.steward, 
					s4: 'Freightmaster=' + hdr.freightmaster 
				},*/
				{ 	
					s1: 'Comfort=' + hdr.crewComfort,
					s2: '',
				/*	s2: 'Driver=' + hdr.driver, */
					s3: 'Troops=' + hdr.troops * 5, 
					s4: 'Staff=' + hdr.staff
				}
				/*,
				{
					s1: '', 
					s2: '', 
					s3: '', 
					s4: '' 
				}
				*/
			];

			var crewData:Array    	 = Cfg.getInstance().grepArrayByType( list, 'Crew' );
			addCluster( pdf, '17-18', 'Control', crewList, crewData, hdr, xoffset, pdf.getY() );

			var paxList:Array = [
				{
					s1: 'Demand=' + hdr.demand, 
					s2: 'Passengers='  + hdr.passengers,
					s3: 'Low=' + hdr.low,
					s4: ''
				}
			];

			var paxData:Array		 = Cfg.getInstance().grepArrayByType( list, 'Passenger' );
			var payloadData:Array 	 = Cfg.getInstance().grepArrayByType( list, 'Payload' );
			
			for each ( var elem:Object in payloadData )
			{
				paxData.push( elem );
			}

			addCluster( pdf, '19', 'Payload', paxList, paxData, hdr, xoffset, pdf.getY(), true );
			
			var sensorData:Array  	 = Cfg.getInstance().grepArrayByType( list, 'Sensor' );			
			if ( sensorData.length == 0 )
			{
				sensorData.push( { label:'Default sensors', target:hdr.tl, tl:hdr.tl } );
				//               label    target  q  r  e  b  s  CP  Sq  tl  tons  mcr 
			}
			addGroup( pdf, "21a", "Sensors", sensorData, hdr, xoffset, pdf.getY(), true, true );
			
			var weaponData:Array  	 = Cfg.getInstance().grepArrayByType( list, 'Weapon' );
			addGroup( pdf, "21b", "Weapons", weaponData, hdr, xoffset, pdf.getY(), true, true );
			
			var defenseData:Array 	 = Cfg.getInstance().grepArrayByType( list, 'Defense' );		
			addGroup( pdf, "21c", "Defenses", defenseData, hdr, xoffset, pdf.getY(), true, true );			

			
			pdf.end(); // do we need this?
		}
		
		private function addHeaderGroup( pdf:PDF,
										 header:String,
										 subheader:String,
										 data:Object,
										 x:Number,
										 y:Number,
										 pagetitle:String=''):void
		{
			pdf.lineTo( 290, y );
			pdf.end();
			
//			pdf.setFont( HelveticaBold, 10 );
//			pdf.addCell( 10, 10, pagetitle );
//			y += 12;
			pdf.setXY( x, y );

			pdf.setFont( HelveticaBold, 18 );
			if ( header != null )
			{
				pdf.addCell( 18, 18, header		);
			}
			pdf.setFont( Helvetica, 10 );
			if ( subheader != null )
			{
				pdf.setXY(x, y+18);
				pdf.addCell( 10, 10, subheader );
			}

			pdf.setFont( Helvetica, 10 );
			
			
			var name:String = data[ 'shipname' ] == null? '' : data[ 'shipname' ];
			var tons:String = Math.ceil(data[ 'tons' ] - data[ 'tonsFree' ]) + ' t';
			
			
			addHeaderLine( 110, y, name, tons );
			
			var builder:String = data['builder'] == null? '' : data[ 'builder' ];
			var mission:String = data['mission'] == null? '' : data[ 'mission' ] + ', TL' + data['tl'];

			addHeaderLine( 330, y, builder, mission );
			
			var id:String = data[ 'owner' ] == null? 'Unregistered' : data[ 'owner' ];
			var people:String = data[ 'shifts' ];
			if ( data[ 'shifts' ] > 1 )
				people += ' shifts';
			else
				people += ' shift';
			
			addHeaderLine( 110, y+14, id, people );
			
			var disposition:String = data['disposition'] || '';
			var mcr:String = data[ 'totalMCr' ] == null? '' : 'MCr ' + data[ 'totalMCr' ];
			
			addHeaderLine( 330, y+14, disposition, mcr );
			
			pdf.drawRect( new Rectangle( x, pdf.getY()-14, 565, 1 ) );
			pdf.end();	
		}
		
		private function addHeaderLine( x:Number, y:Number, s1:String, s2:String ):void
		{
			pdf.setXY( x, y );
			pdf.addCell( 170, 14, s1, 1, 0, Align.LEFT );
			pdf.addCell(  50, 14, s2, 1, 0, Align.CENTER );
		}
				
		private function addCluster( pdf:PDF,
									 header:String, 
									 subheader:String,
									 dat:Array,
									 group:Array,
									 datHDR:Object,
									 x:Number,
									 y:Number,
									 clusterFirst:Boolean = false
									 ):void
		{
			var ypos:Number = pdf.getY() + dat.length * 14;
			if ( ypos > MAX_PAGE_Y )
			{
				pdf.addPage();	
				addHeaderGroup( pdf, "03", "", datHDR, x, 40, 'STARSHIP FILLFORM 04-10' );
				pdf.setY( 104 );
				y = pdf.getY();
			}

			pdf.setXY( x, y );
			pdf.setFont( HelveticaBold, 18 );
			
			if ( header != null )
			{
				pdf.addCell( 18, 18, header		);
			}			
			
			pdf.setFont( Helvetica, 10 );
			
			if ( subheader != null )
			{
				pdf.setXY(x, y+18);
				pdf.addCell( 10, 10, subheader );
			}

			displayGrid.height = 0;
			var offset:int = 0;
			
			if ( clusterFirst )
			{
				offset = addGrid( crewDisplayGrid, x, y, dat );
				addGrid( displayGrid, x, y+offset, group );
			}
			else
			{
				offset = addGrid( displayGrid, x, y+offset, group );				
				addGrid( crewDisplayGrid, x, y+offset, dat );
			}
			
			pdf.moveTo( x, y );
			pdf.lineTo( 565, y );
			pdf.end();

			if ( crewDisplayGrid.height + displayGrid.height < 28)
				crewDisplayGrid.height = 28 - displayGrid.height;
			
			pdf.setY( y + crewDisplayGrid.height + displayGrid.height );
		}
		
		private function addGrid( grid:Grid, x:Number, y:Number, dat:Array ):int
		{
			if ( dat == null ) dat = [];
			
			if ( dat.length > 0 )
			{
				grid.dataProvider = dat;
				
				pdf.setXY( 0, y );
				pdf.addGrid( grid, x+60, 0, false, false );
				pdf.end();
			}

			return dat.length * 14;
		}
		
		private function addGroupFromList( pdf:PDF,
										   header:String,
										   subheader:String,
										   datHDR:Object,
										   x:Number,
										   sourceList:Array,
										   type:String,
										   showHeader:Boolean=false,
										   skipIfEmpty:Boolean=false ):void
		{
			var dat:Array = Cfg.getInstance().grepArrayByType( sourceList, type );
			addGroup( pdf, header, subheader, dat, datHDR, x, 0, showHeader, skipIfEmpty );
		}
		
		private function addGroup( pdf:PDF, 
								   header:String, 
								   subheader:String, 
								   dat:Array, 
								   datHDR:Object,
								   x:Number, 
								   y:Number, 
								   showHeader:Boolean=false,
								   skipIfEmpty:Boolean=false
								   ):void
		{
			// skip, if empty
			if ( skipIfEmpty && dat.length == 0 )
				return;
			
			// fill to minimum, if needed
			while ( dat.length < 2 )
			{
				// [ comment, target, q, r, e, b, s, cp, sq, tl, tons, mcr ]
				dat.push( {} );
			}
			
			// new page, if necessary
			var ypos:Number = pdf.getY() + dat.length * 14;
			if ( ypos > MAX_PAGE_Y )
			{
				pdf.addPage();	
				addHeaderGroup( pdf, "03", "", datHDR, x, 40, 'STARSHIP FILLFORM 04-10' );
				pdf.setY( 104 );
			}
			y = pdf.getY();
			
			// ok now print
			pdf.setXY(x, y);
			pdf.setFont( HelveticaBold, 18 );
			if ( header != null )
			{
				pdf.addCell( 18, 18, header		);
			}
/*			if ( header2 != null )
			{
				pdf.setXY(x, y+28);
				pdf.addCell( 18, 18, header2	); 
			}
*/			pdf.setFont( Helvetica, 10 );
			if ( subheader != null )
			{
				pdf.setXY(x, y+18);
				pdf.addCell( 10, 10, subheader );
			}
/*			if ( subheader2 != null )
			{
				pdf.setXY(x, y+46);
				pdf.addCell( 10, 10, subheader2 );
			}
*/			
			displayGrid.dataProvider = dat;

			pdf.moveTo( x, y );
			pdf.lineTo( 565, y );
			pdf.end();

			pdf.setXY( 0, y );
			pdf.addGrid( displayGrid, x+60, 0, false, showHeader );

			if ( displayGrid.height < 28)
				displayGrid.height = 28;
			pdf.setY( y + displayGrid.height );
		}
		
		private function hrule( pdf:PDF, y1:Number ):void
		{
			var x:Number = pdf.getX();
			var y:Number = pdf.getY();
			
			pdf.moveTo( 0.5, y1 );
			//pdf.addText( header, 0.5, y1-0.05 );
			pdf.lineTo( 8.0, y1 );
			pdf.end();
			pdf.moveTo( x, y );
		}		
	}
}