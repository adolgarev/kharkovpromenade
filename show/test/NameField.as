package test {

	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextFieldAutoSize;
	import flash.display.CapsStyle;
	import flash.display.LineScaleMode;

	public class NameField extends Sprite { 

		private var _text:TextField;

		public function NameField() {
			_text = new TextField();
			_text.x = 8;
			_text.y = 15;

			_text.autoSize = TextFieldAutoSize.LEFT;
			var tf:TextFormat = _text.defaultTextFormat;
			tf.size = 21;
			tf.font = "Times New Roman";
			tf.bold = true;
			//_text.embedFonts = true;
			_text.defaultTextFormat = tf;
			_text.setTextFormat(tf);
			_text.antiAliasType = AntiAliasType.ADVANCED;
			_text.gridFitType = GridFitType.SUBPIXEL;
			
			addChild(_text);
			
			graphics.lineStyle(7, 0xBBBBBB, 1.0, true, LineScaleMode.NORMAL, CapsStyle.NONE);
			graphics.moveTo(3, 10);
			graphics.lineTo(3, 45);
			graphics.lineStyle(1, 0xCCCCCC, 1.0, true, LineScaleMode.NORMAL, CapsStyle.NONE);
			graphics.lineTo(619, 45);
		}

		public function get text():String {
			return _text.text;
		}

		public function set text(val:String):void {
			_text.text = val;
		}

	}
}