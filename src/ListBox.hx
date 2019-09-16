import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.Shape;
import ui.Text;
import openfl.events.MouseEvent;
import openfl.display.Sprite;

class ListBox extends Sprite
{
    public var select:Int->Void;
    public var index:Int = -1;
    public var focus:Int = -1;
    var length:Int = 0;
    var i:Int = 0;
    var title:String = "";
    var setWidth:Int = 300;
    public function new(title:String)
    {
        super();
        this.title = title.toLowerCase();
        cacheAsBitmap = true;
        tab();
        //title
        var text = new Text(title,CENTER,24,Style.text,setWidth);
        text.cacheAsBitmap = false;
        text.x = 0;
        text.y = 4;
        addChild(text);
        //events
        addEventListener(MouseEvent.CLICK,click);
        addEventListener(MouseEvent.MOUSE_MOVE,move);
    }
    public function add(name:String)
    {
        //text
        var text = new Text(StringTools.replace(name,"_"," "),LEFT,24,Style.text,setWidth - 40);
        text.height = 40 - 4;
        text.y = 40 + length * 40 + 4;
        text.x = 40;
        addChild(text);
        //icon
        if (true)
        {
            var bitmap = new Bitmap(Assets.getBitmapData("assets/" + title + "/" + name + ".png"));
            bitmap.smoothing = true;
            bitmap.width = 20;
            bitmap.height = 20;
            bitmap.x = 10;
            bitmap.y = 40 + length * 40 + (40 - bitmap.width)/2;
            addChild(bitmap);
        }
        length++;
        draw();
    }
    private function draw()
    {
        graphics.beginFill(index == i ? Style.fill : Style.select);
        graphics.drawRect(0,40 + i * 40,setWidth,40);
        if (i == focus)
        {
            graphics.endFill();
            graphics.beginFill(0xFFFFFF);
            graphics.drawCircle(300 - 20,40 + focus * 40 + 20,8);
        }
        i++;
    }
    private function tab()
    {
        graphics.beginFill(Style.tab);
        graphics.drawRect(0,0,setWidth,40);
    }
    private function move(_)
    {
        buttonMode = mouseY > 40 ? true : false;
    }
    private function click(_)
    {
        index = Math.floor((mouseY - 40)/40);
        if (index < 0) return;
        redraw();
        //event
        if (select != null) select(index);
    }
    public function redraw()
    {
        graphics.clear();
        tab();
        i = 0;
        graphics.endFill();
        for (j in 0...length)  draw();
    }
    public function fill()
    {
        var shape = new Shape();
        shape.graphics.beginFill(0,0);
        shape.graphics.drawRect(0,0,width,height);
        addChild(shape);
    }
}