package;

import haxe.io.Bytes;
import lime.app.Future;
import data.Reflector;
import haxe.Timer;
import openfl.net.URLRequest;
import openfl.display.PixelSnapping;
import sys.io.FileOutput;
import openfl.utils.ByteArray;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.display.Shape;
import haxe.Json;
import openfl.utils.AssetType;
import openfl.Assets;
import openfl.events.Event;
import sys.FileSystem;
import openfl.display.Sprite;
import haxe.io.Path;
import sys.io.File;
import haxe.io.BytesInput;
import ui.*;
class Main extends Sprite
{
	public static var dir:String = "";
    var setWidth:Int = 1200;
    var setHeight:Int = 800;
    var scale:Float = 0;
    var data:data.Data;
    var action:ActionButton;
    var delete:Button;
    var side:Bitmap;
    var servers:ListBox;
    var clients:ListBox;
    var desc:Text;
    var discord:Button;
    var serverbrowser:ServerBrowser;
    var loader:Loader = new Loader();
    var timer:Timer;
    public static var future:Future<Int> = null;
	public function new()
	{
		super();
        stage.color = Style.dark;
        setupDir();
        //folders
        if (!FileSystem.exists(dir + "clients")) FileSystem.createDirectory(dir + "clients");
        if (!FileSystem.exists(dir + "servers")) FileSystem.createDirectory(dir + "servers");
        //data
        data = new data.Data();
        var start:Int = "assets/".length;
        for (path in Assets.list(AssetType.TEXT))
        {
            var split:Int = path.indexOf("/",start);
            //-5 to remove .json
            var name = path.substring(split + 1,path.length - 5);
            switch(path.substring(start,split))
            {
                case "clients":
                data.clients.push({name:name,data:Json.parse(Assets.getText(path))});
                case "servers":
                data.servers.push({name:name,data:Json.parse(Assets.getText(path))});
            }
        }
        //stage
        side = new Bitmap(new BitmapData(300,stage.stageHeight,false,Style.select));
        side.cacheAsBitmapMatrix = new Matrix();
        addChild(side);
        servers = new ListBox("Servers");
        for (obj in data.servers) servers.add(obj.name);
        addChild(servers);
        servers.select = serverFunction;
        servers.fill();
        clients = new ListBox("Clients");
        clients.y = servers.height + 0;
        for (obj in data.clients) clients.add(obj.name);
        addChild(clients);
        clients.select = clientFunction;
        clients.fill();
        //action button
        action = new ActionButton();
        action.Click = actionFunction;
        addChild(action);
        //delete button
        delete = new Button();
        delete.visible = false;
        //rect
        delete.graphics.beginFill(0xFF0000);
        delete.graphics.drawRoundRect(0,0,100,40,30,30);
        //text
        delete.text = "Delete";
        delete.textfield.align = CENTER;
        delete.textfield.width = 100;
        delete.textfield.y = 4;
        delete.textfield.size = 24;
        delete.textfield.color = Style.text;
        delete.Click = remove;
        addChild(delete);
        //main
        desc = new Text("",LEFT,20,0xFFFFFF,setWidth - 300 - 20 * 2);
        desc.spacing = 20;
        desc.wordWrap = true;
        desc.cacheAsBitmap = false;
        desc.height = 326;
        desc.x = 300 + 20;
        desc.y = 10;
        addChild(desc);
        //discord invite area
        discord = new Button();
        discord.visible = false;
        discord.addChild(new Bitmap(Assets.getBitmapData("assets/discord.png"),PixelSnapping.ALWAYS,true));
        discord.scaleX = 0.3;
        discord.scaleY = 0.3;
        discord.x = setWidth - discord.width - 20;
        discord.y = desc.height + 10 + 20;
        discord.Click = discordInvite;
        addChild(discord);
        serverbrowser = new ServerBrowser();
        serverbrowser.y = desc.y + desc.height + 8;
        addChild(serverbrowser);
        //event
        stage.addEventListener(Event.RESIZE,resize);
        resize(null);

        timer = new haxe.Timer(1000 * 6);
        timer.run = update;
	}
    private function update()
    {
        //update serverbrowser
        /*if (servers.index >= 0)
        {
            loader.complete = function(bytes:Bytes)
            {
                trace("load");
                reflect(bytes.toString());
                trace("reflect finish");
                timer.run = update;
            }
            loader.error = function()
            {
                timer.run = update;
            }
            loader.get(data.servers[servers.index].data.reflector,false);
            timer.run = function(){};
        }*/
    }
    private function reflect(string:String)
    {
        trace("inital " + string.length);
        string = string.substring("Remote servers:<br><br>|--> ".length,string.length);
        var index:Int = 0;
        var array:Array<data.Reflector> = [];
        var reflector:Reflector = {ip: "",port: 0,status: ""};
        trace("0");
        while(true)
        {
            index = string.indexOf(" : ");
            if (index < 0) break;
            reflector.ip = string.substring(0,index);
            reflector.port = Std.parseInt(string.substring(index + 3,index = string.indexOf(" ::: ",index)));
            reflector.status = string.substring(index + 5,index = string.indexOf("<br><br>"));
            array.push(Reflect.copy(reflector));
            if (string.substring(index,index + 8 + 5) == "<br><br>|--> ")
            {
                //trim off
                string = string.substring(index + 8 + 5,string.length);
            }else{
                //end
                break;
            }
        }
        trace("1 " + array.length);
        serverbrowser.set(array);
    }
    private function serverFunction(i:Int)
    {
        //redraw other
        clients.index = -1;
        clients.redraw();
        //data
        var obj = data.servers[i];
        if (FileSystem.exists(dir + "servers/" + obj.name))
        {
            //folder
            action.type = 1;
        }else{
            //does not exist
            action.type = 0;
        }
        delete.visible = action.type == 1 ? true : false;
        desc.text = data.servers[i].data.desc;
        discord.visible = true;
        serverbrowser.clear();
        update();
    }
    private function clientFunction(i:Int)
    {
        //redraw other
        servers.index = -1;
        servers.redraw();
        //data
        var obj = data.clients[i];
        if (FileSystem.exists(dir + "clients/" + obj.name))
        {
            //folder
            action.type = 1;
        }else{
            //does not exist
            action.type = 0;
        }
        delete.visible = action.type == 1 ? true : false;
        desc.text = data.clients[i].data.desc;
        discord.visible = false;
        serverbrowser.clear();
    }
    private function discordInvite(_)
    {
        if (servers.index >= 0)
        {
            url(data.servers[servers.index].data.discord);
        }
    }
    private function remove(_)
    {
        if (future != null) return;
        if (servers.index >= 0)
        {
            future = new Future(function()
            {
                deleteDir(dir + "servers/" + data.servers[servers.index].name);
                return 0;
            },true).onComplete(function(i:Int)
            {
                FileSystem.deleteDirectory(dir + "servers/" + data.servers[servers.index].name);
                serverFunction(servers.index);
                future = null;
            });
            return;
        }
        if (clients.index >= 0)
        {
            future = new Future(function()
            {
                deleteDir(dir + "clients/" + data.clients[clients.index].name);
                return 0;
            },true).onComplete(function(i:Int)
            {
                FileSystem.deleteDirectory(dir + "servers/" + data.clients[clients.index].name);
                clientFunction(clients.index);
                future = null;
            });
        }
    }
    private function actionFunction(_)
    {
        if (servers.index >= 0)
        {
            var name:String = data.servers[servers.index].name;
            var server = data.servers[servers.index].data;
            var path:String = dir + "servers/" + name + "/";
            if (FileSystem.exists(path))
            {
                //already exists

                return;
            }
            //installer
            loader.complete = function(data:Bytes)
            {
                trace("stamp: " + UnitTest.stamp());
                //FileSystem.createDirectory(path);
                //unzip(haxe.zip.Reader.readZip(new BytesInput(data)),path);
                //serverFunction(servers.index);
                //63426486
                //70000000
            }
            UnitTest.inital();
            loader.get(server.data,true);
            return;
        }
        trace("clients " + clients.index);
        if (clients.index >= 0)
        {
            trace("start loader");
            var name:String = data.clients[clients.index].name;
            var client = data.clients[clients.index].data;
            var path:String = dir + "clients/" + name + "/";
            if (FileSystem.exists(path))
            {
                for (name in FileSystem.readDirectory(path))
                {
                    switch(Path.extension(name))
                    {
                        case "exe":
                        execute(path + name);
                    }
                }
                return;
            }
            //installer
            loader.complete = function(bytes:Bytes)
            {
                var data = bytes.toString();
                data = data.substring(Std.int(72886/4),data.length);
                var find = "d-flex flex-justify-between flex-items-center py-1 py-md-2 Box-body px-2";
                data = data.substring(data.indexOf(find) + find.length,data.length);
                var href = '<a href="';
                var index:Int = 0;
                var count:Int = 0;
                #if windows
                count = client.windows;
                #elseif mac
                count = client.mac;
                #elseif linux
                count = client.linux;
                #end
                //count = 2;
                var downloadLink:String = "";
                for (i in 0...count + 1)
                {
                    index = data.indexOf(href,index) + href.length;
                    downloadLink = data.substring(index,data.indexOf('"',index));
                }
                downloadLink = "https://github.com" + downloadLink;
                loader.progress = function(current:Float,total:Float)
                {
                    trace(current + "/" + total);
                }
                loader.complete = function(data:Bytes)
                {
                    trace("unzip");
                    FileSystem.createDirectory(path);
                    if (client.compressed)
                    {
                        unzip(haxe.zip.Reader.readZip(new BytesInput(data)), path);
                    }else{
                        var app = File.write(path + name + ".exe");
                        app.write(data);
                        app.close();
                    }
                    //extract client lib
                    unzip(haxe.zip.Reader.readZip(new BytesInput(Assets.getBytes("assets/clientlib.zip"))),path);
                    trace("finish");
                    clientFunction(action.type);
                }
                loader.get(downloadLink,true);
            }
            loader.error = function()
            {
                trace("error");
            }
            loader.get(client.url,false);
            #if windows

            #end
            #if mac

            #end
            #if linux

            #end
        }
    }
    private function deleteDir(path:String)
    {
        if (FileSystem.exists(path) && FileSystem.isDirectory(path))
        {
            for (name in FileSystem.readDirectory(path))
            {
                if (FileSystem.isDirectory(path + "/" + name))
                {
                    deleteDir(path + "/" + name);
                }else{
                    FileSystem.deleteFile(path + "/" + name);
                }
            }
        }
    }
    public function removeClientLib(path:String)
    {
        for (name in FileSystem.readDirectory(path))
        {
            trace("name " + name);
            if (name == "settings")
            {
                FileSystem.deleteDirectory(path + name);
            }else{
                switch (Path.extension(name))
                {
                    case "dll":
                    FileSystem.deleteFile(path + name);
                    case "exe":
                    FileSystem.deleteFile(path + name);
                }
            }
        }
    }
    private function url(url:String)
    {
        openfl.Lib.navigateToURL(new URLRequest(url));
    }
    private function execute(url:String):Void 
    {
        switch (Sys.systemName()) 
        {
            case "Linux", "BSD": Sys.command("xdg-open", [url]);
            case "Mac": Sys.command("open", [url]);
            case "Windows": Sys.command("start", [url]);
            default:
        }
    }
    private function resize(_)
    {
        var tempX:Float = stage.stageWidth / setWidth;
        var tempY:Float = stage.stageHeight / setHeight;
        scale = Math.min(tempX,tempY);
        x = Math.floor((stage.stageWidth - setWidth * scale) / 2);
        y = 0;
        scaleX = scale;
        scaleY = scale;

        //keep side bar to the side
        var diff:Float = -x * 1/scale;
        if (clients != null) clients.x = diff;
        if (servers != null) servers.x = diff;
        side.height = stage.stageHeight/scale;
        side.x = diff;
        //action button
        action.x = -100 + (setWidth + action.width)/2;
        action.y = stage.stageHeight/scale - 40 - 20;
        delete.x = action.x + action.width + 10;
        delete.y = action.y;

        serverbrowser.x = action.x + action.width/2  - 90;
        /*graphics.clear();
        graphics.lineStyle(2,0xFFFFFFF);
        var cx:Float = 200 + (setWidth - 200)/2;
        graphics.moveTo(cx,0);
        graphics.lineTo(cx,setHeight);*/
    }
    private function unzip(list:List<haxe.zip.Entry>,path:String)
    {
        //unzip(haxe.zip.Reader.readZip(new BytesInput(loader.data)),path);
        future = new Future(function()
        {
            path += "/";
            var file:FileOutput = null;
            for (items in list)
            {
                items.fileName = items.fileName.substring(items.fileName.indexOf("/") + 1,items.fileName.length);
                if(Path.extension(items.fileName) == "")
                {
                    //folder
                    FileSystem.createDirectory(path + items.fileName);
                }else{
                    if (FileSystem.isDirectory(path + Path.directory(items.fileName)))
                    {
                        file = File.write(path + items.fileName);
                        file.write(haxe.zip.Reader.unzip(items));
                        file.close();
                        file = null;
                    }else{
                        trace("Can not find directory " + Path.directory(items.fileName));
                    }
                }
            }
            return 0;
        },true).onComplete(function(i:Int)
        {
            future = null;
        });
    }
	private function setupDir()
    {
        #if windows
        dir = "";
        #else
        dir = Path.normalize(lime.system.System.applicationDirectory);
        dir = Path.removeTrailingSlashes(dir) + "/";
        #end
        #if mac
        dir = dir.substring(0,dir.indexOf("/Contents/Resources/"));
        dir = dir.substring(0,dir.lastIndexOf("/") + 1);
        #end
    }
}
