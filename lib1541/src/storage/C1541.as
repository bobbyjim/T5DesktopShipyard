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
/**
 * class C1541 - simple SerialBus and C1541 emulation.
 * - will not support everything but the usual simplest
 * CBM dos stuff. No fastloading, etc.
 * Might add full 1541 emulation later with CPU + IO chip
 * emulation.
 *
 * Adapted from JAC64
 * 
 **/
{
	import storage.DiskChannel;
	import storage.LByteArray;
	import storage.formats.Storable;


	public class C1541
	{
		public static var IO_START:int = 0x15000;
		public static var IO_END:int = 0x15dff;
		public static var IO_FLAG:int = 0x08;
		
		public static var IO_OFFSET:int = 0x15000 - 0xd000; // CPU.IO_OFFSET;
		
		public static var SERIAL_ATN:int = (1 << 3);
		public static var SERIAL_CLK_OUT:int = (1 << 4);
		public static var SERIAL_DATA_OUT:int = (1 << 5);
		public static var SERIAL_CLK_IN:int = (1 << 6);
		public static var SERIAL_DATA_IN:int = (1 << 7);
		
		public static var TALK:int = 0x40;
		public static var LISTEN:int = 0x20;
		public static var DATA:int = 0x60;
		public static var OPEN:int = 0xf0;
		public static var CLOSE:int = 0xf0;

		private var memory:Array = []; // of int; CPU memory
		private var reader:Storable;   // disk reader

		private static var IDLE:int = 0;
		private static var ATN:int = 1;
		private static var RECEIVING:int = 2;
		private static var SENDING:int = 3;
		private static var READ_BIT:int = 4;
		private static var WAIT_BIT:int = 5;
		private static var READ_BYTE:int = 6;
		private static var WRITE_BYTE:int = 7;
		
		private static var LOAD_FILE:int = 1;
		private static var SAVE_FILE:int = 2;
		private static var LOGICAL_CHANNEL:int = 3;
		
		private static var ATN_SEEN:int = 10;
		private static var ATN_READ_BIT:int = 11;
		private static var ATN_WAIT_BIT:int = 12;
		
		private static var WAIT_LISTENER_READY:int = 13;
		private static var WRITE_BIT_CLK1:int = 14;
		private static var WRITE_BIT_CLK2:int = 15;
		private static var WRITE_END:int = 16;
		private static var WAIT_LISTENER_EOI_HANDSHAKE:int = 17;
		
		private static var READ_FILENAME:int = 1;
		
		private var channel:Array = [
			new DiskChannel(0),			new DiskChannel(1),			new DiskChannel(2),			new DiskChannel(3),
			new DiskChannel(4),			new DiskChannel(5),			new DiskChannel(6),			new DiskChannel(7),
			new DiskChannel(8),			new DiskChannel(9),			new DiskChannel(10),		new DiskChannel(11),
			new DiskChannel(12),		new DiskChannel(13),		new DiskChannel(14),		new DiskChannel(15)
			];

		private var atnLast:Boolean = false;
		private var mode:int = IDLE;
		private var eoiTimeout:int = 0;
		private var eoi:int;
		private var lastChar:Boolean = false;

		private var role:int = 0;
		private var floppyMode:int = 0;
		private var floppyChannel:int = 0;
		private var filename:String;
		
		// For example when reading bytes and waits for EOI
		private var waitTimeout:int = 0;
		
		private var readMode:int = READ_FILENAME;
		private var tmpFilename:String = "";

		public function C1541( mem:Array )
		{
			this.memory = mem;
			// reader = new C64Reader();
		}
		
		public function reset():void 
		{
			mode = IDLE;
			role = 0;
			rbState = 0;
			rbByte = 0;
			floppyMode = 0;
			floppyChannel = 0;
			clockHi();
		}
	
	/*		
		public C64Reader getReader() {
			return reader;
		}
	*/
		private function clockLo():void {
			memory[IO_OFFSET + 0xdd00] &= ~SERIAL_CLK_IN;
		}
		
		private function clockHi():void {
			memory[IO_OFFSET + 0xdd00] |= SERIAL_CLK_IN;
		}
		
		public function dataLo():void {
			memory[IO_OFFSET + 0xdd00] &= ~SERIAL_DATA_IN;
		}
		
		public function dataHi():void {
			memory[IO_OFFSET + 0xdd00] |= SERIAL_DATA_IN;
		}

		
		public function tick( cycles:int ):void
		{
			if (waitTimeout != 0 && waitTimeout < cycles) 
			{
				trace(".");
				tick2(cycles, true);
			}			
		}
		
		public function tick2( cycles:int, timeout:Boolean ):void
		{
			var data:int = memory[IO_OFFSET + 0xdd00];
			var atn:Boolean = (data & SERIAL_ATN) != 0;
			var dataOut:Boolean = (data & SERIAL_DATA_OUT) != 0;
			var clkOut:Boolean = (data & SERIAL_CLK_OUT) != 0;
			var atnInvoked:Boolean = atn && !atnLast; // was: atn & !atnLast
			
			switch (mode) {
				// IDLE mode - just waiting... set data to high...
				case READ_BYTE:
					if (atnInvoked) {
						mode = IDLE;
						return;
					}
					
					var b:int = readByte(data, cycles, false, timeout);
					if (b != 0) {
						mode = IDLE;
						if (atn) {
							handleATNByte(b);
						} else {
							trace("//// Read byte: " + b // Integer.toString(b, 16) 
								+ " => " + b); // ((char) b));
							dataLo();
							if (readMode == READ_FILENAME) {
								tmpFilename += b; // (char) b;
								if (lastChar) {
									trace("Filename: " + tmpFilename);
									filename = tmpFilename;
								}
							}
						}
					}
					break;
				case WRITE_BYTE:
				if (atnInvoked) {
					mode = IDLE;
					return;
				}
				if (writeByte(data, cycles, timeout)) {
					// When all is read - reset!
					reset();
				}
				break;
				case ATN_SEEN:
				if (atn && !clkOut) {
					dataHi();
					mode = READ_BYTE;
					// Start up for reading a byte...
					readByte(data, cycles, true, false);
					
				} else if (!atn) {
					mode = IDLE;
				}
				break;
				case IDLE:
				if (atn && clkOut) { // was: atn & clkOut
					trace("C1541: ATN Seen...");
					dataLo();
					mode = ATN_SEEN;
				}
				if (!atn && role == TALK) {
					// Here we should talk more...
					if (!clkOut && dataOut) {
						mode = WRITE_BYTE;
						initWrite(cycles);
					}
				} else if (!atn && role != 0) {
					if (!clkOut) {
						mode = READ_BYTE;
						readByte(data, cycles, true, false);
					}
				}
				break;
			}
			atnLast = atn;
		}

		private var rbState:int;
		private var rbByte:int;
		private var rbCtr:int = 0;
		private var eoiCtr:int = 0;

		private function readByte( data:int, cycles:int, restart:Boolean, timeout:Boolean ):int 
		{
				var dataOut:Boolean = (data & SERIAL_DATA_OUT) != 0;
				var clkOut:Boolean = (data & SERIAL_CLK_OUT) != 0;
				
				if (restart) {
					// Set everything to "low" and go...
					rbCtr = 0;
					rbByte = 0;
					rbState = WAIT_BIT;
					dataHi();
					trace("Start reading byte - data lo");
					waitTimeout = 200 + cycles;
					eoiCtr = 0;
					lastChar = false;
					return 0;
				}
				
				if (timeout) {
					trace("//// EOI Timeout???");
					if (eoiCtr == 0) {
						trace("//// EOI 1 => dataLo");
						dataLo();
						waitTimeout = 80 + cycles;
					} else {
						trace("///// EOI 2 => dataHi");
						dataHi();
						// No more timeout...
						waitTimeout = 0;
						lastChar = true;
					}
					eoiCtr++;
				}
				
				if (rbState == WAIT_BIT) {
					if (clkOut)
						rbState = READ_BIT;
				} else {
					if (!clkOut) {
						rbByte |= dataOut ? 0 : (1 << rbCtr);
						// 	System.out.println("//// Read bit: " + rbCtr + " => " + rbByte);
						rbState = WAIT_BIT;
						rbCtr++;
						waitTimeout = 0;
					}
				}
				
				if (rbCtr == 8) {
					return rbByte;
				}
				return 0;
			}
		
		private var wByte:int;
		private var wBitPos:int;
		private var wBytePos:int;
		private var wState:int;
		private var wCyclesWait:int;
		private var bytesToWrite:LByteArray; // was: byte[]
		private var wEOI:Boolean = false;

	
		private function initWriteByte( data:int, cycles:int ):void 
		{
			var b:int = data > 0x20 ? data : 0x2e; // was: ' ' and '.';
			trace("***>> InitW: " +
				(data & 0xff) // Integer.toString(data & 0xff, 16) 
				+ " '" + b // (char) b
				+ "' ");
			wByte = data;
			wBitPos = 0;
			
			// at least 100 us between the bytes
			wCyclesWait = cycles + 100;
			
			// Ensure that we get ticks!!!!
			waitTimeout = cycles + 100;
			
			wState = WAIT_LISTENER_READY;
		}
	
		private function writeByte( data:int, cycles:int, timeout:Boolean ):Boolean 
		{
			var dataOut:Boolean = (data & SERIAL_DATA_OUT) != 0;
			
			// Do nothing if we are waiting for something...
			if (wCyclesWait > cycles) {
				//       System.out.println("Waiting until: " + wCyclesWait + " now: " +
				// 			 cycles);
				return false;
			}
			//     System.out.println("wState:" + wState);
			switch (wState) {
				case WAIT_LISTENER_READY:
					clockHi();
					if (!dataOut) {
						// If no file - exit here => file not found error...
						if (bytesToWrite == null) {
							waitTimeout = 0;
							return true;
						}
						if (!wEOI) {
							trace("[R]");
							wState = WRITE_BIT_CLK2;
						} else {
							trace("[R(EOI)]");
							wState = WAIT_LISTENER_EOI_HANDSHAKE;
						}
						// no wait for the first bit! (should call this method again)
					} else
						trace("[-R]");
					break;
				case WAIT_LISTENER_EOI_HANDSHAKE:
					if (dataOut) {
						trace("EOI handshake!!!");
						wEOI = false;
						wState = WAIT_LISTENER_READY;
					}
					break;
				case WRITE_BIT_CLK1:
					// C64 is waiting while the clock is low - as soon as clock
					// is high it will read the data!
					// Set bit and make clock low!
					if ((wByte & (1 << wBitPos)) == 0) {
						// 	System.out.println("* Write bit " + wBitPos + " low");
						dataLo();
					} else {
						// 	System.out.println("* Write bit " + wBitPos + " high");
						dataHi();
					}
					wBitPos++;
					clockHi();
					wCyclesWait = cycles + 70;
					if (wBitPos < 8) {
						wState = WRITE_BIT_CLK2;
					} else {
						wState = WRITE_END;
					}
					break;
				case WRITE_BIT_CLK2:
					// Set clock back to low - to indicate that another byte
					// is coming up!
					clockLo();
					dataLo();
					wCyclesWait = cycles + 70;
					wState = WRITE_BIT_CLK1;
					break;
				case WRITE_END:
					clockLo();
					if (dataOut) {
						trace("Ack: " + memory[0xa4] ); //	Integer.toString(memory[0xa4], 16));
						wBytePos++;
						
						if ((wBytePos % 10) == 0) {
							//setChanged();
							trace("Loading " + filename + " " + (100 * wBytePos) /   // was: notifyObservers
								bytesToWrite.length + "%"); 
						}
						
						if (wBytePos == bytesToWrite.length - 1) {
							wEOI = true;
						} else if (wBytePos >= bytesToWrite.length) {
							waitTimeout = 0;
							wEOI = false;
							trace("******** Write finished!!!");
							//setChanged();
							//notifyObservers("");
							return true;
						}
						initWriteByte(bytesToWrite[wBytePos], cycles);
					}
					break;
			}
			return false;
		}
		
		private function initWrite(cycles:int):void 
		{
			// Do stuff with all sorts of things...
			// Floppy channel, filename, etc.
			// Filename
			
			clockLo();
			wBytePos = 0;
			wEOI = false;
			
			if (floppyMode == LOAD_FILE) {
				//ByteArrayOutputStream out = new ByteArrayOutputStream();
				var out:LByteArray = new LByteArray();
				
				if ((filename = reader.readFile(filename, -1, out)) != null) 
				{
					bytesToWrite = out; // .toByteArray();
					trace("C1541 has " + bytesToWrite.length +
						" bytes to write");
					
					initWriteByte(bytesToWrite[0], cycles);
				} else {
					// Error???
					trace("File not found... should signal error...");
					bytesToWrite = null;
					initWriteByte(0, cycles);
				}
			}
			if (floppyMode == LOGICAL_CHANNEL) {
				trace("Should write logical channel data!");
				bytesToWrite = channel[floppyChannel].getData();
				
				initWriteByte(bytesToWrite[0], cycles);
			}
		}
		
		
		
		private function handleATNByte( data:int):void 
		{
			var cmd:int = data & 0xf0;
			var dev:int = data & 0x1f;
			var secAdr:int = data & 0x0f;

			trace("ATN Byte: " + data + " " + data ); // Integer.toString(data, 16));
				
			switch (cmd) {
				case TALK:
				case TALK + 0x10:
					role = 0;
					if (dev == 31) {
						trace("  >> UNTALK!!!");
					} else {
						trace("  Received TALK for dev: " + dev);
						if (dev == 8) {
							trace("### DEV: 8 ACTIVE as 1541!");
							role = TALK;
						}
					}
					break;
				case LISTEN:
				case LISTEN + 0x10:
					role = 0;
					if (dev == 31) {
						trace("  >> UNLISTEN!!!");
						if (floppyMode == LOGICAL_CHANNEL) {
							
							// Should load and set data too!
							//ByteArrayOutputStream out = new ByteArrayOutputStream();
							var out:LByteArray = new LByteArray();
							
							if ((tmpFilename = reader.readFile(tmpFilename, -1, out)) != null) 
							{
								channel[floppyChannel].setData(out); // .toByteArray());
								trace("Setting channel " + floppyChannel +
									" to " + tmpFilename + " size: " +
									channel[floppyChannel].getData().length);
								channel[floppyChannel].setFilename(tmpFilename);
								filename = tmpFilename;
							} else {
								trace("#### File not found error???");
							}
						}
					} else {
						trace("  Received LISTEN for dev: " + dev);
						if (dev == 8) {
							trace("### DEV: 8 ACTIVE as 1541!");
							role = LISTEN;
						}
					}
					break;
				case OPEN:
					trace("### OPEN sec addr: " + secAdr);
					tmpFilename = "";
					readMode = READ_FILENAME;
					if (secAdr == 0) {
						trace("### => LOAD File!");
						floppyMode = LOAD_FILE;
					} else if (secAdr == 1) {
						trace("### => SAVE File!");
						floppyMode = SAVE_FILE;
						readMode = READ_FILENAME;
					} else if (secAdr == 15) {
						trace("### => Error...");
					} else {
						trace("Logical channel: " + secAdr);
						floppyMode = LOGICAL_CHANNEL;
						floppyChannel = secAdr;
					}
				case CLOSE:
					trace("### Close: secAdr: " + secAdr);
					channel[secAdr].close();
					break;
				case DATA:
					trace("### DATA sec addr: " + secAdr);
					// Set current channel to this!
					trace("Setting floppy channel!");
					floppyChannel = secAdr;
					break;
			}
		}
			
		public function handleDisk( data:int, cycles:int ):void 
		{
			//     System.out.println("---- SerialBus: " + data + " ------");
			
			trace("W:");
			printSerial(data);
			tick2(cycles, false);
		}
		
		public static function printSerial(data:int):void 
		{
			if ((data & SERIAL_ATN) != 0) {
				trace("A1");
			} else {
				trace("A0");
			}
			
			var sdata:int = (data & SERIAL_CLK_OUT) != 0 ? 1 : 0;
			trace(" C" + sdata);
			sdata = (data & SERIAL_DATA_OUT) != 0 ? 1 : 0;
			trace(" D" + sdata);
			
			sdata = (data & SERIAL_CLK_IN) != 0 ? 1 : 0;
			trace(" c" + sdata);
			sdata = (data & SERIAL_DATA_IN) != 0 ? 1 : 0;
			trace(" d" + sdata);
		}		
	}
}