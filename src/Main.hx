package;

import openfl.net.SharedObject;
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
    public static var setWidth:Int = 1200;
    public static var setHeight:Int = 800;
    var scale:Float = 0;
    var data:data.Data;
    var action:ActionButton;
    var delete:Button;
    var side:Bitmap;
    var servers:ListBox;
    var clients:ListBox;
    var desc:Text;
    var discord:Button;
    var signup:Button;
    var serverbrowser:ServerBrowser;
    var loader:Loader = new Loader();
    var timer:Timer;
    var unzipLength:Int = 0;
    var task:String = "";
    var image:Bitmap;
    public static var so:SharedObject;
    var account:AccountBox;
	public function new()
	{
		super();
        stage.addEventListener(Event.ACTIVATE,function(_)
        {
            stage.frameRate = 30;
        });
        stage.window.onMinimize.add(function()
        {
            stage.frameRate = 5;
        });
        /*stage.addEventListener(openfl.events.MouseEvent.CLICK,function(_)
        {
            setup();
        });*/
        so = SharedObject.getLocal("data");
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
        if (!FileSystem.exists(dir + "accounts")) FileSystem.createDirectory(dir + "accounts");
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
        //servers.fill();
        clients = new ListBox("Clients");
        //saved data
        if (so.data.focus != null && so.data.focus > -1) 
        {
            clients.focus = so.data.focus;
            trace("focus " + clients.focus + " length " + data.clients.length);
            if (data.clients.length < clients.focus + 1) 
            {
                clients.focus = -1;
                so.data.focus = -1;
                return;
            }
            if (!FileSystem.exists(dir + "clients/" + data.clients[clients.focus].name))
            {
                clients.focus = -1;
                so.data.focus = clients.focus;
            }
        }
        clients.y = servers.height + 0;
        for (obj in data.clients) clients.add(obj.name);
        addChild(clients);
        clients.select = clientFunction;
        //clients.fill();
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
        delete.Click = deleteFunction;
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
        discord.y = desc.height + 10 + 20;
        discord.Click = discordInvite;
        addChild(discord);
        signup = new Button();
        signup.visible = false;
        signup.text = "Signup";
        signup.textfield.align = CENTER;
        signup.textfield.width = 200;
        signup.textfield.y = 4;
        signup.textfield.size = 24;
        signup.textfield.color = Style.text;
        signup.y = discord.y + discord.height + 20;
        signup.graphics.beginFill(0x800080,1);
        signup.graphics.drawRoundRect(0,0,200,40,30,30);
        signup.Click = signupFunction;
        addChild(signup);
        serverbrowser = new ServerBrowser();
        serverbrowser.x = 300 + 35;
        serverbrowser.y = desc.y + desc.height + 16;
        addChild(serverbrowser);
        image = new Bitmap(null,openfl.display.PixelSnapping.ALWAYS,true);
        image.x = 320;
        image.y = 360;
        //image.bitmapData = Assets.getBitmapData("assets/images/0.png");
        //width 240
        account = new AccountBox();
        if (so.data.account != null)
        {
            account.type = LOGIN;
        }
        //account.visible = false;
        addChild(account);
        //event
        stage.addEventListener(Event.RESIZE,resize);
        resize(null);
        addChild(image);
        timer = new haxe.Timer(1000 * 10);
        timer.run = update;
	}
    private function signupFunction(_)
    {
        if (servers.index > -1) url(data.servers[servers.index].data.account);
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
        clients.x = 0;
        clients.y = servers.y + servers.height;
        //redraw other
        clients.index = -1;
        clients.redraw();
        //data
        var obj = data.servers[i];
        trace("server function name " + obj.name);
        if (FileSystem.exists(dir + "servers/" + obj.name))
        {
            if (!FileSystem.exists(dir + "servers/" + obj.name + "/done"))
            {

                //folder is there but files are still there 
                action.type = CLEAN;
            }else{
                //folder
                action.type = PLAY;
            }
        }else{
            trace("does not exist");
            //does not exist
            action.type = DOWNLOAD;
        }
        delete.visible = (action.type == DOWNLOAD || action.type == CLEAN ? false : true);
        desc.text = data.servers[i].data.desc;
        discord.visible = true;
        signup.visible = true;
        serverbrowser.index = 0;
        serverbrowser.clear();
        update();
    }
    var si:Int = 0;
    private function clientFunction(i:Int)
    {
        //redraw other
        servers.redraw();
        if (action.type == DONE)
        {
            //server is selecting client
            clients.x = servers.x;
            clients.y = servers.y + servers.height;
            //download client
            clients.focus = clients.index;
            clients.index = clients.focus;
            si = servers.index;
            servers.index = -1;
            action.type = SELECT;
            actionFunction(null);
            action.type = DONE;
            return;
        }
        servers.index = -1;
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
        signup.visible = false;
        serverbrowser.clear();
    }
    private function discordInvite(_)
    {
        if (servers.index >= 0)
        {
            url(data.servers[servers.index].data.discord);
        }
    }
    private function deleteFunction(_)
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
            //remove focus if deleted client
            if (clients.index == clients.focus) clients.focus = -1;
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
                    trace("graphics lib");
                    graphicLib(path,function()
                    {
                        //english text in dir
                        var language = File.write(path + "us_english_60.txt");
                        language.writeString(Assets.getText("assets/us_english_60.txt"));
                        language.close();
                        //languages folder
                        FileSystem.createDirectory(path + "languages");
                        language = File.write(path + "languages/English.txt");
                        language.writeString(Assets.getText("assets/English.txt"));
                        language.close();
                        //sounds
                        FileSystem.createDirectory(path + "otherSounds");
                        unzip(haxe.zip.Reader.readZip(new BytesInput(Assets.getBytes("assets/otherSounds.zip"))),path + "otherSounds/",function()
                        {
                            //completion check file
                            File.write(path + "done").close();
                            //finish event
                            finish();
                        });
                    });
                },true);
            });
            case PLAY:
            trace("client focus " + clients.focus);
            //check if client not focused
            if (clients.focus == -1)
            {
                clients.x = 560;
                clients.y = serverbrowser.y;
                action.type = DONE;
                return;
            }
            //use focused client add into server folder and play
            action.text = "Setting up";
            var name:String = data.clients[clients.focus].name;
            trace("name " + name);
            var d = FileSystem.readDirectory(dir + "clients/" + name);
            var fileName = d[0] == "binary.txt" ? d[1] : d[0];
            var ext = Path.extension(fileName);
            var input:haxe.io.Input = File.read(dir + "clients/" + name + "/" + fileName);
            //clean up old client and move settings back
            try {
            removeClient(path);
            }catch(e:Dynamic)
            {
                trace("e " + e);
            }
            //setup settings
            setup();
            //install new client
            var binary = File.write(path + "binary.txt");
            binary.writeString(File.getContent(dir + "clients/" + name + "/binary.txt"));
            binary.close();
            switch(ext)
            {
                case "zip":
                //compressed
                clientlib(path,function()
                {
                    unzip(haxe.zip.Reader.readZip(input),path,function()
                    {
                        trace("run client");
                        runClient(path);
                    });
                });
                default:
                //excutables
                clientlib(path,function()
                {
                    trace("finish client lib " + path + fileName);
                    var file = File.write(path + fileName);
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
            case SELECT:
            if (FileSystem.exists(path))
            {
                //already installed
                clients.focus = index;
                so.data.focus = clients.focus;
                finish();
                return;
            }
            trace("download select client " + name);
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
                var string = bytes.toString();
                var link = downloadLink(string,count);
                //get binary
                var split = string.indexOf('class="muted-link css-truncate" title="') + 39;
                string = string.substring(string.indexOf("_v",split) + 2,string.indexOf('"',split));
                trace("version " + string);
                //download zip from link
                trace("link " + link);
                loader.get(link,true,function(bytes:Bytes)
                {
                    FileSystem.createDirectory(path);
                    //binary
                    var binary = File.write(path + "binary.txt");
                    binary.writeString("v" + string + " built on Mon Jan 1 11:11:11 PST 2019");
                    binary.close();

                    var ext:String = Path.extension(link);
                    //write an executable or a zip
                    var app = File.write(path + name + (ext == "" ? "" : "." + ext));
                    app.write(bytes);
                    app.close();
                    trace("focus " + index);
                    clients.focus = index;
                    finish();
                });
            });
            case UNSELECT:
            clients.focus = -1;
            so.data.focus = -1;
            finish();
            case EXIT:
            terminate();
            default:
        }
    }
    private function binary(path:String)
    {
        //data binary version
        var binary = File.write(path + "binary.txt");
        trace("version " + File.getContent(path + "dataVersionNumber.txt"));
        binary.writeString("v" + File.getContent(path + "dataVersionNumber.txt") + " built on Mon Jan 1 11:11:11 PST 2019");
        binary.close();
    }
    private function finish()
    {
        if (action.type == DONE)
        {
            clients.index = -1;
            servers.index = si;
            //play server
            action.type = PLAY;
            actionFunction(null);
            return;
        }
        if (servers.index >= 0)
        {
            openfl.Lib.application.window.alert(data.servers[servers.index].name + " Downloaded","Complete");
            serverFunction(servers.index);
            return;
        }
        if (clients.index >= 0)
        {
            clientFunction(clients.index);
        }
        trace("finish action");
    }
    private function graphicLib(path:String,finish:Void->Void)
    {
        FileSystem.createDirectory(path + "graphics");
        unzip(haxe.zip.Reader.readZip(new BytesInput(Assets.getBytes("assets/graphics.zip"))),path + "graphics/",function()
        {
            finish();
        });
    }
    private function settingslib(dir:String,path:String)
    {
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
    }
    private function clientlib(path:String,finish:Void->Void)
    {
        unzip(haxe.zip.Reader.readZip(new BytesInput(Assets.getBytes("assets/clientlib.zip"))),path,function()
        {
            //add settings
            if (!FileSystem.exists(dir + "settings")) throw "settings not found";
            if (FileSystem.exists(path + "settings")) deleteDir(path + "settings");
            FileSystem.createDirectory(path + "settings");
            settingslib(dir,path);
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
                execute(path,name);
                return;
                #elseif mac
                case "app":
                execute(path,name);
                return;
                #elseif linux
                case "":
                //file with no extension therefore it's a linux executable
                if (!FileSystem.isDirectory(path + name))
                {
                    execute(path,name);
                    return;
                }
                #end
            }
        }
    }
    private function setup()
    {
        if (serverbrowser.array.length == 0) return;
        //settings setup
        trace("setting up");
        File.saveContent(dir + "settings/customServerAddress.ini",serverbrowser.array[serverbrowser.index].ip);
        File.saveContent(dir + "settings/CustomServerPort.ini",Std.string(serverbrowser.array[serverbrowser.index].port));
        File.saveContent(dir + "settings/useCustomServer.ini","1");
        if (account.index > -1)
        {
            trace("account index " + account.index);
            var data = account.array[account.index];
            var file = File.write(dir + "settings/email.ini",false);
            file.writeString(data.email);
            file.close();
            file = File.write(dir + "settings/accountKey.ini",false);
            file.writeString(data.key);
            file.close();
            /*file = File.write(dir + "settings/autoLogin.ini");
            file.writeString("1");
            file.close();*/
            //File.saveContent(dir + "settings/email.ini",data.email);
            //File.saveContent(dir + "settings/accountKey.ini",data.key);
            //File.saveContent(dir + "settings/autoLogin.ini","1");
        }else{
            //File.saveContent(dir + "settings/autoLogin.ini","0");
        }
    }
    public function removeClient(path:String)
    {
        for (name in FileSystem.readDirectory(path))
        {
            if (name == "settings")
            {
                //move settings back and save to be changed
                settingslib(path,dir);
                //delete settings
                deleteDir(path + "settings");
            }else{
                switch (Path.extension(name))
                {
                    case "dll" | "exe" | "app":
                    FileSystem.deleteFile(path + name);
                }
            }
        }
    }
    private function url(url:String)
    {
        openfl.Lib.navigateToURL(new URLRequest(url));
    }
    private function execute(path:String,url:String):Void 
    {
        Sys.setCwd(path);
        trace("execute " + url);
        switch (Sys.systemName()) 
        {
            case "Linux", "BSD": Sys.command("xdg-open", [url]);
            case "Mac": Sys.command("open", [url]);
            case "Windows": Sys.command("start", [url]);
            default:
        }
        task = url;
        action.type = RUNNING;
        stage.window.minimized = true;
        trace("finish run");
    }
    private function terminate()
    {
        if (task == "") return;
        switch(Sys.systemName())
        {
            case "Linux" | "BSD" | "Mac" : Sys.command("pkill",[Path.withoutExtension(task)]);
            //case "Mac":
            case "Windows": Sys.command("TASKKILL",["/IM",task]);
        }
        task = "";
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
        account.x = diff;
        account.resize(stage.stageWidth/scale);
        account.y = stage.stageHeight/scale - 40;
        //action button
        action.x = -60 + (setWidth + action.width)/1.5;
        action.y = stage.stageHeight/scale - 40 * 2 - 10;
        delete.x = action.x + action.width + 10;
        delete.y = action.y;
        discord.x = action.x + 70;
        signup.x = discord.x;
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
        //dir = Path.normalize(lime.system.System.applicationDirectory) + "/";
        #else
        dir = Path.normalize(lime.system.System.applicationDirectory);
        dir = Path.removeTrailingSlashes(dir) + "/";
        #end
        #if mac
        dir = dir.substring(0,dir.indexOf("/Contents/Resources/"));
        dir = dir.substring(0,dir.lastIndexOf("/") + 1);
        #end
        trace("dir " + dir);
    }
}
