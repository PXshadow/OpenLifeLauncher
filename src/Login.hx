import openfl.display.Shape;
import ui.Button;
import ui.Text;
import openfl.display.DisplayObjectContainer;

class Login extends DisplayObjectContainer
{
    public var emailInput:Text;
    public var keyInput:Text;
    public var nameInput:Text;
    var emailName:Text;
    var keyName:Text;
    var nameName:Text;
    public var login:Button;
    public var background:Shape;
    public var loginEvent:Void->Void;
    public var signupEvent:Void->Void;
    public function new()
    {
        super();
        background = new Shape();
        background.cacheAsBitmap = true;
        background.graphics.beginFill(Style.tab);
        background.graphics.drawRect(0,0,300,224);
        addChild(background);

        nameInput = new Text("",LEFT,18,0,200);
        nameInput.tabEnabled = true;
        nameInput.tabIndex = 0;
        nameInput.height = 20;
        nameInput.type = INPUT;
        nameInput.selectable = true;
        nameInput.mouseEnabled = true;
        nameInput.cacheAsBitmap = false;
        nameInput.border = true;
        nameInput.background = true;
        nameInput.backgroundColor = 0xFFFFFF;
        addChild(nameInput);
        emailInput = new Text("",LEFT,18,0,200);
        emailInput.tabEnabled = true;
        emailInput.tabIndex = 1;
        emailInput.height = 20;
        emailInput.type = INPUT;
        emailInput.selectable = true;
        emailInput.mouseEnabled = true;
        emailInput.cacheAsBitmap = false;
        emailInput.border = true;
        emailInput.background = true;
        emailInput.backgroundColor = 0xFFFFFF;
        addChild(emailInput);
        keyInput = new Text("",LEFT,18,0,200);
        keyInput.displayAsPassword = true;
        keyInput.height = 20;
        keyInput.tabEnabled = true;
        keyInput.tabIndex = 2;
        keyInput.type = INPUT;
        keyInput.selectable = true;
        keyInput.mouseEnabled = true;
        keyInput.cacheAsBitmap = false;
        keyInput.border = true;
        keyInput.background = true;
        keyInput.backgroundColor = 0xFFFFFF;
        addChild(keyInput);

        keyName = new Text("Key:",LEFT,18,Style.text);
        addChild(keyName);
        emailName = new Text("Email:",LEFT,18,Style.text);
        addChild(emailName);
        nameName = new Text("Name:",LEFT,18,Style.text);
        addChild(nameName);
        //buttons
        function setButton(button:Button)
        {
            button.textfield.align = CENTER;
            button.textfield.width = 200;
            button.textfield.y = 1;
            button.textfield.size = 20;
            button.textfield.color = Style.text;
            //graphics
            button.graphics.beginFill(0xFF0000,1);
            button.graphics.drawRect(0,0,200,30);
        }
        login = new Button();
        login.text = "Login";
        setButton(login);
        login.Click = function(_)
        {
            if (loginEvent != null) loginEvent();
        }
        addChild(login);
        //pos
        emailName.x = 8;
        nameName.x = 8;
        keyName.x = 8;

        nameInput.x = 80;
        emailInput.x = nameInput.x;
        keyInput.x = nameInput.x;

        login.x = nameInput.x;

        var start:Int = 10;
        var spacing:Int = 42;

        nameInput.y = start;
        nameName.y = start;
        emailInput.y = start + spacing;
        emailName.y = emailInput.y;
        keyInput.y = start + spacing * 2;
        keyName.y = keyInput.y;

        login.y = start + spacing * 3;
        //events
    }
}