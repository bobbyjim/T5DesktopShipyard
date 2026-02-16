package data
{
	public class Codec
	{
		public static var instance:Codec;
		public static var codeLength:int = 8;
		
		public function Codec() {}

		public static function getInstance():Codec 
		{
			if ( instance == null )
				instance = new Codec();
			
			return instance;
		}
		
		public function setLength( item:String, length:int ):String
		{
			while ( item.length < length )
				item += ' ';
			
			return item;
		}
		
		public function getMissionCode():String
		{
			var code:String = '';
			return setLength( '2' + code, codeLength );
		}
		
		public function getHullCode():String
		{
			var code:String = '';
			return setLength( '4' + code, codeLength );
		}
		
		public function getHullFittings():Array
		{
			var fittings:Array = [];
			var code:String = '6' + '';
			return fittings;
		}
		
		public function getJumpField():String
		{
			var code:String = '';
			return '7' + code;
		}
		
		public function getArmor():String
		{
			var code:String = '';
			return '8' + code;
		}
		
		public function getDrives():Array
		{
			var drives:Array = [];
			var code:String = '9' + '';
			return drives;
		}
		
		public function getFuelFittings():Array
		{
			var fuelFittings:Array = [];
			var code:String = 'B' + '';
			return fuelFittings;
		}
		
		public function getSensors():Array
		{
			var sensors:Array = [];
			var code:String = 'D' + '';
			return sensors;
		}
		
		public function getWeapons():Array
		{
			var weapons:Array = [];
			var code:String = 'E' + '';
			return weapons;
		}
		
		public function getDefenses():Array
		{
			var defenses:Array = [];
			var code:String = 'F' + '';
			return defenses;
		}
		
		public function getOps():Array
		{
			var ops:Array = [];
			var code:String = 'G' + '';
			return ops;
		}
		
		public function getControls():Array
		{
			var controls:Array = [];
			var code:String = 'H' + '';
			return controls;
		}
		
		public function getPayload():Array
		{
			var payload:Array = [];
			var code:String = 'K' + '';
			return payload;
		}
	}
}