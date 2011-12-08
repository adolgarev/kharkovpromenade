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
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.geom.Rectangle;

	import test.LinkField;
	import test.NameField;
	import test.Info;
	import test.PosSprite;

	public class Main extends Sprite {

		private var _next:LinkField;
		private var _prev:LinkField;
		private var _name:NameField;
		private var _num:TextField;
		private var _hr:Sprite;


		private var _loader:Loader;

		private var _data:Object;
		private var _path:String;
		private var _pos:int;


		private var _info:Info;

		private var _play:LinkField = null;
		private var _pause:LinkField = null;
		private var _sound:Sound = null;
		private var _channel:SoundChannel = null;
		private var _position:int;
		private var _playing:Boolean;
		private var _posSprite:PosSprite;
		private var _dragging:Boolean;
		private var _realPos:int;


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
			_hr.graphics.moveTo(0, 0);
			_hr.graphics.lineTo(616, 0);
			addChild(_hr);

			if (_data.hasOwnProperty("audio")) {
				_play = new LinkField();
				_play.text = "Play";
				_play.visible = false;
				_play.addEventListener(MouseEvent.CLICK, handlePlay);
				addChild(_play);

				_pause = new LinkField();
				_pause.text = "Pause";
				_pause.visible = false;
				_pause.addEventListener(MouseEvent.CLICK, handlePause);
				addChild(_pause);

				_sound = new Sound();
				_sound.load(new URLRequest(_path + _data.audio));
				_position = 0;
				_realPos = -1;
				_playing = false;
				_play.visible = true;

				_posSprite = new PosSprite();
				addChild(_posSprite);
				addEventListener(Event.ENTER_FRAME, posSprite);

				_posSprite.addEventListener(MouseEvent.MOUSE_DOWN, posStartDrag);
				_dragging = false;
			}

			_info = new Info(_data);
			addChild(_info);
		}

		public function postAdd():void {
			stage.addEventListener(Event.RESIZE, layoutElements);
			showElement(-1);
			layoutElements();
		}


		private function handleNext(e:Event = null):void {
			showElement(_pos + 1);
			//handlePause();
		}

		private function handlePrev(e:Event = null):void {
			showElement(_pos - 1);
			//handlePause();
		}

		private function handlePlay(e:Event = null):void {
			_channel = _sound.play(_position);
			_playing = true;
			_play.visible = false;
			_pause.visible = true;
		}

		private function handlePause(e:Event = null):void {
			if (_channel != null) {
				_channel.stop();
				_playing = false;
				_play.visible = true;
				_pause.visible = false;
			}
		}

		private function posSprite(e:Event = null):void {
			if (_sound == null)
				return;

			if (_dragging)
				_position = (_posSprite.x - _hr.x) / _hr.width * _sound.length;
			else if (_playing)
				_position = _channel.position;

			if (!_dragging) {
				_posSprite.x = _hr.x + _hr.width * (_position / _sound.length);
				_posSprite.y = _hr.y;
			}

			if (_playing || _dragging) {
				var realPos:int = 0;
				for (realPos = 0; realPos < _data.cuePoints.length; realPos++) {
					if (_data.cuePoints[realPos] > _position / 1000)
						break;
				}
				realPos--;
				if (realPos != _realPos) {
					_realPos = realPos;
					showElement(realPos);
				}
			}
		}

		private function posStartDrag(event:MouseEvent):void {
			_posSprite.startDrag(false, new Rectangle(_hr.x, _hr.y, _hr.width, 0));
			stage.addEventListener(MouseEvent.MOUSE_UP, posStopDrag);
			_dragging = true;
			_channel.stop();
		}

		private function posStopDrag(event:MouseEvent):void {
			_posSprite.stopDrag();
			stage.removeEventListener(MouseEvent.MOUSE_UP, posStopDrag);
			_dragging = false;

			if (_playing)
				_channel = _sound.play(_position);
			else
				_channel = null;
		}

		private function showElement(i:int):void {
			_pos = i;

			if (i == -1) {
				_info.visible = true;
				_next.visible = true;
				_prev.visible = false;

				_loader.unload();

				_name.text = _data.name;
			}
			else {
				_info.visible = false;

				_loader.load(new URLRequest(_path + _data.data[i].src));
				_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, layoutElements);

				_next.visible = true;
				_prev.visible = true;
				if (i >= _data.data.length - 1)
					_next.visible = false;

				_name.text = _data.data[i].name;
			}
			_num.text = String(i+1) + "/" + String(_data.data.length);

		}

		public function layoutElements(e:Event = null):void {
			_next.x = 624 - _next.width;
			_prev.x = _next.x - _prev.width - 2;
			_next.y = stage.stageHeight - _next.height - 5;
			_prev.y = _next.y;

			_num.x = 0;
			_num.y = stage.stageHeight - _num.height - 5;

			_hr.x = 3;
			_hr.y = _next.y - 5;

			_info.x = 624 - _info.width - 5;
			_info.y = _name.y + _name.height + 7;

			if (_sound != null) {
				_play.x = (624 - _play.width - _pause.width - 2) / 2;
				_play.y = _next.y;
				_pause.x = _play.x + _play.width + 2;
				_pause.y = _next.y;
			}


			if (_loader.contentLoaderInfo.content != null) {
				var max_available_width:int = stage.stageWidth;
				var max_available_height:int = 600;
				_loader.x = (max_available_width - _loader.contentLoaderInfo.width) / 2 - x;
				_loader.y = (max_available_height - _loader.contentLoaderInfo.height) / 2 + _name.y + _name.height;
			}
		}
	}
} 
