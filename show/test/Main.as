package test {
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextFieldAutoSize;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.display.CapsStyle;
	import flash.display.LineScaleMode;

	import test.LinkField;
	import test.NameField;

	public class Main extends Sprite {

		private var _next:LinkField;
		private var _prev:LinkField;
		private var _name:NameField;
		private var _num:TextField;
		private var _hr:Sprite;


		private var _loader:Loader;

		private var _data:Object;
		private var _path:String;
		private var _pos:uint;


		public function Main(data:Object, path:String) {
			_data = data;
			_path = path;

			_loader = new Loader();
			addChild(_loader);

			_name = new NameField();
			addChild(_name);

			_num = new TextField();
			_num.autoSize = TextFieldAutoSize.LEFT;
			var tf:TextFormat = _num.defaultTextFormat;
			tf.size = 14;
			tf.font = "Times New Roman";
			//_num.embedFonts = true;
			_num.defaultTextFormat = tf;
			_num.setTextFormat(tf);
			_num.antiAliasType = AntiAliasType.ADVANCED;
			_num.gridFitType = GridFitType.SUBPIXEL;
			addChild(_num);

			_next = new LinkField();
			_next.text = "Next";
			_next.addEventListener(MouseEvent.CLICK, handleNext);
			addChild(_next);
			
			_prev = new LinkField();
			_prev.text = "Prev";
			_prev.addEventListener(MouseEvent.CLICK, handlePrev);
			addChild(_prev);

			_hr = new Sprite();
			_hr.graphics.lineStyle(1, 0x888888, 1.0, true, LineScaleMode.NORMAL, CapsStyle.NONE);
			_hr.graphics.moveTo(3, 0);
			_hr.graphics.lineTo(619, 0);
			addChild(_hr);
		}

		public function postAdd():void {
			stage.addEventListener(Event.RESIZE, layoutElements);
			showElement(0);
			layoutElements();
		}


		private function handleNext(e:Event = null):void {
			showElement(_pos + 1);
		}

		private function handlePrev(e:Event = null):void {
			showElement(_pos - 1);
		}


		private function showElement(i:uint):void {
			_pos = i;

			_loader.load(new URLRequest(_path + _data.data[i].src));
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, layoutElements);

			_next.visible = true;
			_prev.visible = true;
			if (i == 0)
				_prev.visible = false;
			if (i >= _data.data.length - 1)
				_next.visible = false;

			_name.text = _data.data[i].name;
			_num.text = String(i + 1) + "/" + String(_data.data.length);
		}

		public function layoutElements(e:Event = null):void {
			_next.x = 624 - _next.width;
			_prev.x = _next.x - _prev.width - 2;
			_next.y = stage.stageHeight - _next.height - 5;
			_prev.y = stage.stageHeight - _prev.height - 5;

			_num.x = 0;
			_num.y = stage.stageHeight - _num.height - 5;

			_hr.x = 0;
			_hr.y = _next.y - 3;

			if (_loader.contentLoaderInfo.content != null) {
				var max_available_width:int = stage.stageWidth;
				var max_available_height:int = 600;
				_loader.x = (max_available_width - _loader.contentLoaderInfo.width) / 2 - x;
				_loader.y = (max_available_height - _loader.contentLoaderInfo.height) / 2 + _name.y + _name.height - y;
			}
		}
	}
} 
