import ui.Button;
import ui.Text;
class ActionButton extends Button
{
    var setWidth:Int = 200;
    @:isVar public var type(get,set):Int;
    function get_type():Int 
    {
        return type;
    }
    function set_type(value:Int):Int 
    {
        type = value;
        textfield.text = "";
        graphics.clear();
        switch(type)
        {
            case 0:
            //download
            text = "Download";
            fill(0xd50000);
            case 1:
            //play
            text = "Play";
            fill(0x388e3c);
            case 2:
            //update
            text = "Update";
            fill(0x2196f3);
        }
        return type;
    }
    public function new()
    {
        super();
        //red

        //green 0x388e3c
        text = "";
        textfield.align = CENTER;
        textfield.width = setWidth;
        textfield.y = 4;
        textfield.size = 24;
        textfield.color = Style.text;
    }
    public function fill(color:UInt=0xFF0000)
    {
        graphics.clear();
        graphics.beginFill(color,1);
        graphics.drawRoundRect(0,0,setWidth,40,30,30);
    }
}