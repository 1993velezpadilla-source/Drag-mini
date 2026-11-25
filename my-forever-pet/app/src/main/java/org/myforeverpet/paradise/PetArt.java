package org.myforeverpet.paradise;
import android.graphics.*;
/** Original layered vector artwork; no Bandai sprites. */
final class PetArt {
 private final Paint p=new Paint(3);
 private void color(int c){p.setColor(c);p.setStyle(Paint.Style.FILL);}
 private void oval(Canvas c,float x,float y,float rx,float ry,int col){color(col);c.drawOval(x-rx,y-ry,x+rx,y+ry,p);}
 private void rect(Canvas c,float l,float t,float r,float b,float radius,int col){color(col);c.drawRoundRect(l,t,r,b,radius,radius,p);}
 private void text(Canvas c,String s,float x,float y,float size,int col){color(col);p.setTextSize(size);p.setTypeface(Typeface.create("sans-serif-medium",0));p.setTextAlign(Paint.Align.CENTER);c.drawText(s,x,y,p);}
 private void star(Canvas c,float x,float y,float size,int col){color(col);Path a=new Path();for(int i=0;i<10;i++){double ang=-Math.PI/2+i*Math.PI/5;float r=i%2==0?size:size*.42f;float xx=x+(float)Math.cos(ang)*r,yy=y+(float)Math.sin(ang)*r;if(i==0)a.moveTo(xx,yy);else a.lineTo(xx,yy);}a.close();c.drawPath(a,p);}
 void draw(Canvas canvas,PetState s,int zoom,boolean wallpaper,long tick){
  canvas.save();float w=canvas.getWidth(),h=canvas.getHeight();canvas.scale(w/360f,h/480f);
  Canvas c=canvas;float bob=(float)Math.sin(tick/550.0)*3;
  int sky=s.field==1?0xff5ac9d9:s.field==2?0xff8aa8ee:0xffa1e4d5;
  int land=s.field==1?0xff318ca9:s.field==2?0xffb9c8fa:0xff76bb86;
  if(zoom==0){color(0xff131f42);c.drawPaint(p);for(int i=0;i<35;i++)star(c,(i*73+19)%360,(i*131+9)%480,1+i%3,0xffe5eaff);oval(c,180,238,99,99,0xff65c7b9);oval(c,154,216,52,39,land);oval(c,212,263,34,31,0xff76bb86);oval(c,137,178,16,11,0xffe0fff4);if(!wallpaper)text(c,"SPACE",180,55,19,0xffeff4ff);canvas.restore();return;}
  if(zoom==3){color(0xfffde3e9);c.drawPaint(p);for(int i=0;i<15;i++)oval(c,(i*61+30)%360,(i*93+30)%480,12,10,0xfff7bfd2);oval(c,180,230,119,118,0xffe79ebc);oval(c,180,230,109,108,0xffffedf2);for(int i=0;i<4;i++){int a=i<s.cells[s.field]?0xff4cb69b:0xffd5d9e4;oval(c,115+i*43,210,16,16,a);oval(c,111+i*43,206,4,4,0xfff5fffb);}if(s.sick){star(c,180,272,24,0xffad648d);text(c,"Treatment needed",180,330,17,0xff874c73);}else text(c,"Healthy cells",180,298,18,0xff874c73);text(c,"CELL  •  "+s.cells[s.field]+"/4",180,55,20,0xff874c73);canvas.restore();return;}
  color(sky);c.drawPaint(p);oval(c,290,75,31,31,0xffffefb4);for(int i=0;i<3;i++){float x=55+120*i;oval(c,x,98+(i%2)*32,34,13,0xffecfff7);oval(c,x-11,90+(i%2)*32,20,18,0xffecfff7);}
  oval(c,83,330,170,123,land);oval(c,290,340,170,126,land);rect(c,0,335,360,480,0,land);
  if(s.field==1){for(int i=0;i<9;i++)oval(c,(i*49)%360,330+i%3*36,24,3,0xff83dbe0);}else for(int i=0;i<10;i++){float x=(i*59+10)%360;rect(c,x,340+i%3*32,x+3,354+i%3*32,1,0xff3a966e);oval(c,x+4,340+i%3*32,5,4,0xffffe2a6);}
  float scale=zoom==1?.68f:1.15f;float cx=180,cy=300+bob;oval(c,cx,346,59*scale,8,0x22405055);c.save();c.translate(cx,cy);c.scale(scale,scale);
  if(s.stage==0){oval(c,0,0,43,55,0xffd8b2e8);oval(c,0,-3,39,50,0xfffff4ee);oval(c,-15,-19,11,8,0xfff0c2cb);oval(c,17,8,15,10,0xffc1dfec);oval(c,-9,28,8,7,0xffb9dccb);}
  else{
   int[] colors={0xffffd89a,0xffb9e5ee,0xffcbbbf7,0xffffbcd1};int body=colors[(s.field+s.body+s.color)%colors.length];int edge=0xff5d5273;
   float r=s.stage==1?33:s.stage==2?39:s.stage==3?45:50;
   oval(c,-r*.65f,r*.69f,15,12,edge);oval(c,r*.65f,r*.69f,15,12,edge);oval(c,-r*.65f,r*.62f,13,10,body);oval(c,r*.65f,r*.62f,13,10,body);
   if(s.stage>=2){float ear=s.body==1?34:19;oval(c,-r*.58f,-r*.72f,14,ear,edge);oval(c,r*.58f,-r*.72f,14,ear,edge);oval(c,-r*.58f,-r*.76f,11,ear-3,body);oval(c,r*.58f,-r*.76f,11,ear-3,body);}
   oval(c,0,-3,r+2,r*.85f+2,edge);oval(c,0,-4,r,r*.85f,body);oval(c,-r*.65f,7,8,5,0xffeea6ae);oval(c,r*.65f,7,8,5,0xffeea6ae);
   boolean blink=tick%3400<150;for(int side:new int[]{-1,1}){float x=side*r*.33f;oval(c,x,-9,5+s.eyes*.3f,blink?1.5f:8,0xff463850);if(!blink)oval(c,x-1,-12,1.8f,2,0xffffffff);}
   oval(c,0,11,4, s.sick?2:3,0xff775369);
   if(s.sick)star(c,40,-48,9,0xffab6094);
  }c.restore();
  if(!wallpaper){for(int i=0;i<s.waste;i++){float x=25+i*50;oval(c,x,385,11,5,0xff9b765e);oval(c,x,380,8,6,0xffb28b72);}text(c,zoom==1?s.fieldName().toUpperCase():s.stageName().toUpperCase(),180,47,21,0xff35465f);}
  canvas.restore();
 }
}
