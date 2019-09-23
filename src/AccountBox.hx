import sys.FileSystem;
import haxe.io.Path;
import lime.ui.FileDialog;
import haxe.Json;
import sys.io.File;
import openfl.display.Shape;
import ui.Text;
import openfl.events.MouseEvent;
import openfl.display.Sprite;
import ui.Button;
class AccountButton extends Button
{
    public var index:Int = -1;
    public function new(index:Int,name:String)
    {
        super();
        this.index = index;
        text = name;
        textfield.color = Style.text;
        graphics.beginFill(0,0.2);
        graphics.drawRect(0,0,300,30);
    }
}
enum AccountType 
{
    LOGIN;
    DONE;
}
typedef AccountData = 
{
    name:String,
    email:String,
    key:String
}
class AccountBox extends Sprite
{
    public var index:Int = -1;
    var text:Text;
    public var username:String = "";
    var emailInput:Text;
    var passwordInput:Text;
    var selector:Shape;
    var login:Login;
    public var array:Array<AccountData> = [];
    var list:Array<AccountButton> = [];
    @:isVar public var type(get,set):AccountType;
    function get_type():AccountType
    {
        return type;
    }
    function set_type(value:AccountType):AccountType
    {
        type = value;
        switch(type)
        {
            case LOGIN:
            text.text = "Login";
            text.x = 40;
            selector.visible = true;
            case DONE:
            text.text = username + " | Logout";
            text.x = 8;
            selector.visible = false;
            default:
        }
        return type;
    }
    public function new()
    {
        super();
        //get data
        var directory:Array<String> = FileSystem.readDirectory(Main.dir + "accounts");
        for (i in 0...directory.length)
        {
            array.push(Json.parse(File.getContent(Main.dir + "accounts/" + directory[i])));
        }
        //selector
        selector = new Shape();
        selector.x = 10;
        selector.y = 15;
        selector.cacheAsBitmap = true;
        selector.graphics.lineStyle(2,Style.text);
        selector.graphics.moveTo(0,8);
        selector.graphics.lineTo(20/2,0);
        selector.graphics.lineTo(20,8);
        addChild(selector);
        //text
        text = new Text("",LEFT,24,Style.text);
        text.cacheAsBitmap = false;
        text.bold = true;
        text.y = 4;
        addChild(text);
        //properties
        mouseEnabled = true;
        buttonMode = true;
        //events
        addEventListener(MouseEvent.CLICK,click);
        //login create
        login = new Login();
        login.loginEvent = signin;
        login.signupEvent = signup;
        login.visible = false;
        login.y = -250;
        addChild(login);
        type = LOGIN;
    }
    private function signin()
    {
        if (login.nameInput.text == "" || login.emailInput.text == "" || login.keyInput.text == "") return;
        var obj:AccountData = {name:login.nameInput.text,email:login.emailInput.text,key:login.keyInput.text};
        if (!FileSystem.exists(Main.dir + "accounts/" + obj.name + ".json")) index = array.push(obj);
        try {
        var file = File.write(Main.dir + "accounts/" + obj.name + ".json",false);
        file.writeString(Json.stringify(obj));
        file.close();
        }catch(e:Dynamic)
        {
            trace("error writing " + e);
        }
        login.emailInput.text = "";
        login.nameInput.text = "";
        login.keyInput.text = "";
        login.visible = false;
        type = DONE;
    }
    private function signup()
    {

    }
    private function click(_)
    {
        if (mouseX > 120) return;
        trace("mouseY " + mouseY);
        for (item in list)
        {
            removeChild(item);
            item = null;
        }
        list = [];
        selector.scaleY = 1;
        selector.y = 15;
        if (mouseY < 0) return;
        switch(type)
        {
            case LOGIN:
            if (mouseX > 30)
            {
                //action
                login.visible = true;
                text.text = "Accounts News";
            }else{
                //list
                selector.scaleY = -1;
                selector.y = 15 + 15;
                login.visible = false;
                for (i in 0...array.length)
                {
                    var button = new AccountButton(i,array[i].name);
                    button.y = -40 -36 * i;
                    button.Click = accountFunction;
                    addChild(button);
                    list.push(button);
                }
            }
            case DONE:
            index = -1;
            Main.so.data.account = index;
            type = LOGIN;
            default:
        }
    }
    private function accountFunction(e:MouseEvent)
    {
        var button:AccountButton = cast e.currentTarget;
        index = button.index;
        username = array[index].name;
        trace("index " + index + " username " + username);
        type = DONE;
        Main.so.data.account = index;
    }
    public function resize(width:Float)
    {
        graphics.endFill();
        graphics.beginFill(0xB2024,1);
        graphics.drawRect(0,0,width,40);
        text.width = width;
    }
}