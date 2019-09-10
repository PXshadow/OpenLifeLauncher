import openfl.display.Shape;
import data.Reflector;
import openfl.events.MouseEvent;
import ui.Text;
import openfl.display.Sprite;

class ServerBrowser extends Sprite
{
    var address:Text;
    var status:Text;
    var over:Shape;
    var select:Shape;
    var index:Int = 0;
    public function new()
    {
        super();
        //cacheAsBitmap = true;
        //text
        address = new Text("",LEFT,18,Style.text,100);
        address.height = 400;
        address.spacing = 2;
        address.cacheAsBitmap = false;
        addChild(address);
        status = new Text("",LEFT,18,Style.text,100);
        status.x = 100 + 20;
        status.height = 400;
        status.spacing = 2;
        status.cacheAsBitmap = false;
        addChild(status);
        //event
        buttonMode = true;
        addEventListener(MouseEvent.CLICK,click);
        addEventListener(MouseEvent.MOUSE_MOVE,move);

        graphics.beginFill(0,0);
        graphics.drawRect(0,0,100 + 100 + 20,400);

        //debug
        /*graphics.endFill();
        graphics.lineStyle(1,0);
        var j:Float = 0;
        for (i in 0...16)
        {
            j = i * (18 + 4 + 1) + 2;
            graphics.moveTo(0,j);
            graphics.lineTo(220,j);
        }*/
        over = new Shape();
        over.visible = false;
        over.graphics.lineStyle(1,Style.text,1,true);
        over.graphics.lineTo(200,0);
        addChild(over);

        select = new Shape();
        select.x = -4;
        select.visible = false;
        select.graphics.lineStyle(2,Style.text,1,true);
        select.graphics.moveTo(-8,-6);
        select.graphics.lineTo(0,0);
        select.graphics.lineTo(-8,6);
        addChild(select);
    }
    private function click(_)
    {
        index = i;
        setIndex(true);
    }
    var i:Int = 0;
    private function move(_)
    {
        i = Std.int((mouseY + 2)/(18 + 4 + 1));
        if (i < 0) i = 0;
        if (i > address.numLines - 1) i = address.numLines - 1;
        setIndex();
    }
    private function setIndex(clickBool:Bool=false)
    {
        if (clickBool)
        {
            select.visible = true;
            select.y = (index + 1) * (18 + 4 + 1) - 18/2 - 1;
        }else{
            over.visible = true;
            over.y = (i + 1) * (18 + 4 + 1);
        }
    }
    public function clear()
    {
        address.text = "";
        status.text = "";
        over.visible = false;
        select.visible = false;
        mouseEnabled = false;
    }
    public function set(array:Array<Reflector>)
    {
        clear();
        mouseEnabled = true;
        for (reflect in array)
        {
            address.appendText(reflect.ip.substring(0,reflect.ip.indexOf(".")) + "\n");
            status.appendText(reflect.status + "\n");
        }
        setIndex(false);
        setIndex(true);
    }
}