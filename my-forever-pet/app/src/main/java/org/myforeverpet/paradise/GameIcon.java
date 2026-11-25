package org.myforeverpet.paradise;
import android.graphics.*;
import android.graphics.drawable.Drawable;
/** Lightweight original illustrated navigation icons. */
final class GameIcon extends Drawable{
 private final int kind;private final Paint p=new Paint(3);private final Path path=new Path();
 GameIcon(int k){kind=k;}
 private void color(int c){p.setShader(null);p.setColor(c);}
 private void rr(Canvas c,float x,float y,float w,float h,float r,int col){color(col);c.drawRoundRect(x,y,x+w,y+h,r,r,p);}
 private void o(Canvas c,float x,float y,float w,float h,int col){color(col);c.drawOval(x-w,y-h,x+w,y+h,p);}
 private void grad(Canvas c,float x,float y,float w,float h,float r,int a,int b){color(-1);p.setShader(new LinearGradient(x,y,x+w*.35f,y+h,a,b,Shader.TileMode.CLAMP));c.drawRoundRect(x,y,x+w,y+h,r,r,p);p.setShader(null);}
 private void poly(Canvas c,int col,float... xy){color(col);path.reset();path.moveTo(xy[0],xy[1]);for(int i=2;i<xy.length;i+=2)path.lineTo(xy[i],xy[i+1]);path.close();c.drawPath(path,p);}
 @Override public void draw(Canvas c){c.save();c.translate(getBounds().left,getBounds().top);c.scale(getBounds().width()/48f,getBounds().height()/48f);int dark=0xff282444;switch(kind){
 case 0:o(c,24,36,21,8,dark);grad(c,5,20,38,19,8,0xffffa6c4,0xffb64e94);o(c,24,22,18,8,dark);for(int i=0;i<8;i++)o(c,11+i%4*8,19+i/4*5,4.5f,3.7f,0xffe7a85e);o(c,24,31,4,3,0xfffff4dd);break;
 case 1:color(dark);path.reset();path.moveTo(24,44);path.cubicTo(-9,19,6,-1,24,12);path.cubicTo(42,-1,57,19,24,44);c.drawPath(path,p);p.setShader(new LinearGradient(10,8,34,40,0xffffc1db,0xffe8579b,Shader.TileMode.CLAMP));c.save();c.scale(.86f,.86f,24,24);c.drawPath(path,p);c.restore();p.setShader(null);o(c,14,15,4,2,0xfffef2f7);break;
 case 2:rr(c,4,12,40,27,11,dark);grad(c,6,14,36,23,9,0xffc5c3ff,0xff6557c8);rr(c,11,23,13,4,1,dark);rr(c,15.5f,18.5f,4,13,1,dark);o(c,34,22,3,3,0xffffc96f);o(c,38,28,3,3,0xfff88db7);break;
 case 3:rr(c,10,21,28,22,4,dark);grad(c,12,21,24,20,3,0xffffe3ad,0xffbc91d7);poly(c,dark,2,22,24,3,46,22,42,27,24,11,6,27);poly(c,0xfff2a1c0,6,21,24,6,42,21,38,23,24,12,10,23);rr(c,20,29,8,12,3,0xff6c4e85);break;
 case 4:poly(c,dark,16,5,32,5,32,17,44,38,39,45,9,45,4,38,16,17);poly(c,0xffc7e5fc,19,8,29,8,29,19,40,37,37,42,11,42,8,37,19,19);poly(c,0xffb47cee,12,29,36,29,40,38,36,41,12,41,8,38);o(c,23,34,3,3,0xffeadaff);break;
 case 5:rr(c,3,7,42,34,5,dark);grad(c,5,9,38,30,4,0xffc397f0,0xff7255ac);rr(c,9,11,14,25,2,0xffffeed8);rr(c,25,11,14,25,2,0xfff7dfcb);for(int i=0;i<3;i++){rr(c,12,17+i*5,8,1,0,0xffaf9cc1);rr(c,28,17+i*5,8,1,0,0xffaf9cc1);}poly(c,0xffed82ab,29,10,35,10,35,24,32,21,29,24);break;
 default:o(c,24,24,22,22,dark);o(c,24,24,19,19,0xff69b9ee);poly(c,0xff92d79e,10,13,20,8,28,12,26,20,17,22,16,33,10,29,7,22);poly(c,0xff8ed696,32,19,41,20,37,31,30,39,26,29);o(c,17,12,4,2,0x88ffffff);
 }c.restore();}
 @Override public void setAlpha(int a){}@Override public void setColorFilter(ColorFilter f){}@Override public int getOpacity(){return PixelFormat.TRANSLUCENT;}
}
