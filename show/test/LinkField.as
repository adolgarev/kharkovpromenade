package test {

	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextFieldAutoSize;
	import flash.events.Event;
	import flash.events.MouseEvent;

	public class LinkField extends Sprite {

		private var _text:TextField;

		public function LinkField() {
			_text = new TextField();

			buttonMode = true;
			mouseChildren = false;

			_text.autoSize = TextFieldAutoSize.LEFT;
			var tf:TextFormat = _text.defaultTextFormat;
			tf.underline = false;
			tf.color = 0x0000ff;
			tf.size = 14;
			tf.font = "Lucida Grande";
			_text.embedFonts = true;
			_text.defaultTextFormat = tf;
			_text.setTextFormat(tf);
			_text.antiAliasType = AntiAliasType.ADVANCED;
			_text.gridFitType = GridFitType.SUBPIXEL;
			
			addChild(_text);

			addEventListener(MouseEvent.MOUSE_OVER, handleOver);
			addEventListener(MouseEvent.MOUSE_OUT, handleOut);
		}

		private function handleOver(e:Event):void {
			var tf:TextFormat = _text.defaultTextFormat;
			tf.underline = true;
			_text.defaultTextFormat = tf;
			_text.setTextFormat(tf);
		}

		private function handleOut(e:Event):void {
			var tf:TextFormat = _text.defaultTextFormat;
			tf.underline = false;
			_text.defaultTextFormat = tf;
			_text.setTextFormat(tf);
		}

		public function get text():String {
			return _text.text;
		}

		public function set text(val:String):void {
			_text.text = val;
		}

	}
} 
