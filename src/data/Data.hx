package data;

class Data
{
    public var servers:Array<{name:String,data:Server}> = [];
    public var clients:Array<{name:String,data:Client}> = [];
    public var serverIndex:Int = 0;
    public var clientIndex:Int = 0;
    public function new()
    {

    }
}