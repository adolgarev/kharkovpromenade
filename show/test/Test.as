package test {
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.display.Loader;


	import test.Plist;
	import test.Main;


	import flash.text.TextField;

	public class Test extends Sprite {


		private var _main:Main;

		private var _data:Object;
		private var _path:String;


		public function Test() {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			loaderInfo.addEventListener(Event.COMPLETE, stage1);
		}


		private function stage1(e:Event):void {
			var key:String = loaderInfo.parameters.key;
			_path = key;

			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, stage2);
			loader.load(new URLRequest(key));
		}


		private function stage2(e:Event):void {
			var loader:URLLoader = e.target as URLLoader;
			var p:Plist = new Plist(loader.data);
			
			_data = p.readObject();
			var l:int = _path.lastIndexOf("/");
			if (l == -1)
				_path = "";
			else
				_path = _path.substring(0, l + 1);

			var fontLoader:Loader = new Loader();
			fontLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, stage3);
			fontLoader.load(new URLRequest("Lucida Grande.swf"));
		}


		private function stage3(e:Event):void {
			_main = new Main(_data, _path);
			addChild(_main);
			stage.addEventListener(Event.RESIZE, layoutElements);
			layoutElements();
		}


		private function layoutElements(e:Event = null):void {
			_main.x = (stage.stageWidth - 800) / 2;
			_main.y = 0;
			_main.layoutElements();
		}
	}
}
