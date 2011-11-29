package test {
	public class Plist {
		
		private var _data:XML;
		

		public function Plist(data:*) {
			
			if (data is XML) {
				_data = data as XML;
			}
			else if (data is String) {
				_data = new XML(data as String);
			}
		}
		
		
		public function readObject():Object {
			return parseObject(_data.dict[0]);
		}

		public static function parseObject(object:XML):Object {
			var n:String = object.name();
			var res:Object = null;
			var item:XML;
			
			
			switch (n) {
				case "dict":
					res = new Object();
					var key:XML = null;
					for each (item in object.elements()) {
						if (key == null) {
							key = item;
						}
						else {
							res[key.toString()] = parseObject(item);
							key = null;
						}
					}
					break;
				case "array":
					res = new Array();
					for each (item in object.elements()) {
						res.push(parseObject(item));
					}
					break;
				case "string":
					res = object.toString();
					break;
				case "integer":
					res = int(object.toString());
					break;
				case "real":
					res = Number(object.toString());
					break;
				case "true":
					res = true;
					break;
				case "false":
					res = false;
					break;
			}
			
			return res;
		}
	}
}
