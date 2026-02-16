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
	Commodore Disk Image
	
	What it is: flexible image format which parametrically stores the disk's structure 
 in an initial configuration block.  This promotes a generalized parsing engine, 
 allows dynamic disks which grow into their allocation only when necessary, 
 and opens up experimentation on novel image structures without having to write
 custom parsers.

	Offs.  Len  Element
	---------------------------------------------------------------
	00-1C  28   Signature "COMMODORE BUSINESS MACHINES", $00 ended
	
	1D     1    DOS Type - e.g. 0x2A, 0x2C, 0x3D
				- "DOS Version" is the 2nd character in the DOS Type field.

	1E     1    Header track number            
	            - header sector is always 0
	            - header T/S points to first directory sector

	1F     1    Header label byte offset - e.g. $04, $06, $90
				  "HDR Label" is the disk label, ID, and DOS Type (23 bytes length).
	
	20-27  8    Zones: ending track # and number of sectors
	
	28     1    "Double-sided" flag/BAM FSC split value
				- 0x00 if the image is single-sided
				- 0x01 if single-sided BUT WITHOUT FREE SECTOR COUNT BYTES
	            - 0x02-0x7f single-sided
				- 0x80 if double-sided with the FSC split (like the D71, which splits the free sector count from the remainder of its BAM).  That "other value" is the FSC split value.
	            - 0x81 if double-sided BUT WITHOUT FREE SECTOR COUNT BYTES
	            - 0xff if double-sided with the FSC split (like the D71, which splits the free sector count from the remainder of its BAM).  That "other value" is the FSC split value.
	

	29     1    BAM byte offset (0=0x04)
	2A     1    BAM label offset (0=0x00)
				- If BAM label offset > number of sectors, treat as Track number, sector 0, side 2 FSC byte offset.

	2B     1    BAM interleave (0=0x01)
				- The first BAM sector is 0, UNLESS the interleave is 1, in which case it begins in sector 1.
				- The final BAM sector points to EOF (00/FF). 
				  (8x50 doesn't do this, but I don't care and nobody else does, either.)

	2C     1    DIR interleave (0=0x01)
				- The first DIR sector is 1, UNLESS the BAM sector is 1, in which case it follows the BAM.
				- The final DIR sector points to 00/FF.
	
	2D     1    FIL interleave (0=0x01)
	2E     1    8x50 flag: Put BAM on (Header Track - 1).
	2F     1    D81 flag: Use extended BAM label on BAM sectors.
	            The extended "header label" for BAM sectors is:
	            - the 2 byte Disk ID
	            - the I/O byte
	            - and the autoboot flag
