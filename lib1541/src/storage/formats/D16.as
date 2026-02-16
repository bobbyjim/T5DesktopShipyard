/*
 * Copyright notice
 *
 * (c) 2010 Robert Eaglestone.  All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */
package storage.formats
/*
    D16 format
    
    Based on formats used by Ruud Baltissen  (http://www.baltissen.org/newhtm/1541ide8.htm).
    This version has 255 tracks, with 248 sectors per track, for about 15.8 megabytes.

    Header             = 18,0
    BAM                = 18,1-32
    Directory          = 18,33-255
    DOS Type           = 82    // version D16 format
    DOS Version/Format = '2R'  // DOS-version and format
    Disk Name          = 16 bytes
    $A0
    
    BAM is 31 bytes per track.
*/
{
	import storage.CMD;

	public class D16 extends CMD implements Storable
	{
		public function D16(fn:String=null)
		{
			super(fn);

		    EXTENSION 					 = 'D16';
			DOS_VERSION                  = 'R';
			DOS_TYPE                     = '2R';
			
			var zones:Array   = [[255,248]];
			var header:int    = 18;
			var dir:int       = 18;
			var bam:int       = 18;
			var dirSector:int = 33;
			var hdrNameOffset:int = 0x04;
			var bamOffset:int = 0x06;
			var bamInterleave:int = 1;
			var bamHasSectorCount:Boolean = false; // gets us 8 more sectors per track
			
			this.configure( zones, 
							false, 
							false, 
							header, 
							dirSector, 
							hdrNameOffset, 
							bamOffset, 
							bamInterleave, 
							true,
							1, 1,
							false,
							bamHasSectorCount );		
		}	
	}
}			
