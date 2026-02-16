package generators
{
	import com.adobe.serialization.json.JSON;
	import com.adobe.serialization.json.JSONDecoder;
	import com.adobe.serialization.json.JSONEncoder;
	
	import data.IO;
	
	import flash.xml.XMLDocument;
	
	import mx.utils.XMLUtil;
	
	import storage.LByteArray;

	public class PONEncoder
	{
		
		public static function encodePON( obj:Object, pair:String="=>" ):String
		{
			return encodeJSON( obj, pair );
		}
		
		public static function writeTextHeaderLine():String
		{
			return pad( "Tons", 7, true ) + "\t "
				 + pad( "Component", 35 ) + "\t"
				 //+ pad( "TN", 2 )         + "\t "
				 + pad( "MCr", 5, true )  + "\t"
				 + 'Notes'
				 + "\n"
				 //+ "--------\t ----------------------------------\t --\t -------\t  --------------------\n";
				 + "-------\t -----------------------------------\t-----\t--------------------\n";
		}
		
		// New way: component, TL, tons, mcr, target, q r e b s, CP
		public static function writeHtmlHeaderLine( title:String, subtitle:String, rowspan:int ):String
		{
			return "<tr bgcolor='f0f0f0'>\n"
			     + "   <th rowspan='" + rowspan + "'>" + title + "<br /><font size='-1'>" + subtitle + "</font></th>\n"
//				 + "   <td><i>#</i></td>\n"
				 + "   <td><i>Component</i></td>\n"
				 + "   <td><i>TL</i></td>\n"
				 + "   <td><i>Tons</i></td>\n"
				 + "   <td><i>MCr</i></td>\n"
				 + "   <td><i>TN</i></td>\n"
//				 + "   <td><i>Q</i></td>\n"
//				 + "   <td><i>R</i></td>\n"
//				 + "   <td><i>E</i></td>\n"
//				 + "   <td><i>B</i></td>\n"
//				 + "   <td><i>S</i></td>\n"
				 + "   <td><i>Quality</i></td>\n"
				 + "   <td><i>CP</i></td>\n"
//				 + "   <td><i>Sq</i></td>\n"
				 + "</tr>";
		}
		
		//
		//  Text dumps an array of ship components.
		//
		public static function encodeText( group:Array ):String
		{
			// component, target, q, r, e, b, s, cp, sq, tl, tons, mcr
			var out:Array = [];
			
			for each (var obj:Object in group)
			{
				//
				// NEW GOAL: build a label such that the component
				// characteristics may be parsed and deduced.
				//
				var label:String = buildLabel( obj );
				
				var notes:String = obj.notes || ''; // buildNotation( obj );
				
				if ( obj.howMany > 1 )
					notes = '#' + obj.howMany + ' ' + notes;
				
				out.push( pad( obj.totalTons, 7, true ) + "\t "
						+ pad( label, 35 )              + "\t"
				//		+ pad( obj.target, 2 )          + "\t "
						+ pad( obj.totalMCr, 5, true )  + "\t"
						+ notes
				);
			}
			
			if ( out.length == 0 ) return '';
			
			return out.join( "\n" ) + "\n";
		}
		
		//
		//  A compressed line format
		//
		public static function encodeACS( title:String, subtitle:String, group:Array ):String
		{
			if ( group.length == 0 )
				return '';
			
			var tlmap:Array = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 
							   'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
							   'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S',
							   'T', 'U', 'V', 'W', 'X', 'Y', 'Z' ];
			
			var qmap:Array = [ 'E', 'D', 'C', 'B', 'A', '0', '1', '2', '3', '4', '5' ];
			
			// component, tons, count, mcr, TL, target, q r e b s, CP, label
			// component, tons, count, TL+target+CP, qrebs, label
			var out:String = "";
			for each (var obj:Object in group)
			{
				// Not using totalTons, just because
				var tons:String = '';
				if ( obj.hasOwnProperty( 'tons' ) )
					tons = '' + int(obj.tons * obj.howMany);
				
				if ( tons.length < 2 ) tons += ' ';
				if ( tons.length < 3 ) tons += ' ';
				
				var count:String = obj.howMany || '1';
				
				if ( count.length < 2 ) count += ' ';
				
				// Not using totalMCr, just because
				var mcr:String = '';
				if ( obj.hasOwnProperty( 'mcr' ) )
				{
					mcr = '' + (obj.mcr * obj.howMany);
					mcr = mcr.replace( /(\.\d)\d+/, "$1" ); 
				}
				
				var r:int = obj.r || 0;
				var e:int = obj.e || 0;
				var b:int = obj.b || 0;
				var s:int = obj.s || 0; 
				var qrebs:String = obj.q + qmap[ r+5 ] + qmap[ e+5 ] + qmap[ b+5 ] + qmap[ s+5 ];
				
				var category:String = subtitle.substr(0,1);
				var label:String = obj.label;
				if ( label.indexOf( "Bridge" ) > -1 )   category = 'B';
				if ( label.indexOf( "Fuel" )   > -1 )   category = 'F';
				if ( label.indexOf( "Life" )   > -1 )   category = 'L';
				if ( label.indexOf( "Computer" ) > -1 ) category = 'M';
				
				out += "" //" - " 
					+ category + ' '
					+ tons + ' '
					+ count + ' '
					// + mcr + ' '
					//+ tlmap[obj.tl] + ''
					+ tlmap[obj.target] + '' 
					+ obj.CP + ' '
					+ qrebs + ' '
					+ obj.label
					+ "\n"
					 ;				
			}
			
			return out;
		}
			

		public static function encodeHtml( title:String, subtitle:String, group:Array ):String
		{
			if ( group.length == 0 )
				return '';
			
			// OLD: component, target, q, r, e, b, s, cp, sq, tl, tons, mcr
			// NEW: component, TL, tons, mcr, target, qrebs, CP
			var out:String = writeHtmlHeaderLine( title, subtitle, group.length + 1 );
			var bgcolor:Array = [ 'ffffff', 'f8f8f8' ];
			for each (var obj:Object in group)
			{
				var label:String = obj.label;
				if ( obj.howMany > 1 )
					label = '(' + obj.howMany + ') ' + label;

				// Not using totalTons, just because
				var tons:String = '';
				if ( obj.hasOwnProperty( 'tons' ) )
				   tons = '' + (obj.tons * obj.howMany);

				// Not using totalMCr, just because
				var mcr:String = '';
				if ( obj.hasOwnProperty( 'mcr' ) )
				{
					mcr = '' + (obj.mcr * obj.howMany);
					mcr = mcr.replace( /(\.\d)\d+/, "$1" ); 
				}
				
				var qrebs:String = "";
				if ( obj.q && obj.q != '0' ) qrebs += "Q" + ((obj.q > 0)? "+" + obj.q : obj.q);
				if ( obj.r && obj.r != '0' ) qrebs += " R" + ((obj.r > 0)? "+" + obj.r : obj.r);
				if ( obj.e && obj.e != '0' ) qrebs += " E" + ((obj.e > 0)? "+" + obj.e : obj.e);
				if ( obj.b && obj.b != '0' ) qrebs += " B" + ((obj.b > 0)? "+" + obj.b : obj.b);
				if ( obj.s && obj.s != '0' ) qrebs += " S" + ((obj.s > 0)? "+" + obj.s : obj.s);
				
				out += "<tr bgcolor='" + bgcolor[0] + "'>\n"
//					+ "   <td>" + count    + "</td>\n"
					+ "   <td>" + label      + "</td>\n"
					+ "   <td>" + obj.tl         + "</td>\n"
					+ "   <td>" + (tons || '-') + "</td>\n"
					+ "   <td>" + (mcr  || '-') + "</td>\n"					
					+ "   <td>" + obj.target     + "</td>\n"
/*					+ "   <td>" + (obj.q  || '') + "</td>\n"
					+ "   <td>" + (obj.r  || '') + "</td>\n"
					+ "   <td>" + (obj.e  || '') + "</td>\n"
					+ "   <td>" + (obj.b  || '') + "</td>\n"
					+ "   <td>" + (obj.s  || '') + "</td>\n"
*/					
					+ "   <td>" + qrebs + "</td>\n"
					+ "   <td>" + (obj.CP || '') + "</td>\n"
//					+ "   <td>" + (obj.Sq || '-') + "</td>\n"
				    + "</tr>\n";
				
				bgcolor.push( bgcolor.shift() );
			}
			
			return out;
		}
		
		private static function buildLabel( obj:Object ):String
		{
			var label:String = obj.label;
			
			//if ( obj.hasOwnProperty( 'category' ) )
			//	label = obj.category + ' ' + label;
			//else
			//	label = obj.type + ' ' + label;

			if ( obj.hasOwnProperty( 'howMany' ) && obj.howMany > 1 )
				label = obj.howMany + 'x ' + label;
			
			return label;
		}

		//
		//  Text dumps an array of ship components.
		//
		public static function encodeBASIC( buf:LByteArray, group:Array ):void
		{
			// comment, target, q, r, e, b, s, cp, sq, tl, tons, mcr
			var out:Array = [];
			
			for each (var obj:Object in group)
			{
				//
				// NEW GOAL: build a label such that the component
				// characteristics may be parsed and deduced.
				//
				var label:String = buildBasicLabel( obj );
				
				var notes:String = obj.notes || ''; // buildNotation( obj );
				
				if ( obj.howMany > 1 )
					notes = '#' + obj.howMany + ' ' + notes;
				
				// write link pointer placeholder
				buf.writeByte( 1 ); buf.writeByte( 1 ); // Link ptr lo, hi

				// then turn the tonnage into a line number
				var totalTons:int = obj.totalTons;
				var lo:int = totalTons % 256;
				var hi:int = totalTons / 256;
				
				// and write the tonnage as a line number
				buf.writeByte( lo );	buf.writeByte( hi ); // line num lo, hi

				// now build the content label
				var content:String = pad( label, 28 ) + pad( obj.totalMCr, 4, true );
				
				// and pre-pad it with spaces accordingly
				if ( totalTons < 10000 ) content = ' ' + content;
				if ( totalTons < 1000  ) content = ' ' + content;
				if ( totalTons < 100   ) content = ' ' + content;
				if ( totalTons < 10    ) content = ' ' + content;
				
				// then write it
				buf.writeUTFBytes( content );

				// finally write the trailing null
				buf.writeByte( 0 );
			}			
		}
		
		private static function buildBasicLabel( obj:Object ):String
		{
			var label:String = obj.label;
			
			//if ( obj.hasOwnProperty( 'category' ) )
			//	label = obj.category + ' ' + label;
			//else
			//	label = obj.type + ' ' + label;
			
			if ( obj.hasOwnProperty( 'howMany' ) && obj.howMany > 1 )
				label = 'x' + obj.howMany + ' ' + label;
			
			return label;
		}
		
		private static function buildNotation( obj:Object ):String
		{
			var elements:Array = [];

			if ( obj.hasOwnProperty( 'config' ) )
				elements.push( obj.config );

/*			if ( obj.hasOwnProperty( 'category' ) )
				elements.push( obj.category );
			else
				elements.push( obj.type );
*/			
			if ( obj.hasOwnProperty( 'code' ) )
				elements.push( obj.code );
			
/*			if ( obj.hasOwnProperty( 'config' ) == false
			  && obj.hasOwnProperty( 'category' ) == false )
				elements.push( obj.label );
*/			
			if ( obj.hasOwnProperty( 'notes' ) && obj.notes != null )
				elements.push( obj.notes );
			
			var label:String = elements.join( ' ' );
			return label;
		}
		
		public static function pad( text:String, len:int, padLeft:Boolean=false ):String
		{
			if ( padLeft )
			{
				text = '                                                            ' + text;
				return text.substr(text.length - len);
			}
			else
			{
				text += '                                                            ';
				return text.substr(0, len);
			}
		}
		
		public static function encodeJSON( obj:Object, pair:String=': ', indent:String='' ):String
		{
			if ( obj == null )   return '""';
			if ( obj is String ) return '"' + obj + '"';
			if ( obj is Number ) return obj.toString();
			
			var out:String = "";
			var ary:Array;
			
			if ( obj is Array )
			{
				out += "\n" + indent + "[";
				ary = new Array();
				for each (var item:Object in obj as Array)
				{
					ary.push( encodeJSON( item, pair, indent + '  ' ) );
				}
				out += ary.join( "," + '\n' + indent );
				out += "]\n";
			} 
			else if ( obj is Object )
			{
				out += "\n" + indent + "{";
				ary = new Array();
				for (var key:String in obj)
				{
					if ( key == 'mx_internal_uid' ) continue;
					ary.push( '"' + key + '"' + pair + encodeJSON( obj[key], pair, indent + '  ' ) );
				}
				out += ary.join( "," + '\n' + indent );
				out += "}\n";
			}			
			return out;
		}
		
		public static function encodeXML( obj:Object, tag:String, indent:String='' ):String
		{
			if ( obj is Number || obj is String ) return '<' + tag + '>' + obj.toString() + '</' + tag + '>';
			
			var out:String = '';
			var ary:Array;

			if ( obj is Array )
			{
				ary = new Array();
				for each (var item:Object in obj as Array)
				{
					ary.push( indent + encodeXML( item, tag, indent + '  ' ) + "\n" );
				}
				out += ary.join( '' );
			}
			else if ( obj is Object )
			{
				var values:Array = [];
				ary = new Array();
				for (var key:String in obj)
				{
					if ( key == 'mx_internal_uid' ) continue;
					
					var value:Object = obj[ key ];
					
					if ( value is Number || value is String )
					{
						values.push( key + '="' + value + '" ' );
					}
					else
					{
						ary.push( encodeXML( obj[key], key, indent + '  ' ) );
					}
				}
				out = '<' + tag + ' ' + values.join( ' ' )
					+'>' 
					+ ary.join( "" )
					+ '</' + tag + '>\n';
			}
			return out;
		}
		
		public static function decodeXML( content:String ):Object
		{
			var xml:XML = XML( content );
			var obj:Object = objectFromXML( xml );
			return obj;
		}
		
		public static function objectFromXML( xml:XML ):Object
		{
			var obj:Object = {  };
				
			// Check if xml has no child nodes and no attribs
			if (xml.hasSimpleContent() && xml.attributes().length() == 0) 
			{
				return String(xml);     // Return its value
			}
				
			// Parse out attributes:
			for each (var attr:XML in xml.@ * ) 
			{
				obj[String(attr.name())] = objectFromXML(attr);
			}
				
			// Parse out nodes:
			for each (var node:XML in xml.*) 
			{
				var localname:String = String(node.localName());
				var target:Object    = objectFromXML( node );
				
				if ( obj.hasOwnProperty( localname ) ) // found an array
				{
					if ( ( obj[ localname ] is Array ) == false )
					{
						// not yet an array, so create one
						var current:Object = obj[ localname ];
						obj[ localname ] = [];
						obj[ localname ].push( current );
					}
					// add this target to the array
					obj[ localname ].push( target );
				}
				else
				{
					obj[localname] = target;			
				}
			}
				
			return obj;
		}
		
		public static function encodeYAML( obj:Object ):String
		{
			var yaml:String = "--- " + _encodeYAML( obj );

			yaml = yaml.replace( /!actionscript.object:.*/g, "" );
			yaml = yaml.replace( /!!\w+/g, "" );
			yaml = yaml.replace( /  mx_internal_uid: .*\n/g, "" );

			return yaml + "\n"; // final newline, please!
		}
		
		public static function _encodeYAML( obj:Object, indent:String='' ):String
		{
			if ( obj is String )
			{
				var csv:Array = obj.split( ',' );
				if ( csv.length == 0 )
					return "''";
				
				var para:Array = obj.split( "\n" );
				
				if ( para.length > 1 ) // folded style
					return "|\n" + indent + para.join( "\n" + indent );
				else
				{
					var str:String = obj.toString();
					if ( str.indexOf("'") > -1 )
						return '"' + str + '"';
					else
						return "'" + str + "'";
				}
			}
			
			if ( obj is Number || obj is String ) return obj.toString();
			if ( obj == null ) return "''";
			
			var out:String = "";
			var ary:Array;
			
			if ( obj is Array )
			{
//				out += "[";
				ary = new Array();
				for each (var item:Object in obj as Array)
				{
					ary.push( "\n" + indent + "- " + _encodeYAML( item, indent + '   ' ) );
				}
				out += ary.join( "\n" );
//				out += "]\n";
			} 
			else if ( obj is Object )
			{
				var key:String;
				ary = new Array();

				if( everyValueInObjIsSimple( obj ) )
				{
				   out += '{';
				   for ( key in obj )
				   {
					  if ( key == 'mx_internal_uid' ) continue;
				      ary.push( key + ': ' + _encodeYAML( obj[ key ] ) );
				   }
				   out += ary.join( ', ' );
				   out += "}";
				}
				else
				{
					out += "\n";
					for ( key in obj)
					{
						if ( key == 'mx_internal_uid' ) continue;
						ary.push( indent + key + ': ' + _encodeYAML( obj[key], indent + '   ' ) );
					}
					out += ary.join( "\n" );
				}
			}			
			return out;
		}
		
		private static function everyValueInObjIsSimple( obj:Object ):Boolean
		{
			//
			//  For the sake of YAML::Tiny, let's make everything non-JSON.
			//
			return false;
			
			if ( obj == null ) return false; // cheap and easy shortcut
			
			for ( var key:String in obj )
			{
				if ( !(obj[ key ] is Number)
				  && !(obj[ key ] is String) 
				  && !(obj[ key ] is int)
//				  && !(obj[ key ] == null)
				  ) // nope
				{
					return false;
				}
				
				//
				//  Newlines are not simple.
				//
				if ( obj[key] is String )
				{
					var str:String = obj[key] as String;
					if ( str.indexOf( "\n" ) >= 0 )
					{
						return false;
					}
				}
			}
			return true; // ok
		}
	}
}