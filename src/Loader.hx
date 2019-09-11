import haxe.Timer;
import haxe.io.Output;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Bytes;
import lime.net.curl.CURL;
import lime.app.Future;
class Loader
{
    public var complete:Bytes->Void;
    public var error:Void->Void;
    public var progressOut:ProgressOut;
    public var progress:(current:Float,total:Float)->Void;
    var curl:CURL = new CURL();
    var curlBool:Bool = false;
    var bytes:Bytes;
    var index:Int = 0;
    var redirects:Int = 0;
    public function new()
    {

    }
    public function get(url:String,application:Bool)
    {
        if (curlBool)
        {
            //if (Main.future != null) return;
            curl.reset();
            curl.reset();
            index = 0;
            curl.setOption(URL,url);
            curl.setOption(HTTPGET,true);
            curl.setOption(FOLLOWLOCATION,true);
            curl.setOption(AUTOREFERER,true);
            var headers = ["Content-Type: " + Std.string(application ? "application/octet-stream" : "application/x-www-form-urlencoded")];
            curl.setOption(HTTPHEADER,headers);
            //curl.setOption(PROGRESSFUNCTION,onProgress);
            curl.setOption(WRITEFUNCTION,onWrite);
            curl.setOption(SSL_VERIFYPEER,false);
            curl.setOption(SSL_VERIFYHOST,0);
            curl.setOption(USERAGENT, "libcurl-agent/1.0");
            curl.setOption(NOSIGNAL,true);
            curl.setOption(ACCEPT_ENCODING,"DEFLATE");
            curl.setOption(TRANSFERTEXT,!application);
            //curl.setOption(VERBOSE,true);
            #if cpp
            //cpp.vm.Gc.enterGCFreeZone();
            #end
            Main.future = new Future(function()
            {
                trace(curl.perform());
                return 0;
            },true).onComplete(function(i:Int)
            {
                #if cpp
                //cpp.vm.Gc.exitGCFreeZone();
                #end
                Main.future = null;
            });
        }else{
            download(url);
        }
    }
    private function download(url:String,maxRedirect:Int=20)
    {
        var h = new haxe.Http(url);
        h.addHeader("User-Agent","libcurl-agent/1.0");

        var httpStatus = -1;
        var redirectedLocation = null;
        h.onStatus = function(status)
        {
            httpStatus = status;
            switch(httpStatus)
            {
                case 301,302,307,308:
                switch(h.responseHeaders.get("Location"))
                {
                    case null:
                    throw 'responded with $httpStatus, ${h.responseHeaders}';
                    case location:
                    trace("location " + location);
                }
            }
        }
        h.onError = function(e)
        {
            progressOut.close();
            switch(httpStatus)
            {
                case 416:
                // 416 Requested Range Not Satisfiable, which means that we probably have a fully downloaded file already
				// if we reached onError, because of 416 status code, it's probably okay and we should try unzipping the file
                default:
                throw e;
            }
        }
        h.customRequest(false,progressOut);

        if (redirectedLocation != null)
        {
            if (maxRedirect > 0)
            {
                download(redirectedLocation,maxRedirect - 1);
            }else{
                throw "Too many redirects.";
            }
        }
    }
    private function print(string:String)
    {
        trace(string);
    }
    private function onWrite(curl:CURL,output:Bytes):Int
    {
        if (complete != null) complete(bytes);
        return output.length;
    }
}
class ProgressOut extends haxe.io.Output {

	var o : haxe.io.Output;
	var cur : Int;
	var curReadable : Float;
	var startSize : Int;
	var max : Null<Int>;
	var maxReadable : Null<Float>;
	var start : Float;

	public function new(o, currentSize) {
		this.o = o;
		startSize = currentSize;
		cur = currentSize;
		start = Timer.stamp();
	}

	function report(n) {
		cur += n;

		var tag : String = ((max != null ? max : cur) / 1000000) > 1 ? "MB" : "KB";

		curReadable = tag == "MB" ? cur / 1000000 : cur / 1000;
		curReadable = Math.round( curReadable * 100 ) / 100; // 12.34 precision.

		if( max == null )
			Sys.print('${curReadable} ${tag}\r');
		else {
			maxReadable = tag == "MB" ? max / 1000000 : max / 1000;
			maxReadable = Math.round( maxReadable * 100 ) / 100; // 12.34 precision.

			Sys.print('${curReadable}${tag} / ${maxReadable}${tag} (${Std.int((cur*100.0)/max)}%)\r');
		}
	}

	public override function writeByte(c) {
		o.writeByte(c);
		report(1);
	}

	public override function writeBytes(s,p,l) {
		var r = o.writeBytes(s,p,l);
		report(r);
		return r;
	}

	public override function close() {
		super.close();
		o.close();
		var time = Timer.stamp() - start;
		var downloadedBytes = cur - startSize;
		var speed = (downloadedBytes / time) / 1000;
		time = Std.int(time * 10) / 10;
		speed = Std.int(speed * 10) / 10;

		var tag : String = (downloadedBytes / 1000000) > 1 ? "MB" : "KB";
		var readableBytes : Float = (tag == "MB") ? downloadedBytes / 1000000 : downloadedBytes / 1000;
		readableBytes = Math.round( readableBytes * 100 ) / 100; // 12.34 precision.

		Sys.println('Download complete: ${readableBytes}${tag} in ${time}s (${speed}KB/s)');
	}

	public override function prepare(m) {
		max = m + startSize;
	}

}