*/
{
	import flash.utils.ByteArray;
	
	import storage.CMD;
	import storage.LByteArray;

	public class R64 extends CMD implements Storable
	{
		public function R64(fn:String=null)
		{
			super(fn);
			
			EXTENSION 					 = 'R64';
			DOS_VERSION                  = 'R';
			DOS_TYPE                     = '0R';
		}
		
		public function test():void
		{
			configure();
		}

		override public function initializeReading( bytes:ByteArray ):ByteArray
		{
			// here is where we strip off the R64 disk configuration
			// first, read off the R64 disk configuration and initialize
			var len:int = readImageConfiguration( bytes );
			
			var disk:ByteArray = new LByteArray();
			bytes.position = len;
			disk.length = bytes.bytesAvailable;
			disk.writeBytes( bytes, len );
			disk.position = 0;

			return disk;
		}

		override public function finalizeWriting( data:LByteArray ):LByteArray
		{
			// here is where we prepend the R64 disk configuration
			var image:LByteArray = writeImageConfiguration();
			image.length += data.length;
			image.writeBytes( data );
			
			return image;
		}
		
		/**
		 * 
		 * returns the number of bytes in the configuration
		 *
		 **/
		public function readImageConfiguration( dat:ByteArray ):int
		{
 			dat.position = 0x00;
			var sig:String         = readString( dat, 0x1d ); // 00-1C
			var dosType:int        = dat.readByte() && 0xff;  // 1D
			var hdrTrack:int       = dat.readByte() && 0xff;  // 1E
			var hdrOffset:int      = dat.readByte() && 0xff;  // 1F
			var zones:Array  = [];
			var totalTracks:int = 0;
			var totalSectors:int = 0;
			for( var i:int=0; i<4; i++ )                      // 20-27
			{
				var t:int = dat.readByte() && 0xff;
				var spt:int = dat.readByte() && 0xff;
				totalTracks += t;
				totalSectors += t * spt;
				zones[i] = [t,spt];
			}
			var doubleSided:int    = dat.readByte() && 0xff;  // 28
			var bamOffset:int      = dat.readByte() && 0xff;  // 29
			var bamLabelOffset:int = dat.readByte() && 0xff;  // 2A
			var bamInterleave:int  = dat.readByte() && 0xff;  // 2B
			var dirInterleave:int  = dat.readByte() && 0xff;  // 2C
			var filInterleave:int  = dat.readByte() && 0xff;  // 2D
			var o8x50Flag:int      = dat.readByte() && 0xff;  // 2E - put BAM on HDR TRK - 1
			var o1581Flag:int      = dat.readByte() && 0xff;  // 2F - use extended BAM label
			var errorSectors:int   = dat.readByte() && 0xff;  // 30

			var bamPrependInterleave:Boolean = (bamInterleave > 1);
			var bamPointsToDirectory:Boolean = false; // because noone cares			
			var bamHasSectorsFreeCount:Boolean = ((doubleSided & 0x01) > 0);
			var bamHeaderHasDosVersion:Boolean = (o1581Flag != 0);
			
			var dirTrack:int = hdrTrack;
			var bamTrack:int = hdrTrack;
			
			if ( o8x50Flag && 0x01 == 1 ) bamTrack = hdrTrack - 1;

			var bamBytesPerTrack:int  = Math.ceil( totalSectors / 8 );
			if ( bamHasSectorsFreeCount ) bamBytesPerTrack++;

			var bamTracksPerBlock:int = Math.floor( (256 - bamOffset)/bamBytesPerTrack );
			var bamSectors:int        = Math.ceil( totalTracks / bamTracksPerBlock );

			var dirSector:int = 1;
			
			if ( bamInterleave == 1 && bamTrack == hdrTrack ) 
			{
				// now we get to figure out where the directory starts.  wheeee.
				dirSector = bamSectors + 1;
			}

			// dat.writeBytes( ERROR_BYTES, 0, errorSectors * 0x100 ); // read in error sectors

			var cfgLength:int = 0x100; // 256 bytes always

			configure( zones,
					   doubleSided > 0x10,
					   errorSectors > 0,
					   hdrTrack,
					   dirSector,
					   hdrOffset,
					   bamOffset,				
					   bamInterleave,
					   bamPrependInterleave,
					   filInterleave,
					   dirInterleave,
					   bamPointsToDirectory,
					   bamHasSectorsFreeCount,
					   bamHeaderHasDosVersion,
					   dirTrack,
					   bamTrack );
			
			return cfgLength;
		}

		public function writeImageConfiguration():LByteArray
		{
			var cfg:LByteArray = new LByteArray();
 
			writeString( cfg, "COMMODORE BUSINESS MACHINES", 0x1d );

			/*
			var errorSectors:int = countErrorSectors();
						
			cfg.writeByte( errorSectors );        // 2A
			cfg.writeByte( DOUBLE_SIDED? 1:0 );   // 2B
			
			for each ( var zone:Array in ZONES )  // 2C-33 in pairs (T, S per T)
			{
				cfg.writeByte( zone[0] );
				cfg.writeByte( zone[1] );
			}
			
			cfg.writeByte( HEADER_TRACK );        // 34
			cfg.writeByte( HEADER_DISK_NAME_BYTE_OFFSET ); // 35
			cfg.writeByte( FILE_INTERLEAVE );     // 36
			cfg.writeByte( DIRECTORY_TRACK );     // 37
			cfg.writeByte( DIRECTORY_SECTOR );    // 38
			cfg.writeByte( DIRECTORY_INTERLEAVE );// 39
			cfg.writeByte( BAM_TRACK );           // 3A
			cfg.writeByte( 0x00 );                // 3B
			cfg.writeByte( BAM_BYTE_OFFSET );     // 3C
			cfg.writeByte( BAM_INTERLEAVE );      // 3D
			cfg.writeByte( BAM_POINTS_TO_DIRECTORY? 1:0 ); // 3E
			cfg.writeByte( BAM_PREPEND_INTERLEAVE? 1:0 );      // 3F

			cfg.length = 0x40 + errorSectors * 0x100; // make room for error sectors
			*/
			
			return cfg;
		}

		private function countErrorSectors():int
		{
			if ( ERROR_BYTES_PRESENT == false )
				return 0;
			else 
			if ( DOUBLE_SIDED )
				return 6;
			
			return 3;
		}
	
	}
}