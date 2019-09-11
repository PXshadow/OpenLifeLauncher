import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.net.URLRequestMethod;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.events.Event;
import haxe.io.Bytes;
import lime.net.curl.CURL;
import lime.app.Future;
class Loader
{
    public var complete:Bytes->Void;
    public var error:Void->Void;
    public var progress:(current:Float,total:Float)->Void;
    var curl:CURL = new CURL();
    var loader:URLLoader;
    var curlBool:Bool = true;
    var bytes:Bytes;
    var index:Int = 0;
    public function new()
    {
        if(!curlBool)
        {
            loader = new URLLoader();
            //events
            loader.addEventListener(Event.COMPLETE,function(_)
            {
                if (complete != null) complete(loader.data);
            });
            loader.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent)
            {
                if (error != null) error();
            });
            loader.addEventListener(ProgressEvent.PROGRESS,function(e:ProgressEvent)
            {
                if (progress != null) progress(e.bytesLoaded,e.bytesTotal);
            });
        }
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
                if (complete != null) complete(bytes);
                #if cpp
                //cpp.vm.Gc.exitGCFreeZone();
                #end
                Main.future = null;
            });
        }else{
            var request = new URLRequest(url);
            request.contentType = application ? "application/octet-stream" : "application/x-www-form-urlencoded";
            request.method = GET;
            loader.dataFormat = application ? BINARY : TEXT;
            loader.load(request);
        }
    }
    private function onWrite(curl:CURL,output:Bytes):Int
    {
        /*bytes = output;
        trace("copy");
        /*growBuffer(output.length);
        trace("write " + output.length);
        bytes.blit(index,output,0,output.length);
        index += output.length;*/
        return output.length;
    }
    private function growBuffer(length:Int)
	{
		if (length > bytes.length)
		{
			var cacheBytes = bytes;
			bytes = Bytes.alloc(length);
			bytes.blit(0, cacheBytes, 0, cacheBytes.length);
		}
	}
}