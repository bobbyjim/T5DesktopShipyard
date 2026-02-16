package data
{
	public class ExpressionEngine
	{
		public function ExpressionEngine()
		{
		}
		
		public static function calculateMCr( obj:Object ):Number
		{
			//
			//  Expressions are of the form:
			//
			//  Ax
			//
			//  or
			//
			//  Ax + By
			//
			//  In other words, a string of sums.
			//
			//
			//  Where "A" and "B" is a number, and "x" and "y" are either symbols, or nonexistent.
			//
			//  Example: a cost function might be
			//
			//  0.5 $this.tons + 0.01 $hull.tons
			//
			//  In other words, MCr 0.5 x component tons + MCr 0.01 x hull tons.
			//
			return 1.0
		}
		
		public static function calculateTons( obj:Object ):Number
		{
			return 1.0
		}
	}
}