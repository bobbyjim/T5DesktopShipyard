/*
* Copyright notice
*
* (c) 2012 Robert Eaglestone.  All rights reserved.
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
	 *
	 *   D28 format
	 * 
	 * This is a test format using programmatic configuration.  
	 * 
	 * It is designed for storing small programs with a minimal number of
	 * files (up to 8).
	 * 
	 * It has two zones: the first zone has 1 track with 2 sectors; 
	 * the second zone has 23 tracks of 8 sectors each.  The image has a
	 * 2-byte BAM.  Total space for file data is 23 * 8 / 4 = 46k.
	 * 
	 * Its header, directory, and BAM are all on track 1, the BAM shares sector 0
	 * with the header, and the directory exists entirely on sector 1.  This means
	 * there is only room for up to 8 file entries.
	 *   
	 * All interleaves are 1, the disk name offset is 0x04, and the BAM data starts
	 * at 0x1C. 
	 */
{
	import storage.CMD;
	import storage.LByteArray;
	import storage.formats.Storable;
	
	public class D28 extends CMD implements Storable
	{
		public function D28(fn:String=null)
		{
				super(fn);

				var zones:Array 			= [ [1,2], [23,8] ];
				var doubleSided:Boolean 	= false;
				var errorBytes:Boolean 		= false;
				var headerTrack:int 		= 1;
				var dirSector:int 			= 1;
				var hdrDiskNameOffset:int 	= 0x04;
				var bamOffset:int 			= 0x1c;

				configure( zones, 
					doubleSided,
					errorBytes,
					headerTrack,
					dirSector,
					hdrDiskNameOffset,
					bamOffset );
		}
	}
}