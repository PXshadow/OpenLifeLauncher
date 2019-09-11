import ui.Button;
import ui.Text;
enum ActionType 
{
    DOWNLOAD;
    PLAY;
    UPDATE;
    NOCLIENT;
    
    SELECT;
    UNSELECT;
}
class ActionButton extends Button
{
    var setWidth:Int = 200;
    @:isVar public var type(get,set):ActionType;
    function get_type():ActionType
    {
        return type;
    }
    function set_type(value:ActionType):ActionType
    {
        type = value;
        textfield.text = "";
        graphics.clear();
        switch(type)
        {
            case DOWNLOAD:
            text = "Download";
            fill(0xd50000);
            case PLAY:
            text = "Play";
            fill(0x388e3c);
            case UPDATE:
            text = "Update";
            fill(0x2196f3);
            case SELECT:
            text = "Select";
            fill(0x2196f3);
            case UNSELECT:
            text = "Unselect";
            fill(0x2196f3);
            case NOCLIENT:
            text = "No Client";
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