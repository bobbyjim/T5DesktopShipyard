package storage.formats
	/*
	*
	*   D20 format
	* 
	* This is a test format using programmatic configuration.  
	* 
	* Its configuration has a BAM which can address 100k of storage:
	* 416 sectors, in 13 tracks of 32 sectors each, and a 5-byte BAM.
	* 
	* Its header, directory, and BAM are all on track 1, the BAM shares sector 0
	* with the header, and the directory begins on sector 1, just like the D64.  
	* All interleaves are 1, the disk name offset is 0x04, and the BAM data starts
	* at 0x1C.
	*/
{
	import storage.CMD;
	import storage.LByteArray;
	
	public class D10 extends CMD implements Storable
	{
		public function D10(fn:String=null)
		{
			super(fn);
			
			var zones:Array 			= [ [13,32] ];
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
				bamOffset );		}
	}
}