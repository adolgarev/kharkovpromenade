package test {

	import flash.display.Sprite;
	import flash.display.CapsStyle;
	import flash.display.LineScaleMode;

	public class PosSprite extends Sprite {

		public function PosSprite() {
			graphics.beginFill(0xFF0000, 0.0);
			graphics.drawRect(-5, -5, 10, 10);
			graphics.endFill();

			graphics.lineStyle(1, 0x000000, 1.0, true, LineScaleMode.NORMAL, CapsStyle.NONE);
			graphics.moveTo(0, -5);
			graphics.lineTo(0, 5);
		}

	}


}