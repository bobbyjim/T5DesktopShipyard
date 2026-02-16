/*
 * Copyright notice
 *
 *  (c) 2011 Robert Eaglestone.  All rights reserved.
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
package storage
/*
 * Simple implementation of a disk channel
 * adapted from JAC64 source.
 */
{
	public class DiskChannel
	{
		private var _filename:String;
		private var _data:LByteArray;
		private var _open:Boolean;
		private var chID:int;
		
		public function DiskChannel( chID:int )
		{
			this.chID = chID;
		}
		
		public function set filename( name:String ):void
		{
			_filename = name;
		}
		
		public function set data( data:LByteArray ):void
		{
			_data = data;
		}
		
		public function get data():LByteArray
		{
			return _data;
		}
		
		public function readChar():int
		{
			if ( _data.bytesAvailable == 0 ) return -1;
			return _data.readByte() & 0xff;
		}
		
		public function open():void
		{
			_open = true;
			_data.position = 0;
		}
		
		public function close():void
		{
			_open = false;
		}
	}
}
