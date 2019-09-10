import data.Reflector;
import openfl.events.MouseEvent;
import ui.Text;
import openfl.display.Sprite;

class ServerBrowser extends Sprite
{
    var text:Text;
    public function new()
    {
        super();
        //cacheAsBitmap = true;
        //text
        text = new Text("",LEFT,20,Style.text,500);
        text.height = 300;
        text.cacheAsBitmap = false;
        addChild(text);
        //event
        addEventListener(MouseEvent.CLICK,click);
    }
    private function click(_)
    {
        var i:Int = Std.int((mouseY + 0)/20);
        trace("index: " + i);
        if (i < text.numLines)
        {
            
        }
    }
    public function clear()
    {
        text.text = "";
    }
    public function set(array:Array<Reflector>)
    {
        clear();
        for (reflect in array)
        {
            text.appendText(reflect.ip.substring(0,reflect.ip.indexOf(".")) + ":" + reflect.port + " " + reflect.status + "\n");
        }
    }
}