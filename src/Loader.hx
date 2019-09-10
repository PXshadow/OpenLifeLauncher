import openfl.events.ProgressEvent;
import openfl.events.IOErrorEvent;
import openfl.events.Event;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequestMethod;
import openfl.net.URLRequest;
import openfl.net.URLLoader;

class Loader
{
    var loader:URLLoader;
    public var complete:Dynamic->Void;
    public var error:Void->Void;
    public var progrsss:(current:Float,total:Float)->Void;
    public function new()
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
            if (progrsss != null) progrsss(e.bytesLoaded,e.bytesTotal);
        });
    }
    public function get(url:String,application:Bool)
    {
        var request = new URLRequest(url);
        request.contentType = application ? "application/octet-stream" : "application/x-www-form-urlencoded";
        request.method = GET;
        loader.dataFormat = application ? BINARY : TEXT;
        loader.load(request);
    }
}