package test {

	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormatAlign;

	public class Info extends Sprite { 

		private var _data:Object;
		private var _text:TextField;

		public function Info(data:Object) {
			_data = data;

			_text = new TextField();
			_text.multiline = true;

			_text.autoSize = TextFieldAutoSize.LEFT;
			var tf:TextFormat = _text.defaultTextFormat;
			tf.size = 16;
			tf.font = "Times New Roman";
			tf.align = TextFormatAlign.RIGHT;
			//_text.embedFonts = true;
			_text.defaultTextFormat = tf;
			_text.setTextFormat(tf);
			_text.antiAliasType = AntiAliasType.ADVANCED;
			_text.gridFitType = GridFitType.SUBPIXEL;

			_text.text = "";
			_text.appendText("creation date: " + _data.creationDate + "\n");
			_text.appendText("modification date: " + _data.modificationDate + "\n");
			_text.appendText("owner: " + _data.owner);
			
			
			tf.color = 0x555555;
			var p:int;
			_text.setTextFormat(tf, 0, "creation date: ".length);
			p = "creation date: ".length + _data.creationDate.length + 1;
			_text.setTextFormat(tf, p, p + "modification date: ".length);
			p += "modification date: ".length + _data.modificationDate.length + 1;
			_text.setTextFormat(tf, p, p + "owner: ".length);


			addChild(_text);
		}
	}
} 
