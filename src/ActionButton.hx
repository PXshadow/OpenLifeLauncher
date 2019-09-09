import ui.Button;
import ui.Text;
class ActionButton extends Button
{
    var setWidth:Int = 200;
    var type:Int = -1;
    public function new()
    {
        super();
        //red
        fill(0xd50000);
        //green 0x388e3c
        var text = new Text("Download",CENTER,24,Style.text,setWidth);
        text.cacheAsBitmap = false;
        text.x = 0;
        text.y = 4;
        addChild(text);
    }
    public function fill(color:UInt=0xFF0000)
    {
        graphics.clear();
        graphics.beginFill(color,1);
        graphics.drawRoundRect(0,0,setWidth,40,30,30);
    }
}