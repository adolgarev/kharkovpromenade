package test {
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextFieldAutoSize;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display.LineScaleMode;
	import flash.display.CapsStyle;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.display.Bitmap;

	import test.Plist;

	public class Test extends Sprite {

		//private const DEFAULT_FONT:String = "Liberation Sans";
		private const DEFAULT_FONT:String = "Adobe Courier";


		private var mainContainer:Sprite;
		private var next:TextField;
		private var prev:TextField;
		private var nextContainer:Sprite;
		private var prevContainer:Sprite;
		private var nameField:TextField;
		private var curField:TextField;

		private var loader:Loader;

		private var data:Object;
		private var path:String;
		private var cur:uint;

		public function Test() {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			loader = new Loader();
			addChild(loader);

			mainContainer = new Sprite();
			mainContainer.x = 0;
			mainContainer.y = 0;
			addChild(mainContainer);

			nameField = new TextField();
			nameField.x = 8;
			nameField.y = 15;
			nameField.autoSize = TextFieldAutoSize.LEFT;
			var tf:TextFormat = nameField.defaultTextFormat;
			tf.size = 21;
			tf.font = DEFAULT_FONT;
			nameField.defaultTextFormat = tf;
			nameField.setTextFormat(tf);
			nameField.antiAliasType = AntiAliasType.ADVANCED;
			nameField.gridFitType = GridFitType.SUBPIXEL;
			mainContainer.addChild(nameField);

			curField = new TextField();
			curField.autoSize = TextFieldAutoSize.LEFT;
			tf = curField.defaultTextFormat;
			tf.size = 14;
			tf.font = DEFAULT_FONT;
			curField.defaultTextFormat = tf;
			curField.setTextFormat(tf);
			curField.antiAliasType = AntiAliasType.ADVANCED;
			curField.gridFitType = GridFitType.SUBPIXEL;
			mainContainer.addChild(curField);

			mainContainer.graphics.lineStyle(7, 0xBBBBBB, 1.0, true, LineScaleMode.NORMAL, CapsStyle.NONE);
			mainContainer.graphics.moveTo(3, 10);
			mainContainer.graphics.lineTo(3, 45);
			mainContainer.graphics.lineStyle(1, 0xCCCCCC, 1.0, true, LineScaleMode.NORMAL, CapsStyle.NONE);
			mainContainer.graphics.lineTo(642, 45);


			nextContainer = new Sprite();
			next = new TextField();
			next.text = "Next";
			configureLink(nextContainer, next);
			nextContainer.addEventListener(MouseEvent.CLICK, handleNext);
			prevContainer = new Sprite();
			prev = new TextField();
			prev.text = "Prev";
			configureLink(prevContainer, prev);
			prevContainer.addEventListener(MouseEvent.CLICK, handlePrev);

			stage.addEventListener(Event.RESIZE, layoutElements);
			layoutElements();

			loaderInfo.addEventListener(Event.COMPLETE, loaderComplete);
		}

		private function configureLink(container:Sprite, text:TextField):void {
			container.buttonMode = true;
			container.mouseChildren = false;
			mainContainer.addChild(container);

			text.autoSize = TextFieldAutoSize.LEFT;
			var tf:TextFormat = text.defaultTextFormat;
			tf.underline = false;
			tf.color = 0x0000ff;
			tf.size = 14;
			tf.font = DEFAULT_FONT;
			text.defaultTextFormat = tf;
			text.setTextFormat(tf);
			text.antiAliasType = AntiAliasType.ADVANCED;
			text.gridFitType = GridFitType.SUBPIXEL;
			text.visible = false;
			
			container.addChild(text);
			container.width = text.width;
			container.height = text.height;
			container.addEventListener(MouseEvent.MOUSE_OVER, handleOver);
			container.addEventListener(MouseEvent.MOUSE_OUT, handleOut);
		}


		private function handleOver(e:Event):void {
			var text:TextField = e.target.getChildAt(0) as TextField;
			var tf:TextFormat = text.defaultTextFormat;
			tf.underline = true;
			text.defaultTextFormat = tf;
			text.setTextFormat(tf);
		}

		private function handleOut(e:Event):void {
			var text:TextField = e.target.getChildAt(0) as TextField;
			var tf:TextFormat = text.defaultTextFormat;
			tf.underline = false;
			text.defaultTextFormat = tf;
			text.setTextFormat(tf);
		}

		private function handleNext(e:Event = null):void {
			showElement(cur + 1);
		}

		private function handlePrev(e:Event = null):void {
			showElement(cur - 1);
		}


		private function layoutElements(e:Event = null):void {
			mainContainer.x = (stage.stageWidth - 800) / 2;
			mainContainer.y = 0;

			nextContainer.x = 800 - nextContainer.width;
			prevContainer.x = nextContainer.x - prevContainer.width - 2;
			nextContainer.y = stage.stageHeight - nextContainer.height - 5;
			prevContainer.y = stage.stageHeight - prevContainer.height - 5;

			curField.x = 0;
			curField.y = stage.stageHeight - curField.height - 5;


			if (loader.contentLoaderInfo.content != null) {
				/*var image:Bitmap = loader.content as Bitmap;
				image.smoothing = true;

				var max_width:uint = 2522;
				var max_height:uint = 1875;
				var max_width:uint = 800;
				var max_height:uint = 600;*/
				var max_available_width:int = stage.stageWidth;
				var max_available_height:int = curField.y - nameField.y - nameField.height - 5;
				/*var scale:Number = Math.min(max_available_width / max_width,
							max_available_height / max_height);


				loader.x = (max_available_width - loader.contentLoaderInfo.width * scale) / 2;
				loader.y = (max_available_height - loader.contentLoaderInfo.height * scale) / 2 + nameField.y + nameField.height + 5;
				loader.scaleX = scale;
				loader.scaleY = scale;*/
				loader.x = (max_available_width - loader.contentLoaderInfo.width) / 2;
				loader.y = (max_available_height - loader.contentLoaderInfo.height) / 2 + nameField.y + nameField.height + 5;
			}
		}


		private function loaderComplete(e:Event):void {
			var key:String = loaderInfo.parameters.key;
			path = key;

			var pl:URLLoader = new URLLoader();
			pl.addEventListener(Event.COMPLETE, loaderComplete1);
			pl.load(new URLRequest(key));
		}


		private function loaderComplete1(e:Event):void {
			var pl:URLLoader = e.target as URLLoader;
			var p:Plist = new Plist(pl.data);
			
			data = p.readObject();
			var l:int = path.lastIndexOf("/");
			if (l == -1)
				path = "";
			else
				path = path.substring(0, l + 1);

			showElement(0);
		}

		private function showElement(i:uint):void {
			cur = i;

			loader.load(new URLRequest(path + data.data[i].src));
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, layoutElements);

			next.visible = true;
			prev.visible = true;
			if (i == 0)
				prev.visible = false;
			if (i >= data.data.length - 1)
				next.visible = false;

			nameField.text = data.data[i].name;
			curField.text = String(i + 1) + "/" + String(data.data.length);
		}
	}
}
