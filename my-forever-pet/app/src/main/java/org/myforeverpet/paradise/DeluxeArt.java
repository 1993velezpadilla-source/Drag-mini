package org.myforeverpet.paradise;
import android.graphics.*;
/** Original resolution-independent, shaded mascot and room art. No baked UI or borrowed assets. */
final class DeluxeArt {
 private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG|Paint.FILTER_BITMAP_FLAG);
 private final RectF rect=new RectF();private final Path path=new Path();
 private final int ink=0xff252447;
 private Bitmap background,roomBackground;private int bgKey=-1,roomKey=-1;
 private static final int[] BODY={0xff9fee62,0xffefa5cf,0xffe9b16d,0xff76d4b2,0xff75d8f3,0xffa4df7c,0xffd8c9ff,0xfff2a38b,0xffffcf72,0xffe5b3fb,0xffa1e7da,0xffa0b5e9};
 private static int mix(int a,int b,float k){return Color.rgb((int)(Color.red(a)*(1-k)+Color.red(b)*k),(int)(Color.green(a)*(1-k)+Color.green(b)*k),(int)(Color.blue(a)*(1-k)+Color.blue(b)*k));}
 private void solid(int color){p.setShader(null);p.setColor(color);p.setStyle(Paint.Style.FILL);}
 private void oval(Canvas c,float x,float y,float rx,float ry,int color){solid(color);rect.set(x-rx,y-ry,x+rx,y+ry);c.drawOval(rect,p);}
 private void round(Canvas c,float x,float y,float w,float h,float radius,int color){solid(color);rect.set(x,y,x+w,y+h);c.drawRoundRect(rect,radius,radius,p);}
 private void line(Canvas c,float x,float y,float x2,float y2,float w,int color){solid(color);p.setStrokeWidth(w);p.setStrokeCap(Paint.Cap.ROUND);c.drawLine(x,y,x2,y2,p);}
 private void poly(Canvas c,int color,float... xy){solid(color);path.reset();path.moveTo(xy[0],xy[1]);for(int i=2;i<xy.length;i+=2)path.lineTo(xy[i],xy[i+1]);path.close();c.drawPath(path,p);}
 private void gradient(Canvas c,float x,float y,float w,float h,float radius,int a,int b){solid(-1);p.setShader(new LinearGradient(x,y,x+w*.28f,y+h,a,b,Shader.TileMode.CLAMP));rect.set(x,y,x+w,y+h);c.drawRoundRect(rect,radius,radius,p);p.setShader(null);}
 private void form(Canvas c,float x,float y,float rx,float ry,int color){oval(c,x,y+1,rx+1.8f,ry+1.8f,ink);solid(-1);p.setShader(new RadialGradient(x-rx*.32f,y-ry*.53f,Math.max(rx,ry)*1.9f,new int[]{mix(color,0xffffffff,.52f),color,mix(color,0xff30396c,.49f)},new float[]{0,.52f,1},Shader.TileMode.CLAMP));rect.set(x-rx,y-ry,x+rx,y+ry);c.drawOval(rect,p);p.setShader(null);}
 private void sparkle(Canvas c,float x,float y,float s,int color){poly(c,color,x,y-s,x+s*.23f,y-s*.22f,x+s,y,x+s*.22f,y+s*.23f,x,y+s,x-s*.23f,y+s*.22f,x-s,y,x-s*.22f,y-s*.22f);}
 private void heart(Canvas c,float x,float y,float sz,int color){solid(color);path.reset();path.moveTo(x,y+sz*.7f);path.cubicTo(x-sz*1.7f,y-sz*.3f,x-sz*.55f,y-sz*1.2f,x,y-sz*.45f);path.cubicTo(x+sz*.55f,y-sz*1.2f,x+sz*1.7f,y-sz*.3f,x,y+sz*.7f);c.drawPath(path,p);}
 private void ear(Canvas c,float x,float y,int color,boolean point){if(point){poly(c,ink,x-8,y+10,x-7,y-13,x+9,y+3);poly(c,color,x-5,y+6,x-4,y-8,x+6,y+3);poly(c,0xffedb3d0,x-3,y+3,x-3,y-4,x+2,y+2);}else form(c,x,y,6,12,color);}
 void pet(Canvas c,PetState s,float x,float y,float scale,long tick){
  int id=s.stage==PetState.BABY?s.field*4:s.species()%12;int color=BODY[(id+s.color+s.variant*5)%BODY.length];if(s.sick)color=mix(color,0xffa9a3bb,.45f);boolean asleep=s.sleeping();float bob=asleep?0:(float)Math.sin(tick/420.0)*1.3f;
  c.save();c.translate(x,y);c.scale(scale,scale);oval(c,0,23,25,5,0x48302854);c.translate(0,bob);if(asleep){c.translate(0,5);c.scale(1.04f,.82f);}
  if(s.stage==PetState.EGG){form(c,0,-1,17,23,0xffffe5b4);oval(c,-6,-8,5,4,0xffba98e5);oval(c,6,4,5,4,0xff84d9d1);oval(c,-4,12,4,3,0xffed95c4);c.restore();return;}
  float growth=s.stage==1?.88f:s.stage==2?.94f:s.stage==3?1f:1.06f;c.scale(growth,growth);
  float ey=-3,spread=8,rx=19,ry=19,cy=0;
  switch(id){
   case 0:ear(c,-12,-18,color,true);c.save();c.scale(-1,1);ear(c,-12,-18,color,true);c.restore();form(c,-10,19,8,5,color);form(c,10,19,8,5,color);break;
   case 1:form(c,20,13,11,5,color);ear(c,-14,-17,color,true);c.save();c.scale(-1,1);ear(c,-14,-17,color,true);c.restore();form(c,-10,19,6,5,color);form(c,10,19,6,5,color);rx=20;ry=17;break;
   case 2:form(c,0,14,13,11,color);form(c,-9,22,6,4,color);form(c,9,22,6,4,color);form(c,-18,-3,7,15,0xffa77662);form(c,18,-3,7,15,0xffa77662);rx=17;ry=16;cy=-3;ey=-5;break;
   case 3:poly(c,ink,-12,0,-31,-15,-25,16,-10,14,10,14,25,16,31,-15,12,0);poly(c,0xff8da9ed,-13,2,-27,-9,-23,12,-10,11,10,11,23,12,27,-9,13,2);form(c,21,16,10,5,color);ear(c,-12,-20,0xffffd69a,true);c.save();c.scale(-1,1);ear(c,-12,-20,0xffffd69a,true);c.restore();form(c,-9,21,7,5,color);form(c,9,21,7,5,color);rx=17;ry=18;break;
   case 4:poly(c,ink,10,0,30,-16,29,16);poly(c,0xffefa96d,14,0,27,-11,26,11);form(c,-3,-15,7,4,0xffffd587);rx=21;ry=14;cy=0;ey=-2;break;
   case 5:form(c,0,14,9,12,color);line(c,-10,-19,-16,-29,2,ink);line(c,10,-19,16,-29,2,ink);form(c,-16,-29,4,4,0xfff1a4c8);form(c,16,-29,4,4,0xfff1a4c8);rx=21;ry=17;cy=-7;ey=-8;spread=9;break;
   case 6:form(c,-14,17,7,8,color);form(c,0,20,7,8,color);form(c,14,17,7,8,color);ry=23;cy=-3;break;
   case 7:for(int i=0;i<5;i++)form(c,-19+i*9.5f,17+(i%2)*3,6,9,color);rx=19;ry=17;cy=-3;break;
   case 8:form(c,21,6,12,15,0xff74b7a1);form(c,0,11,15,12,color);for(int i=0;i<3;i++)form(c,-9+i*7,-20+(i%2)*2,5,7,0xffe97391);form(c,-8,22,5,3,0xffffc76b);form(c,8,22,5,3,0xffffc76b);rx=15;ry=15;cy=-4;ey=-6;break;
   case 9:form(c,-20,1,10,16,0xffbee9ff);form(c,20,1,10,16,0xffbee9ff);poly(c,ink,-10,6,10,6,17,26,-17,26);poly(c,color,-8,8,8,8,13,23,-13,23);rx=13;ry=14;cy=-8;ey=-9;spread=6;break;
   case 10:poly(c,ink,-11,-8,-28,-15,-17,4,17,4,28,-15,11,-8);poly(c,color,-12,-7,-24,-11,-15,1,15,1,24,-11,12,-7);form(c,0,16,12,10,color);rx=14;ry=15;cy=-7;ey=-8;spread=6;break;
   case 11:ear(c,-13,-18,color,true);c.save();c.scale(-1,1);ear(c,-13,-18,color,true);c.restore();form(c,-10,21,6,4,0xffffbd70);form(c,10,21,6,4,0xffffbd70);rx=20;ry=20;break;
  }
  form(c,0,cy,rx,ry,color);
  oval(c,-rx*.42f,cy-ry*.53f,rx*.23f,ry*.105f,0x88ffffff);
  if(id==2)oval(c,0,7,9,6,0xffffead6);
  if(id==11){oval(c,-8,-2,8,10,0xffffe9cc);oval(c,8,-2,8,10,0xffffe9cc);}
  boolean blink=asleep||tick%3700<130;for(int i=-1;i<=1;i+=2){float ex=i*spread;if(blink){line(c,ex-3,ey,ex+3,ey,1.5f,ink);}else{oval(c,ex,ey,4.8f,id==5?7.5f:7,ink);oval(c,ex+.3f,ey+2,3.8f,4.1f,0xff403060);oval(c,ex-1.5f,ey-2.8f,1.9f,2.3f,0xfffffcff);oval(c,ex+2,ey+3,0.85f,1.1f,0xffb5a3dc);}}
  if(id==8||id==11){poly(c,ink,-4,3,4,3,0,10);poly(c,0xffffbf68,-3,4,3,4,0,8);}else if(id==2){oval(c,0,4,3,2,ink);line(c,0,5,0,8,1,ink);}else if(!asleep&&s.happy>=6){oval(c,0,9,4.4f,3.5f,ink);oval(c,0,11,2.8f,1.2f,0xffed83a2);}else line(c,-2,9,2,9,1.2f,ink);
  if(id==1){for(int j=0;j<2;j++){line(c,-14,5+j*3,-22,3+j*4,.8f,ink);line(c,14,5+j*3,22,3+j*4,.8f,ink);}}
  oval(c,-13,7,3.3f,1.8f,0xffef91ae);oval(c,13,7,3.3f,1.8f,0xffef91ae);
  if(id==10){poly(c,ink,-17,-17,1,-32,16,-17);poly(c,0xff64b68e,-13,-18,1,-29,12,-18);sparkle(c,14,-23,3,0xffffde87);}
  if(s.equipped==1){round(c,-11,-27,22,9,2,ink);gradient(c,-10,-29,20,10,2,0xffffe9a1,0xffe39b3f);sparkle(c,0,-25,4,0xffffffff);}else if(s.equipped==2){form(c,-15,-16,6,4,0xffed86b9);form(c,-5,-16,6,4,0xffed86b9);}else if(s.equipped==3){oval(c,0,-28,13,3.5f,0xfff8d477);oval(c,0,-28,9,1.6f,ink);}
  if(s.variant==1){sparkle(c,-25,-21,4,0xffffd47a);sparkle(c,25,-25,3,0xffffe3ad);}
  if(asleep){text(c,"zZ",24,-22,8,0xffffedc0);}else if(s.interactionAt>0&&s.last-s.interactionAt<2500){heart(c,24,-25,5,0xfff7a3c5);}
  c.restore();
 }
 private void text(Canvas c,String t,float x,float y,float size,int color){solid(color);p.setTypeface(Typeface.create("sans-serif-medium",0));p.setTextSize(size);p.setTextAlign(Paint.Align.CENTER);c.drawText(t,x,y,p);}
 private void plant(Canvas c,float x,float y,float s){c.save();c.translate(x,y);c.scale(s,s);gradient(c,-7,-4,14,12,3,0xffe8aa88,0xff885e73);for(int i=0;i<5;i++){c.save();c.rotate(-55+i*27);gradient(c,-3,-24,6,24,4,0xffa6d68d,0xff4b8a75);c.restore();}c.restore();}
 private void starLamp(Canvas c,float x,float y,int length){line(c,x,0,x,y,1,0xffb8a0a6);solid(-1);p.setShader(new RadialGradient(x,y,16,new int[]{0x99ffbd61,0x00ffbd61},null,Shader.TileMode.CLAMP));c.drawCircle(x,y,16,p);p.setShader(null);sparkle(c,x,y,6,0xffefad5d);sparkle(c,x,y,4,0xffffedac);}
 private void bed(Canvas c){oval(c,38,122,35,7,0x55302547);round(c,8,57,49,52,12,0xff513b69);gradient(c,10,56,45,51,12,0xffb98fc3,0xff635085);poly(c,0xffad82b0,10,65,10,43,29,57,44,57,56,43,55,68);poly(c,0xfff3b9c4,14,61,14,50,25,58,43,58,52,50,52,61);round(c,5,96,62,20,6,0xff79536a);gradient(c,6,87,61,25,7,0xffece3fc,0xffa49dcf);gradient(c,10,87,23,12,5,0xfffef1ed,0xffc9b9df);gradient(c,31,88,35,25,5,0xff838fe3,0xff4b4d9e);for(int i=0;i<6;i++)sparkle(c,36+(i%3)*11,94+(i/3)*11,2.8f,0xffffd681);round(c,9,112,5,8,2,0xff674b63);round(c,57,112,5,8,2,0xff674b63);}
 private void window(Canvas c,boolean night){oval(c,83,45,30,34,0xff4e3c6d);oval(c,83,45,27,31,0xffc18d87);oval(c,83,45,24,28,night?0xff25375e:0xff82d6ec);c.save();path.reset();path.addOval(59,17,107,73,Path.Direction.CW);c.clipPath(path);if(night){oval(c,92,30,7,7,0xffffe8bb);oval(c,95,28,6,6,0xff25375e);for(int i=0;i<8;i++)sparkle(c,63+i*5,23+(i*11)%26,1,0xffe2d5ff);}else{oval(c,93,29,8,8,0xffffe5a0);oval(c,68,39,12,4,0xffe6f7ff);oval(c,78,36,7,5,0xfff4fcff);}oval(c,66,72,25,22,night?0xff426370:0xff80b99b);oval(c,106,75,23,25,night?0xff325b6a:0xff639a80);c.restore();line(c,83,18,83,72,3,0xffbc8d83);line(c,60,45,106,45,3,0xffbc8d83);round(c,56,72,54,4,2,0xffac7c7e);}
 private void buildRoom(int theme,boolean night){if(background==null)background=Bitmap.createBitmap(800,960,Bitmap.Config.ARGB_8888);Canvas c=new Canvas(background);c.scale(5,5);int wall=theme==1?0xff477f9b:theme==2?0xff60509a:0xff725486;gradient(c,0,0,160,192,0,night?0xff2b294b:wall,0xff332c59);for(int i=0;i<8;i++){int x=i*23-4;round(c,x,0,2,124,1,0x33533e67);line(c,x+3,0,x+3,116,.7f,0x44b592bb);}
  gradient(c,0,113,160,79,0,0xffb58479,0xff755b7c);for(int i=-4;i<=4;i++)line(c,80+i*10,115,80+i*39,192,.9f,0x88745164);for(int i=0;i<5;i++){float y=117+i*i*4;line(c,0,y,160,y,1,0x88745164);}round(c,0,110,160,5,1,0xff5c4168);
  window(c,night);plant(c,59,72,.65f);starLamp(c,32,24,24);starLamp(c,48,40,40);starLamp(c,110,24,24);bed(c);
  for(int y:new int[]{51,83}){round(c,112,y,45,5,2,0xff5b3c64);gradient(c,111,y-2,47,4,1,0xffd0a18b,0xff875c72);}
  plant(c,119,48,.66f);for(int i=0;i<4;i++)gradient(c,113+i*5,65-(i%2)*3,4,17+(i%2)*3,1,0xffc5a8e6-i*0x00070403,0xff6b659f);form(c,143,39,8,10,0xffc49aff);sparkle(c,143,36,4,0xfff5deff);gradient(c,136,67,18,13,3,0xff263e76,0xff5e6cb7);heart(c,145,73,3,0xff8bdcff);
  oval(c,80,157,63,24,0x55382751);oval(c,80,153,61,23,0xff626fb3);oval(c,80,152,55,19,0xff9ba9e7);oval(c,80,152,47,15,0xffe5d5e7);for(int i=0;i<12;i++){double a=i*Math.PI/6;oval(c,80+(float)Math.cos(a)*51,152+(float)Math.sin(a)*17,2,1.5f,0xffd6c5ee);}
  plant(c,8,169,1.2f);plant(c,152,112,.9f);form(c,30,146,9,9,0xff73a7e0);c.save();c.rotate(-32,30,146);gradient(c,26,138,7,16,3,0xffffd166,0xffe69b52);c.restore();
  gradient(c,119,137,31,13,5,0xffcb8ee9,0xff694997);oval(c,134,138,16,6,0xff553661);oval(c,134,137,13,4,0xffb47d60);for(int i=0;i<8;i++)oval(c,124+(i%4)*6,135+(i/4)*3,2.4f,1.8f,0xffe0a36d);
  if(night){round(c,0,0,160,192,0,0x4421244b);}bgKey=theme+(night?4:0);
 }
 void home(Canvas out,PetState s,long tick,boolean wall,String clock){boolean night=s.sleeping()||PetState.localMinute(System.currentTimeMillis(),java.util.TimeZone.getDefault())>=19*60||PetState.localMinute(System.currentTimeMillis(),java.util.TimeZone.getDefault())<5*60;int key=s.roomTheme+(night?4:0);if(key!=bgKey||background==null)buildRoom(s.roomTheme,night);out.save();out.scale(out.getWidth()/160f,out.getHeight()/192f);solid(-1);rect.set(0,0,160,192);out.drawBitmap(background,null,rect,p);
  float x=s.sleeping()?36:80,y=s.sleeping()?83:125;float sx=out.getWidth()/160f,sy=out.getHeight()/192f;out.save();out.translate(x,y);float uniform=Math.min(sx,sy);out.scale(uniform/sx,uniform/sy);pet(out,s,0,0,s.sleeping()?1.05f:1.56f,tick);out.restore();
  if(!s.sleeping()&&s.stage>0){float bx=111,by=82+(float)Math.sin(tick/700.0)*1.5f;oval(out,bx,by,11,9,0xfff8eefb);poly(out,0xfff8eefb,bx-4,by+5,bx-7,by+13,bx+1,by+7);heart(out,bx,by,5,s.hunger<=2?0xffe8ae66:0xffed85b2);}
  if(s.waste>0){for(int i=0;i<Math.min(s.waste,6);i++){float px=44+i*14;oval(out,px,179,4,2,0xff76535f);oval(out,px,177,3,3,0xffa87964);}}
  if(wall){text(out,s.displayName()+(clock.isEmpty()?"":" · "+clock),80,187,7,0xfff3e7ff);}out.restore();
 }
 private void bowl(Canvas c,float x,float y,int color){oval(c,x,y+3,19,5,0x44302a46);gradient(c,x-16,y-4,32,12,5,mix(color,0xffffffff,.3f),mix(color,0xff403059,.4f));oval(c,x,y-3,16,6,0xff49334d);for(int i=0;i<8;i++)oval(c,x-10+i%4*6,y-5+i/4*3,3,2,0xffdca16a);}
 private void cabinet(Canvas c,float x,float y,float w,float h,int color){round(c,x,y,w,h,4,0xff513d63);gradient(c,x+2,y+2,w-4,h-4,3,mix(color,0xffffffff,.2f),mix(color,0xff4a3a68,.36f));line(c,x+3,y+h/2,x+w-3,y+h/2,.9f,0xff6e5473);line(c,x+w*.25f,y+h*.37f,x+w*.42f,y+h*.37f,1.8f,0xfff8d6a4);line(c,x+w*.25f,y+h*.73f,x+w*.42f,y+h*.73f,1.8f,0xfff8d6a4);}
 private void buildOtherRoom(int room,int theme,boolean night){if(roomBackground==null)roomBackground=Bitmap.createBitmap(800,960,Bitmap.Config.ARGB_8888);Canvas c=new Canvas(roomBackground);c.scale(5,5);
  int[] walls={0xffce9c97,0xff729faf,0xff8b79b3,0xff947cb7,0xff97c4bc,0xff8273b7};int wall=mix(walls[room],theme==1?0xff6ca5b6:theme==2?0xff8877d3:walls[room],.25f);
  gradient(c,0,0,160,192,0,night?mix(wall,0xff272347,.5f):wall,0xff61547d);gradient(c,0,115,160,77,0,0xffcda58e,0xff8a698b);
  for(int i=-4;i<=4;i++)line(c,80+i*14,115,80+i*42,192,.9f,0x88745164);for(int i=0;i<6;i++)line(c,0,116+i*i*3,160,116+i*i*3,1,0x66745164);round(c,0,110,160,6,1,0xff685274);window(c,night);
  if(room==0){cabinet(c,7,71,43,43,0xffdda899);cabinet(c,107,31,43,84,0xffdbc6a7);round(c,4,66,49,7,2,0xfff1d2b2);plant(c,17,62,.7f);round(c,0,146,160,46,6,0xff78556b);gradient(c,0,144,160,48,6,0xffe4bb92,0xffa67d83);bowl(c,31,163,0xffe89dc6);form(c,129,161,10,9,0xffe88aa5);line(c,129,154,132,148,2,0xff5a946c);oval(c,135,151,5,2,0xff87ca91);}
  else if(room==1){for(int i=0;i<8;i++){line(c,i*22,24,i*22,115,.8f,0x5583d9e6);line(c,0,25+i*13,160,25+i*13,.8f,0x5583d9e6);}round(c,20,108,100,40,10,0xff4b587b);gradient(c,22,108,96,36,9,0xfff2f9fa,0xff91b5d0);oval(c,70,111,47,9,0xff619cc4);oval(c,70,110,42,6,0xffb8e8ed);line(c,27,111,27,94,3,0xffd1e4f0);line(c,27,94,36,94,3,0xffd1e4f0);cabinet(c,125,62,27,35,0xffe6eff2);oval(c,137,101,14,10,0xff4b587b);oval(c,137,99,12,8,0xfff0f7fa);oval(c,137,99,8,4,0xff88bad1);gradient(c,18,151,28,15,6,0xffffcae5,0xffca73a9);gradient(c,122,148,19,22,5,0xffc0f2ff,0xff70a5d2);round(c,125,144,13,5,2,0xffefeaff);}
  else if(room==2){bed(c);cabinet(c,116,86,32,29,0xffb88fae);line(c,134,64,134,86,3,0xff78617f);poly(c,0xff513e63,122,51,146,51,152,72,116,72);poly(c,night?0xff9a83aa:0xffffd898,124,53,144,53,148,69,120,69);if(!night){solid(-1);p.setShader(new RadialGradient(134,66,24,new int[]{0x66ffeab2,0x00ffeab2},null,Shader.TileMode.CLAMP));c.drawCircle(134,66,24,p);p.setShader(null);}starLamp(c,46,29,29);starLamp(c,110,24,24);oval(c,85,151,49,19,0xff837eac);oval(c,85,151,43,14,0xffc2aed7);}
  else if(room==3){cabinet(c,7,67,42,44,0xffc49ac1);gradient(c,111,43,36,28,5,0xff797bc9,0xff413967);heart(c,129,56,6,0xffa6d7ff);plant(c,18,62,.75f);oval(c,80,146,35,12,0xff49365e);oval(c,80,143,33,9,0xff8170bd);oval(c,80,142,27,6,0xffd1a8ec);for(int i=0;i<4;i++)line(c,57+i*15,149,57+i*15,155,2,0xff634b73);form(c,26,161,10,10,0xff85b7df);c.save();c.rotate(-32,26,161);gradient(c,23,151,6,20,3,0xfff9d478,0xffdfa057);c.restore();cabinet(c,120,151,29,25,0xffe4a8cd);sparkle(c,135,159,6,0xffffe4a3);}
  else if(room==4){gradient(c,0,0,160,192,0,night?0xff3c4f78:0xff9bd9de,night?0xff536e89:0xffc6e5c5);for(int i=0;i<5;i++)oval(c,i*43,111,36,43,night?0xff526e78:0xff77af8e);gradient(c,0,119,160,73,0,0xff9ed6a3,0xff689b8d);for(int i=0;i<8;i++){float x=5+i*22;line(c,x,104,x,129,3,0xff9a7c75);}line(c,0,111,160,111,3,0xffbd9784);line(c,0,121,160,121,3,0xffbd9784);round(c,15,139,130,38,6,0xff715460);gradient(c,18,142,124,32,5,0xffac8068,0xff8b6567);for(int i=0;i<14;i++)oval(c,23+(i*13)%112,150+(i*7)%19,1.5f,.7f,0xffcb9c81);plant(c,8,133,.7f);plant(c,150,133,.7f);}
  else {for(int j=0;j<2;j++){gradient(c,7,52+j*27,145,5,2,0xffb49ac6,0xff695b8f);for(int i=0;i<6;i++){float x=19+i*24,y=43+j*27;form(c,x,y,5,8,new int[]{0xffa5e1d2,0xffdcb0ef,0xffeebba6}[i%3]);round(c,x-3,y-9,6,4,1,0xffead9bc);}}gradient(c,0,144,160,48,6,0xffbaa4db,0xff6b598f);gradient(c,30,150,20,25,5,0xffdcf4df,0xff80bca6);round(c,38,154,4,17,1,0xfff8f5ed);round(c,32,160,16,4,1,0xfff8f5ed);cabinet(c,111,150,30,25,0xffe0b1b6);}
  if(night&&room!=4)round(c,0,19,160,173,0,0x221c2146);roomKey=room+theme*8+(night?32:0);
 }
 void room(Canvas out,PetState s,int room,long tick,int effect){boolean night=s.sleeping();int key=room+s.roomTheme*8+(night?32:0);if(roomBackground==null||key!=roomKey)buildOtherRoom(room,s.roomTheme,night);
  out.drawColor(0xff282343);float z=Math.min(out.getWidth()/160f,out.getHeight()/192f);out.save();out.translate((out.getWidth()-160*z)/2,(out.getHeight()-192*z)/2);out.scale(z,z);solid(-1);rect.set(0,0,160,192);out.drawBitmap(roomBackground,null,rect,p);
  float x=80,y=room==4?93:104;if(room==2&&s.sleeping()){x=36;y=83;}float lift=effect==4?(float)Math.abs(Math.sin(tick/120.0))*15:0;pet(out,s,x,y-lift,1.32f,tick);
  if(room==1&&s.soap>0){for(int i=0;i<s.soap*6;i++){float px=51+(i*17)%58,py=72+(i*11)%48;oval(out,px,py,3+i%3,3+i%3,0xffd9f9ff);oval(out,px-1,py-1,1.3f,1.3f,0xffffffff);}}
  if(room==4&&s.gardenAt>0){for(int i=0;i<5;i++){float px=31+i*24;line(out,px,156,px,145,2,0xff5e956b);oval(out,px-3,147,5,2,0xff79c887);oval(out,px+3,144,5,2,0xff88ce92);if(s.clockNow>=s.gardenAt)form(out,px,142,4,4,0xffe08aa7);}}
  if(effect>0)for(int i=0;i<5;i++)sparkle(out,48+i*16,65-(tick/100+i*5)%18,2.4f,effect==2?0xffdbfbff:0xffffe19f);
  String[] names={"Kitchen","Bathroom","Bedroom","Playroom","Garden","Potion lab"};gradient(out,37,3,86,14,6,0xff5f5086,0xff352b5c);text(out,names[room],80,12.5f,8,0xffffebd6);
  if(room==0){text(out,"FOOD",31,185,7,0xfffff1e4);text(out,"SNACK",130,185,7,0xfffff1e4);}else if(room==1){text(out,"SOAP",32,182,7,0xfffaf0ff);text(out,"RINSE",132,182,7,0xfffaf0ff);text(out,"WC",137,119,6,0xfffaf0ff);}else if(room==3){text(out,"BALL",26,186,7,0xfffaf0ff);text(out,"TOY",135,186,7,0xfffaf0ff);}else if(room==4){text(out,s.gardenAt==0?"PLANT":s.clockNow>=s.gardenAt?"HARVEST":"GROWING",80,185,7,0xfffff1d8);}else if(room==5){text(out,"CURE",40,185,7,0xfffaf0ff);text(out,"BUY",125,185,7,0xfffaf0ff);}out.restore();
 }
 Bitmap icon(PetState s){Bitmap b=Bitmap.createBitmap(192,192,Bitmap.Config.ARGB_8888);Canvas c=new Canvas(b);c.translate(96,99);c.scale(3,3);pet(c,s,0,0,1,1000);return b;}
}
