package;

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
import ui.*;
class Main extends Sprite
{
	public static var dir:String = "";
    var setWidth:Int = 1200;
    var setHeight:Int = 800;
    var scale:Float = 0;
    var data:data.Data;
    var action:ActionButton;
    var side:Bitmap;
    var servers:ListBox;
    var clients:ListBox;
    var desc:Text;
	public function new()
	{
		super();
        stage.color = Style.background;
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
        servers.select = server;
        servers.fill();
        clients = new ListBox("Clients");
        clients.y = servers.height + 0;
        for (obj in data.clients) clients.add(obj.name);
        addChild(clients);
        clients.select = client;
        clients.fill();
        //action button
        action = new ActionButton();
        action.Click = actionFunction;
        addChild(action);
        //main
        desc = new Text("Hello world",LEFT,20,0xFFFFFF,200);
        desc.height = 200;
        desc.x = 300 + 10;
        desc.y = 10;
        addChild(desc);
        //event
        stage.addEventListener(Event.RESIZE,resize);
        resize(null);
	}
    private function server(i:Int)
    {
        //redraw other
        clients.index = -1;
        clients.redraw();
        //data
        var obj = data.servers[i];
        if (FileSystem.exists(dir + "servers/" + obj.name))
        {
            //folder
        }else{
            //does not exist
        }
        desc.text = data.servers[i].data.desc;
    }
    private function client(i:Int)
    {
        //redraw other
        servers.index = -1;
        servers.redraw();
        //data
        var obj = data.clients[i];
        if (FileSystem.exists(dir + "clients/" + obj.name))
        {
            //folder
        }else{
            //does not exist
        }
        desc.text = data.clients[i].data.desc;
    }
    private function actionFunction(_)
    {

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
        action.y = stage.stageHeight/scale - 40 - 10;

        /*graphics.clear();
        graphics.lineStyle(2,0xFFFFFFF);
        var cx:Float = 200 + (setWidth - 200)/2;
        graphics.moveTo(cx,0);
        graphics.lineTo(cx,setHeight);*/
    }
    private function unzip(list:List<haxe.zip.Entry>,path:String)
    {
        //unzip(haxe.zip.Reader.readZip(new BytesInput(loader.data)),path);
        var ext:String = "";
        path += "/";
        var i:Int = 0;
        for (items in list)
        {
            items.fileName = items.fileName.substring(items.fileName.indexOf("/") + 1,items.fileName.length);
            ext = Path.extension(items.fileName);
            if(ext == "")
            {
                //folder
                FileSystem.createDirectory(path + items.fileName);
            }else{
                if (FileSystem.isDirectory(path + Path.directory(items.fileName)))
                {
                    File.write(path + items.fileName).write(haxe.zip.Reader.unzip(items));
                }else{
                    trace("Can not find directory " + Path.directory(items.fileName));
                }
            }
            i++;
            if (i > 20) 
            {
                i = 0;
                Sys.sleep(0.016);
                trace("sleep");
            }
        }
        //if (complete != null) complete(true);
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
