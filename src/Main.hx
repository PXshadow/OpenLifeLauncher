package;

import sys.io.FileInput;
import lime.system.BackgroundWorker;
import lime.system.ThreadPool;
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
    var unzipLength:Int = 0;
	public function new()
	{
		super();
        //resolve loader
        loader.get("https://github.com/PXshadow/resolve/archive/master.zip",true,function(data:Bytes)
        {
            trace("warm up resolve");
        });
        stage.color = Style.dark;
        setupDir();
        //folders
        if (!FileSystem.exists(dir + "clients")) FileSystem.createDirectory(dir + "clients");
        if (!FileSystem.exists(dir + "servers")) FileSystem.createDirectory(dir + "servers");
        if (!FileSystem.exists(dir + "settings"))
        {
            FileSystem.createDirectory(dir + "settings");
            unzip(haxe.zip.Reader.readZip(new BytesInput(Assets.getBytes("assets/settings.zip"))),dir + "settings/",function()
            {
                trace("create new settings");
            });
        }
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

        timer = new haxe.Timer(1000 * 10);
        timer.run = update;
	}
    private function update()
    {
        //update serverbrowser
        if (servers.index >= 0)
        {
            loader.get(data.servers[servers.index].data.reflector,false,function(bytes:Bytes)
            {
                if (bytes == null || bytes.length <= 0)
                {
                    timer.run = update;
                    return;
                }
                reflect(bytes.toString());
                timer.run = update;
            });
            timer.run = function(){};
        }
    }
    private function reflect(string:String)
    {
        string = string.substring("Remote servers:<br><br>|--> ".length,string.length);
        var index:Int = 0;
        var array:Array<data.Reflector> = [];
        var reflector:Reflector = {ip: "",port: 0,status: ""};
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
            if (!FileSystem.exists(dir + "servers/" + obj.name + "/done"))
            {
                //folder is there but files are still there 
                action.type = CLEAN;
            }else{
                //folder
                if (clients.focus == -1)
                {
                    action.type = NOCLIENT;
                }else{
                    action.type = PLAY;
                }
            }
        }else{
            //does not exist
            action.type = DOWNLOAD;
        }
        delete.visible = (action.type == DOWNLOAD || action.type == CLEAN ? false : true);
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
        if (clients.focus == i)
        {
            action.type = UNSELECT;
        }else{
            action.type = SELECT;
        }
        delete.visible = FileSystem.exists(dir + "clients/" + data.clients[i].name);
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
        if (servers.index >= 0)
        {
            trace("delete dir");
            var path:String = dir + "servers/" + data.servers[servers.index].name;
            deleteDir(path);
            FileSystem.deleteDirectory(path);
            serverFunction(servers.index);
            trace("finish");
            return;
        }
        if (clients.index >= 0)
        {
            var path:String = dir + "clients/" + data.clients[clients.index].name;
            deleteDir(path);
            FileSystem.deleteDirectory(path);
            clientFunction(clients.index);
        }
    }
    private function actionFunction(_)
    {
        //data
        var index:Int = 0;
        var fill:String = "";
        var name:String = "";
        if (servers.index > -1)
        {
            index = servers.index;
            fill = "servers/";
            name = data.servers[index].name;
        }else{
            index = clients.index;
            fill = "clients/";
            name = data.clients[index].name;
        }
        var path:String = dir + fill + name + "/"; 
        //action types
        switch(action.type)
        {
            //server side
            case DOWNLOAD:
            UnitTest.inital();
            action.text = "Downloading";
            loader.get(data.servers[index].data.data,true,function(data:Bytes)
            {
                trace("stamp: " + UnitTest.stamp());
                FileSystem.createDirectory(path);
                action.text = "unzip";
                unzip(haxe.zip.Reader.readZip(new BytesInput(data)),path,function()
                {
                    File.write(path + "done").close();
                    finish();
                },true);
            });
            case PLAY:
            //use focused client add into server folder and play
            action.text = "Setting up";
            var name:String = data.clients[clients.focus].name;
            var fileName = FileSystem.readDirectory(dir + "clients/" + name)[0];
            var ext = Path.extension(fileName);
            var input:haxe.io.Input = File.read(dir + "clients/" + name + "/" + fileName);
            switch(ext)
            {
                case "zip":
                //compressed
                clientlib(path,function()
                {
                    unzip(haxe.zip.Reader.readZip(input),path,function()
                    {
                        runClient(path);
                    });
                });
                default:
                //excutables
                clientlib(path,function()
                {
                    trace("finish client lib");
                    var file = File.write(path + "/" + fileName);
                    file.write(input.readAll());
                    file.close();
                    runClient(path);
                });
            }
            case CLEAN:
            trace("clean: " + path);
            deleteDir(path);
            FileSystem.deleteDirectory(path);
            finish();
            case NOCLIENT:
            openfl.Lib.current.stage.window.alert("No client selected","Info");
            //client side
            case SELECT:
            if (FileSystem.exists(path + "done"))
            {
                clients.focus = index;
                clients.redraw();
                finish();
                return;
            }else{
                //check if corrupted folder and delete since it's small
                if (FileSystem.exists(path)) deleteDir(path);
            }
            //download
            loader.get(data.clients[index].data.url,false,function(bytes:Bytes)
            {
                trace("url " + data.clients[index].data.url);
                var count:Int = 0;
                #if windows
                count = data.clients[index].data.windows;
                #elseif mac
                count = data.clients[index].data.mac;
                #elseif linux
                count = data.clients[index].data.linux;
                #end
                var link = downloadLink(bytes.toString(),count);
                trace("link " + link);
                loader.get(link,true,function(bytes:Bytes)
                {
                    FileSystem.createDirectory(path);
                    var ext:String = Path.extension(link);
                    //write an executable or a zip
                    var app = File.write(path + name + (ext == "" ? "" : "." + ext));
                    app.write(bytes);
                    app.close();
                    clients.focus = index;
                    //done file to signal no issue happened on install
                    File.write(path + "done").close();
                    finish();
                });
            });
            case UNSELECT:
            clients.focus = -1;
            finish();
            default:
        }
    }
    private function finish()
    {
        if (servers.index >= 0)
        {
            serverFunction(servers.index);
            return;
        }
        if (clients.index >= 0)
        {
            clientFunction(clients.index);
        }
        trace("finish action");
    }
    private function clientlib(path:String,finish:Void->Void)
    {
        unzip(haxe.zip.Reader.readZip(new BytesInput(Assets.getBytes("assets/clientlib.zip"))),path,function()
        {
            //add settings
            if (!FileSystem.exists(dir + "settings")) throw "settings not found";
            if (FileSystem.exists(path + "settings")) removeClient(path);
            FileSystem.createDirectory(path + "settings");
            var input:FileInput = null;
            var output:FileOutput = null;
            for(name in FileSystem.readDirectory(dir + "settings"))
            {
                input = File.read(dir + "settings/" + name);
                output = File.write(path + "settings/" + name);
                output.write(input.readAll());
                output.close();
                input.close();
            }
            finish();
        });
    }
    private function downloadLink(data:String,count:Int):String
    {
        data = data.substring(Std.int(72886/4),data.length);
        var find = '<div class="d-flex flex-justify-between flex-items-center py-1 py-md-2 Box-body px-2">';
        data = data.substring(data.indexOf(find) + find.length,data.length);
        var href = '<a href="';
        var index:Int = 0;
        var downloadLink:String = "";
        for (i in 0...count + 1)
        {
            index = data.indexOf(href,index) + href.length;
            downloadLink = data.substring(index,data.indexOf('"',index));
        }
        return "https://github.com" + downloadLink;
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
                    FileSystem.deleteDirectory(path + "/" + name);
                }else{
                    FileSystem.deleteFile(path + "/" + name);
                }
            }
        }
    }
    public function runClient(path:String)
    {
        var ext:String = "";
        for (name in FileSystem.readDirectory(path))
        {
            ext = Path.extension(name);
            switch(ext)
            {
                #if windows
                case "exe":
                execute(path + "/" + name);
                return;
                #elseif mac
                case "app":
                execute(path + "/" + name);
                return;
                #elseif linux
                case "":
                //file with no extension therefore it's a linux executable
                if (!FileSystem.isDirectory(path + "/" + name))
                {
                    execute(path + "/" + name);
                    return;
                }
                #end
            }
        }
    }
    public function removeClient(path:String)
    {
        for (name in FileSystem.readDirectory(path))
        {
            if (name == "settings")
            {
                deleteDir(path + "settings");
            }else{
                switch (Path.extension(name))
                {
                    case "dll" | "exe" | ".app":
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
    }
    private function unzip(list:List<haxe.zip.Entry>,path:String,finish:Void->Void,actionBool:Bool=false)
    {
        var length:Int = list.length;
        var worker = new BackgroundWorker();
        var file:FileOutput = null;
        worker.doWork.add(function(list:List<haxe.zip.Entry>)
        {
            var i:Int = 0;
            for (item in list)
            {
                i++;
                item.fileName = item.fileName.substring(item.fileName.indexOf("/") + 1,item.fileName.length);
                if(Path.extension(item.fileName) == "")
                {
                    //folder
                    FileSystem.createDirectory(path + item.fileName);
                    worker.sendProgress(i);
                }else{
                    if (FileSystem.isDirectory(path + Path.directory(item.fileName)))
                    {
                        file = File.write(path + item.fileName);
                        file.write(haxe.zip.Reader.unzip(item));
                        file.close();
                        file = null;
                    }else{
                        trace("Can not find directory " + Path.directory(item.fileName));
                    }
                }
            }
            worker.sendComplete();
        });
        worker.onProgress.add(function(current:Int)
        {
            if (actionBool) action.text = "unzip " + Std.string(Std.int((current/length) * 100)) + "%";
        });
        worker.onComplete.add(function(_)
        {
            finish();
        });
        worker.run(list);
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
