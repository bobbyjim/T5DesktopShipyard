package data
{
	import flash.net.FileReference;
	import flash.net.dns.AAAARecord;
	import flash.utils.ByteArray;
	
	import generators.PONEncoder;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	
	import org.as3yaml.YAML;
	
	import storage.LByteArray;
	import storage.formats.D64;
	import storage.formats.LDA;
	import storage.formats.Storable;

	public class IO
	{
		public function IO()
		{
		}
		
		private static function getFilename( ship:Object ):String
		{
			var name:String = 'ACS-' + ship.header.qsp + '-' + ship.header.shipname;
			if ( ship.header.owner != null )
			{
				name = ship.header.owner + '-' + name;
			}
			else if ( ship.header.catalog != null )
			{
				ship.header.owner = ship.header.catalog;
				name = ship.header.owner + '-' + name;
			}
			
			return name;
		}
		
		// padded and truncated to 16 characters
		private static function getBASICfilename( ship:Object ):String
		{
		    var name:String = String(ship.header.shipname).toUpperCase()
				+ String.fromCharCode( 0xa0, 0xa0, 0xa0, 0xa0, 
					                   0xa0, 0xa0, 0xa0, 0xa0, 
									   0xa0, 0xa0, 0xa0, 0xa0, 
									   0xa0, 0xa0, 0xa0, 0xa0 );

			return name.substr( 0, 16 );
		}
		
		/*public static function toPDF():void
		{
			var ship:Object = Cfg.getInstance().getShipObject();
			var pdf:PdfGenerator = new PdfGenerator();
			var bytes:ByteArray  = pdf.generate();
			new FileReference().save( bytes, getFilename( ship ) + '.pdf' );
		}
		
		public static function multiplePDF(event:Object):void
		{
			var pdf:PdfGenerator = new PdfGenerator();
			var bytes:ByteArray  = pdf.generateArchive();
			new FileReference().save( bytes, 'ACS Archive.pdf' );
		}*/
		
		public static function toHTML():void
		{
			var ship:Object = Cfg.getInstance().getShipObject();
			var html:String = encodeAsHTML();
			new FileReference().save( html, getFilename(ship) + ".html" );
		}
		
		public static function toACS():void
		{
			var ship:Object = Cfg.getInstance().getShipObject();
			var acs:String = encodeAsACS();
			new FileReference().save( acs, getFilename(ship) + ".acs" );
		}
		
		public static function toText():void
		{
			var ship:Object = Cfg.getInstance().getShipObject();
			var text:String = encodeAsText();
			new FileReference().save( text, getFilename(ship) + ".txt" );
		}
		
		public static function toD64():void
		{
			var ship:Object = Cfg.getInstance().getShipObject();
			var byteArray:LByteArray = encodeAsBASIC();
			
			var d64:D64 = new D64();
			var myarray:Array = d64.breakIntoSectors( byteArray );
			
			var entry:Object = 
				{
					'name': getBASICfilename(ship),
					'type': 0x83, // 0x81 SEQ 0x82 PRG 0x83 USR
					'sizeActual': byteArray.length,   // in bytes
					'sizeInSectors': myarray.length,
					'load address': 0,           // ??
					'data': myarray
				};

			d64.addEntry( entry );
			var image:LByteArray = d64.writeImage();

			new FileReference().save( image, getFilename(ship) + ".D64" );
		}
		
		public static function encodeAsBASIC():LByteArray
		{
			var buf:LByteArray = new LByteArray();

			/*
			var hulldata:Array    	 = Cfg.getInstance().grepByType( 'Hull' );
			var armorData:Array	  	 = Cfg.getInstance().grepByType( 'Armor' );
			var driveData:Array   	 = Cfg.getInstance().grepByType( 'Drive' );  
			var sensorData:Array  	 = Cfg.getInstance().grepByType( 'Sensor' );			
			var weaponData:Array  	 = Cfg.getInstance().grepByType( 'Weapon' );
			var defenseData:Array 	 = Cfg.getInstance().grepByType( 'Defense' );		
			var operationsData:Array = Cfg.getInstance().grepByType( 'Ops' );
			var crewData:Array    	 = Cfg.getInstance().grepByType( 'Crew' );
			var payloadData:Array 	 = Cfg.getInstance().grepByType( 'Payload' );
			var paxData:Array		 = Cfg.getInstance().grepByType( 'Passenger' );
			var vehicleData:Array    = Cfg.getInstance().grepByType( 'Vehicle' );
			*/
			var ship:Object = Cfg.getInstance().getShipObject();
			var hdr:Object = Cfg.getHdr();		
			var acs:String = encodeAsACS(false);
			
			//var acsary:Array = acs.split( "\n" );
			//acs = acsary.join( "\r" );

			//
			// Byte  Description
			// ----  ----------------------
			// 0-1   Link pointer
			// 2-3   Line number, low-high
			// 4+    Line content, null terminated.
			//

			// Header Line - NOT FOR SEQ and USR FILES!
			//buf.writeByte( 1 ); buf.writeByte( 1 ); // Link ptr lo, hi
			//buf.writeByte( 1 );	buf.writeByte( 0 ); // line num lo, hi
			
			/*
			buf.writeUTFBytes( hdr.shipname + ' MCr' + hdr.totalMCr );
			buf.writeByte( 0 ); // EOL
			
			PONEncoder.encodeBASIC( buf, hulldata );
			PONEncoder.encodeBASIC( buf, armorData);
			PONEncoder.encodeBASIC( buf, driveData);
			PONEncoder.encodeBASIC( buf, sensorData);
			PONEncoder.encodeBASIC( buf, weaponData);
			PONEncoder.encodeBASIC( buf, defenseData);
			PONEncoder.encodeBASIC( buf, operationsData);
			PONEncoder.encodeBASIC( buf, crewData);
			PONEncoder.encodeBASIC( buf, payloadData);
			PONEncoder.encodeBASIC( buf, paxData);
			PONEncoder.encodeBASIC( buf, vehicleData);
			*/
			buf.writeUTFBytes( acs );
			
			for ( var i:int=0; i<buf.length; i++ )
			{
				if ( buf[i] == 0x0a )
				{
					buf[i] = 0x0d;
				}
			}
			
			// write EOF
			buf.writeByte( 0 ); buf.writeByte( 0 );
			
			return buf;			
		}
		
		public static function encodeAsHTML():String
		{
			var html:String = "<html><head>\n"
				+ "<style type='text/css'>\n"
				+ "<!--"
				+ "p2 { font-size:16pt; font-style:italic; font-family:sans-serif; }"
				+ "p  { font-size:9pt; font-family:sans-serif; }"
				+ "th { font-size:16pt; font-family:sans-serif; }"
				+ "td { font-size:9pt; font-family:sans-serif; }"
				+ "-->\n"
				+ "</style>\n"
				+ "</head>"
				+ "<body>\n";
			
			var hulldata:Array    	 = Cfg.getInstance().grepByType( 'Hull' );
			var armorData:Array	  	 = Cfg.getInstance().grepByType( 'Armor' );
			var driveData:Array   	 = Cfg.getInstance().grepByType( 'Drive' );  
			var sensorData:Array  	 = Cfg.getInstance().grepByType( 'Sensor' );			
			var weaponData:Array  	 = Cfg.getInstance().grepByType( 'Weapon' );
			var defenseData:Array 	 = Cfg.getInstance().grepByType( 'Defense' );		
			var operationsData:Array = Cfg.getInstance().grepByType( 'Ops' );
			var crewData:Array    	 = Cfg.getInstance().grepByType( 'Crew' );
			var payloadData:Array 	 = Cfg.getInstance().grepByType( 'Payload' );
			var paxData:Array		 = Cfg.getInstance().grepByType( 'Passenger' );
			var vehicleData:Array    = Cfg.getInstance().grepByType( 'Vehicle' );
			
			var ship:Object = Cfg.getInstance().getShipObject();
			var hdr:Object = Cfg.getHdr();

			html += "<p2>" + hdr.missionLabel + " " + hdr.qsp + " " + hdr.shipname + " MCr " + hdr.totalMCr + "</p2>\n";
			
			var comments:String = hdr.comments || '';
			var myPattern:RegExp = /\n/g;
			
			html += "<p>";
			
			if ( hdr.builder )
				html += 'Builder: ' + hdr.builder + "<br />\n";
			
			if ( hdr.owner )
				html += "Owner: " + hdr.owner + "<br />\n";
			
			if ( hdr.disposition )
				html += "Disposition: " + hdr.disposition + "<br />\n";
			
			html += "</p>\n";

			html += "<p>" + comments.replace(myPattern, "</p>\n<p>") + "</p>\n";
						
			html += "<p>";
			if ( hdr.tonsFree > 0 )
			{
				html += "Actual volume: " + (hdr.tons - hdr.tonsFree) + " tons<br />\n";
			}
			else
				if ( hdr.tonsFree < 0 )
				{
					html += "Overtonnage: " + (-1 * hdr.tonsFree) + " tons<br />\n";	
				}
			
			var crewSign:String = '';
			if ( hdr.crewComfort > -1 ) crewSign = '+';
			
			var passSign:String = '';
			if ( hdr.demand > -1 ) passSign = '+';
			
			html += "Crew comfort:     " + crewSign + hdr.crewComfort + "<br />\n";
			html += "Passenger demand: " + passSign + hdr.demand      + "<br />\n";

			html += "</p>\n";

			html += "<hr>\n";
			
			html += "<table rules='all' frame='border' cellpadding='2' width='100%'>\n";
			
			html += PONEncoder.encodeHtml("04-07", "Hull", hulldata)
				 +  PONEncoder.encodeHtml("08", "Armor", armorData)
				 +  PONEncoder.encodeHtml("10-11", "Drives", driveData)
				 +  PONEncoder.encodeHtml("16", "Operations", operationsData)
				 +  PONEncoder.encodeHtml("16b", "Vehicles", vehicleData)
				 +  PONEncoder.encodeHtml("17-18", "Crew", crewData)
				 +  PONEncoder.encodeHtml("19", "Payload", payloadData)
				 +  PONEncoder.encodeHtml("20", "Passengers", paxData)
				 +  PONEncoder.encodeHtml("21", "Sensors", sensorData)
				 +  PONEncoder.encodeHtml("21b", "Weapons", weaponData)
				 +  PONEncoder.encodeHtml("21c", "Defenses", defenseData)
				 ;
			
			html += "</table>\n";
			html += "[<a href='http://www.farfuture.net/'>Far Future Enterprises</a>]\n";
			html += "</body>\n</html>";

			/*			
			text += hdr.history || '';
			*/
	
			return html;
		}
		
		public static function encodeAsText():String
		{
			var hulldata:Array    	 = Cfg.getInstance().grepByType( 'Hull' );
			var armorData:Array	  	 = Cfg.getInstance().grepByType( 'Armor' );
			var driveData:Array   	 = Cfg.getInstance().grepByType( 'Drive' );  
			var sensorData:Array  	 = Cfg.getInstance().grepByType( 'Sensor' );			
			var weaponData:Array  	 = Cfg.getInstance().grepByType( 'Weapon' );
			var defenseData:Array 	 = Cfg.getInstance().grepByType( 'Defense' );		
			var operationsData:Array = Cfg.getInstance().grepByType( 'Ops' );
			var crewData:Array    	 = Cfg.getInstance().grepByType( 'Crew' );
			var payloadData:Array 	 = Cfg.getInstance().grepByType( 'Payload' );
			var paxData:Array		 = Cfg.getInstance().grepByType( 'Passenger' );
			var vehicleData:Array    = Cfg.getInstance().grepByType( 'Vehicle' );
			
			var ship:Object = Cfg.getInstance().getShipObject();
			var hdr:Object = Cfg.getHdr();
			
			var text:String = hdr.missionLabel + ' '
				            + hdr.qsp + ' '
							+ hdr.shipname + ' '
							+ 'MCr' +  hdr.totalMCr + "\n\n";
			
			if ( hdr.builder )
				text += 'Builder: ' + hdr.builder + "\n";

			if ( hdr.owner )
				text += "Owner: " + hdr.owner + "\n";
			
			if ( hdr.disposition )
				text += "Disposition: " + hdr.disposition + "\n";
				
			text += "\n";
			text += hdr.comments || '';
			text += "\n\n";

			if ( hdr.tonsFree > 0 )
			{
				text += "Actual volume: " + (hdr.tons - hdr.tonsFree) + " tons\n";
			}
			else
			if ( hdr.tonsFree < 0 )
			{
				text += "Overtonnage: " + (-1 * hdr.tonsFree) + " tons\n";	
			}
			
			var crewSign:String = '';
			if ( hdr.crewComfort > -1 ) crewSign = '+';
			
			var passSign:String = '';
			if ( hdr.demand > -1 ) passSign = '+';
			
			text += "Crew comfort:     " + crewSign + hdr.crewComfort + "\n";
			text += "Passenger demand: " + passSign + hdr.demand      + "\n";
			
			text += "\n";

			text += '[code]\n';
			text += PONEncoder.writeTextHeaderLine();
			
			text += PONEncoder.encodeText(hulldata)
				+ PONEncoder.encodeText(armorData)
				+ PONEncoder.encodeText(driveData)
				+ PONEncoder.encodeText(sensorData)
				+ PONEncoder.encodeText(weaponData)
				+ PONEncoder.encodeText(defenseData)
				+ PONEncoder.encodeText(operationsData)
				+ PONEncoder.encodeText(crewData)
				+ PONEncoder.encodeText(payloadData)
				+ PONEncoder.encodeText(paxData)
				+ PONEncoder.encodeText(vehicleData)
				;
						
			text += '[/code]\n\n';

			text += "[code]\n";
			text += hdr.history || '';
			text += "[/code]\n\n";

			return text;
		}
		
		//
		//  This is a modified text format
		//
		public static function encodeAsACS( includeComments:Boolean=true ):String
		{
			var hulldata:Array    	 = Cfg.getInstance().grepByType( 'Hull' );
			var armorData:Array	  	 = Cfg.getInstance().grepByType( 'Armor' );
			var driveData:Array   	 = Cfg.getInstance().grepByType( 'Drive' );  
			var sensorData:Array  	 = Cfg.getInstance().grepByType( 'Sensor' );			
			var weaponData:Array  	 = Cfg.getInstance().grepByType( 'Weapon' );
			var defenseData:Array 	 = Cfg.getInstance().grepByType( 'Defense' );		
			var operationsData:Array = Cfg.getInstance().grepByType( 'Ops' );
			var crewData:Array    	 = Cfg.getInstance().grepByType( 'Crew' );
			var payloadData:Array 	 = Cfg.getInstance().grepByType( 'Payload' );
			var paxData:Array		 = Cfg.getInstance().grepByType( 'Passenger' );
			var vehicleData:Array    = Cfg.getInstance().grepByType( 'Vehicle' );
			
			var ship:Object = Cfg.getInstance().getShipObject();
			var hdr:Object = Cfg.getHdr();
			
			var text:String = "--- \n"
			    + "ACS1.0: " + new Date().toString() + "\n"
				+ "\n"
				//+ "Mission: " + hdr.missionLabel + "\n"
				//+ "QSP: " + hdr.qsp + "\n"
				//+ "TL: " + hdr.tl + "\n"
			    //+ "Name: " + hdr.shipname + "\n"
				//+ "Actual Tons: " + (hdr.tons - hdr.tonsFree) + "\n"
				+ hdr.qsp + "-" + hdr.tl + ' '
			;
			
			//if ( hdr.tonsFree < 0 )
			//	text += "Overtonnage: " + (-1 * hdr.tonsFree) + "\n";
			
			//text += "\n"
			//	 + 'MCr: ' +  hdr.totalMCr + "\n";
			
			/*
			if ( hdr.builder )
				text += 'Builder: ' + hdr.builder + "\n";
			
			if ( hdr.owner )
				text += "Owner: " + hdr.owner + "\n";
			
			if ( hdr.disposition )
				text += "Disposition: " + hdr.disposition + "\n";
			*/		
			var crewSign:String = '';
			if ( hdr.crewComfort > -1 ) crewSign = '+';
			
			var passSign:String = '';
			if ( hdr.demand > -1 ) passSign = '+';
			
			text += /*"Crew comfort:     " +*/ "C" + crewSign + hdr.crewComfort + " ";
			text += /*"Passenger demand: " +*/ "D" + passSign + hdr.demand      + " ";
			
			text += hdr.totalMCr + "\n";
			
//			text += 'Components: \n';
			text += PONEncoder.encodeACS("04-07", "Hull", hulldata)
				+  PONEncoder.encodeACS("08", "Armor", armorData)
				+  PONEncoder.encodeACS("10-11", "Drives", driveData)
				+  PONEncoder.encodeACS("16", "Operations", operationsData)
				+  PONEncoder.encodeACS("16b", "Vehicles", vehicleData)
				+  PONEncoder.encodeACS("17-18", "Crew", crewData)
				+  PONEncoder.encodeACS("19", "Payload", payloadData)
				+  PONEncoder.encodeACS("20", "Passengers", paxData)
				+  PONEncoder.encodeACS("21", "Sensors", sensorData)
				+  PONEncoder.encodeACS("21b", "Weapons", weaponData)
				+  PONEncoder.encodeACS("21c", "Defenses", defenseData)
				;

			if ( includeComments == true )
				text += '\n\n'
			    	 + "Comments: " + (hdr.comments || '') + "\n\n"
				 	+ "ref: [<a href='http://www.farfuture.net/'>Far Future Enterprises</a>]\n"
				 	+ "\n";
			
			return text;
		}
		
		public static function toYAML():void
		{
			var ship:Object = Cfg.getInstance().getShipObject();
			var yaml:String = PONEncoder.encodeYAML(ship); 
			// DO NOT USE YAML.encode( ship ), because it has a fatal bug
			// which occasionally over-indents an attribute.
			
			yaml = yaml.replace( /!actionscript.object:.*/g, "" );
			yaml = yaml.replace( /!!\w+/g, "" );
			yaml = yaml.replace( /  mx_internal_uid: .*\n/g, "" );
			
			new FileReference().save( yaml, getFilename(ship) + '.yml' );
		}
		
		public static function toXML():void
		{
			var ship:Object = Cfg.getInstance().getShipObject();
			var xml:String = PONEncoder.encodeXML(ship, 'ship');
			new FileReference().save( xml, getFilename(ship) + '.xml' );
		}
		
		public static function toJSON():void
		{
			var ship:Object = Cfg.getInstance().getShipObject();
			//				var json:String = JSON.encode(ship);				
			var json:String = PONEncoder.encodeJSON(ship);
			new FileReference().save( json, getFilename(ship) + '.json' );
		}
		
		private static function toPON():void
		{
			var ship:Object = Cfg.getInstance().getShipObject();
			var pon:String = PONEncoder.encodePON(ship);
			new FileReference().save( pon, getFilename(ship) + '.pon' );
		}
		
		private static function toLDA():void
		{
			var ship:Object = Cfg.getInstance().getShipObject();
			
			var image:Storable = new LDA();
			image.addEntry( {} );
			var out:LByteArray = image.writeImage();
			
			var filename:String = getFilename(ship) + '.' + 'LDA';
			new FileReference().save( out, filename );
		}
	}
}