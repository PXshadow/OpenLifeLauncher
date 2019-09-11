import haxe.io.Bytes;
import lime.net.curl.CURL;
import lime.app.Future;

class Loader
{
    public var complete:Dynamic->Void;
    public var error:Void->Void;
    public var progress:(current:Float,total:Float)->Void;
    var curl:CURL;
    var bytes:Bytes;
    var index:Int = 0;
    var application:Bool = false;
    public function new()
    {
        curl = new CURL();
        bytes = Bytes.alloc(0);
    }
    public function get(url:String,application:Bool)
    {
        this.application = application;
        curl.reset();
        curl.setOption(URL,url);
        curl.setOption(HTTPGET,true);
        curl.setOption(FOLLOWLOCATION,true);
        curl.setOption(AUTOREFERER,true);
        var headers = ["Content-Type: " + Std.string(application ? "application/octet-stream" : "application/x-www-form-urlencoded")];
        curl.setOption(HTTPHEADER,headers);
        curl.setOption(PROGRESSFUNCTION,onProgress);
        curl.setOption(WRITEFUNCTION,onWrite);
        curl.setOption(SSL_VERIFYPEER,false);
        curl.setOption(SSL_VERIFYHOST,0);
        curl.setOption(USERAGENT, "libcurl-agent/1.0");
        curl.setOption(NOSIGNAL,true);
        curl.setOption(TRANSFERTEXT,!application);
        trace("code " + curl.perform());
        curl.cleanup();
        /*var request = new URLRequest(url);
        request.contentType = application ? "application/octet-stream" : "application/x-www-form-urlencoded";
        request.method = GET;
        loader.dataFormat = application ? BINARY : TEXT;
        loader.load(request);*/
    }
    private function onProgress(curl:CURL,dltotal:Int,dlnow:Int,uptotal:Int,upnow:Int):Int
    {
        trace("total " + dltotal + " now " + dlnow);
        trace("bytes " + bytes.toString());
        if (dlnow == dltotal)
        {
            if (complete != null) complete(application ? bytes : bytes.toString());
        }else{
            if (progress != null) progress(dlnow,dltotal);
        }
        return dlnow;
    }
    private function onWrite(curl:CURL,output:Bytes):Int
    {
        growBuffer(index + output.length);
        bytes.blit(index,output,0,output.length);
        index += output.length;
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