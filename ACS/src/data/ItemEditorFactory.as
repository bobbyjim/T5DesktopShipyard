package data
{
	import component.itemEditors.DriveItemEditor;
	import component.itemEditors.NoItemEditor;
	
	import spark.components.Group;

	public class ItemEditorFactory
	{
		public function ItemEditorFactory()
		{
			// no op
		}

		public static function itemEditorFor( thingy:Object ):Group
		{
			var category:String = thingy.category;
			var editor:NoItemEditor;
			
			if ( thingy.type == 'Drive' && category.match( /Fuel/ ) == null )
			{
				editor = new DriveItemEditor();
				editor.setThingy( thingy );
				return editor;
			}
			
			return new NoItemEditor();
		}
	}
}