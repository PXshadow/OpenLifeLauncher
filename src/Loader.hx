import sys.net.Host;
import haxe.Timer;
import haxe.io.Output;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Bytes;
import lime.net.curl.CURL;
import lime.app.Future;
class Loader
{
    var curlBool:Bool = true;
    public function new()
    {

    }
    public function get(url:String,application:Bool,complete:Bytes->Void)
    {
        if (curlBool)
        {
            var curl = new CURL();
            curl.reset();
            curl.setOption(URL,url);
            curl.setOption(HTTPGET,true);
            curl.setOption(FOLLOWLOCATION,true);
            curl.setOption(AUTOREFERER,true);
            //curl.setOption(RESOLVE,true);
            var headers = ["Content-Type: " + Std.string(application ? "application/octet-stream" : "application/x-www-form-urlencoded")];
            curl.setOption(HTTPHEADER,headers);
            //curl.setOption(PROGRESSFUNCTION,onProgress);
            curl.setOption(SSL_VERIFYPEER,false);
            curl.setOption(SSL_VERIFYHOST,0);
            curl.setOption(USERAGENT, "libcurl-agent/1.0");
            curl.setOption(NOSIGNAL,true);
            curl.setOption(ACCEPT_ENCODING,"DEFLATE");
            curl.setOption(TRANSFERTEXT,!application);
            //curl.setOption(VERBOSE,true);
            var bytes:Bytes;
            curl.setOption(WRITEFUNCTION,function(curl:CURL,output:Bytes):Int
            {
                bytes = output;
                return bytes.length;
            });
            var future = new Future(function()
            {
                curl.perform();
                return 0;
            },true).onComplete(function(i:Int)
            {
                if (complete != null) complete(bytes);
                bytes = null;
            });
        }else{
            
        }
    }
}