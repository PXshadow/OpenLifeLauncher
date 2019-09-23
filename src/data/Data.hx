package data;

class Data
{
    public var servers:Array<{name:String,data:Server}> = [];
    public var clients:Array<{name:String,data:Client}> = [];
    public function new()
    {

    }
    public function toString():String
    {
        return "clients: " + clients + " servers: " + servers;
    }
}