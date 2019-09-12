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
    var curl:CURL = null;
    var curlLoad:Bool = false;
    public function new()
    {

    }
    public function get(url:String,application:Bool,complete:Bytes->Void)
    {
        if (curlBool)
        {
            if (application)
            {
                if (curlLoad) 
                {
                    openfl.Lib.current.stage.application.window.alert("CURL Application already running","Error");
                    trace("CURL Application already running");
                    return;
                }
                curlLoad = true;
                if (this.curl == null)
                {
                    this.curl = new CURL();
                }else{
                    this.curl.reset();
                }
            }
            var curl = application ? this.curl : new CURL();
            //curl.setOption(INFILESIZE_LARGE,application);
            curl.setOption(URL,url);
            curl.setOption(HTTPGET,true);
            //curl.setOption(INFILESIZE,60000000);
            curl.setOption(FOLLOWLOCATION,true);
            curl.setOption(AUTOREFERER,true);
            //curl.setOption(RESOLVE,true);
            var headers = ["Content-Type: " + Std.string(application ? "application/octet-stream" : "application/x-www-form-urlencoded")];
            curl.setOption(HTTPHEADER,headers);
            //curl.setOption(TCP_NODELAY,true);
            //curl.setOption(PROGRESSFUNCTION,onProgress);
            curl.setOption(SSL_VERIFYPEER,false);
            curl.setOption(SSL_VERIFYHOST,0);
            curl.setOption(USERAGENT, "libcurl-agent/1.0");
            curl.setOption(NOSIGNAL,true);
            curl.setOption(ACCEPT_ENCODING,"DEFLATE");
            curl.setOption(TRANSFERTEXT,!application);
            //curl.setOption(VERBOSE,true);
            curl.setOption(MAXREDIRS,20);
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
                if (application) curlLoad = false;
                if (complete != null) complete(bytes);
                bytes = null;
            });
        }else{
            
        }
    }
}