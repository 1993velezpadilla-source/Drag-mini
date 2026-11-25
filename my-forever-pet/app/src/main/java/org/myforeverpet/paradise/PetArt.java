package org.myforeverpet.paradise;
import android.graphics.*;
/** Original low resolution sprites rendered nearest-neighbor; no official assets. */
final class PetArt {
 private final Bitmap buffer=Bitmap.createBitmap(160,192,Bitmap.Config.ARGB_8888);
 private final Canvas c=new Canvas(buffer);private final Paint p=new Paint();private final Paint blit=new Paint();
 private int ink=0xff353052;private final PetState[] crowd=new PetState[16];private Arcade crowdGame;private int crowdRound=-1;private final RectF destinationRect=new RectF();private final Typeface pixelFont=Typeface.create("monospace",Typeface.BOLD);
 private void r(int x,int y,int w,int h,int color){p.setColor(color);c.drawRect(x,y,x+w,y+h,p);}
 private void o(int x,int y,int rx,int ry,int color){p.setColor(color);c.drawOval(x-rx,y-ry,x+rx+1,y+ry+1,p);}
 private void line(int x,int y,int x2,int y2,int col){p.setColor(col);p.setStrokeWidth(1);c.drawLine(x,y,x2,y2,p);}
 private void t(String s,int x,int y,int size,int col){p.setColor(col);p.setTypeface(pixelFont);p.setTextSize(size);p.setTextAlign(Paint.Align.CENTER);c.drawText(s,x,y,p);}
 private int mix(int a,int b,float f){f=Math.max(0,Math.min(1,f));return Color.rgb((int)(Color.red(a)*(1-f)+Color.red(b)*f),(int)(Color.green(a)*(1-f)+Color.green(b)*f),(int)(Color.blue(a)*(1-f)+Color.blue(b)*f));}
 private String wallClock="";
 void setWallClock(String value){wallClock=value;}
 private void star(int x,int y,int col){r(x-1,y-3,3,7,col);r(x-3,y-1,7,3,col);}
 private void cloud(int x,int y,int col){o(x,y,14,6,col);o(x-5,y-4,7,7,col);o(x+5,y-2,9,7,col);}
 private final Path shapePath=new Path();
 private void poly(int color,int... xy){shapePath.reset();shapePath.moveTo(xy[0],xy[1]);for(int i=2;i<xy.length;i+=2)shapePath.lineTo(xy[i],xy[i+1]);shapePath.close();p.setColor(color);c.drawPath(shapePath,p);}
 private void family(int id,int body,int hi,long tick,boolean blink,int eyes){
  int dark=ink,accent=0xffffd18c,pink=0xffee8fa7,wing=(int)(tick/170)%2;
  switch(id){
  case 0:
   r(-15,-20,7,12,dark);r(8,-20,7,12,dark);r(-13,-18,4,8,body);r(10,-18,4,8,body);o(-9,15,7,5,dark);o(9,15,7,5,dark);o(-9,15,5,3,body);o(9,15,5,3,body);o(0,-1,19,17,dark);o(0,-1,17,15,body);break;
  case 1: // cat
   o(17,12,10,5,dark);o(17,11,7,3,body);poly(dark,-20,-5,-20,-24,-6,-15,7,-15,20,-24,20,7,14,17,-14,17);poly(body,-17,-6,-17,-19,-6,-12,7,-12,17,-19,17,6,12,14,-12,14);r(-20,5,6,1,dark);r(15,5,6,1,dark);break;
  case 2: // dog
   o(0,11,14,12,dark);o(0,11,11,9,body);o(-16,-6,7,16,dark);o(16,-6,7,16,dark);o(-16,-6,5,13,0xffb77c64);o(16,-6,5,13,0xffb77c64);o(0,-5,16,15,dark);o(0,-5,14,13,body);o(0,8,9,6,hi);o(0,5,4,2,dark);break;
  case 3: // dragon
   poly(dark,-10,4,-27,-12,-24,14,-11,17,10,17,25,13,28,-12,9,4);poly(0xff8c9ede,-12,5,-24,-7,-22,12,-10,14,10,14,22,10,25,-7,12,5);o(12,13,11,5,dark);o(12,13,8,3,body);poly(dark,-13,-11,-17,-26,-5,-16,5,-16,17,-26,13,-11);poly(accent,-13,-15,-15,-22,-8,-15,8,-15,15,-22,13,-15);o(0,0,15,17,dark);o(0,0,13,15,body);o(0,12,7,8,accent);break;
  case 4: // fish
   poly(dark,10,0,25,-14,25,14);poly(accent,13,0,22,-9,22,9);o(-3,0,20,13,dark);o(-3,0,17,11,body);o(-2,-12,6,4,dark);o(-2,-12,4,2,accent);r(-13,11,4,5,body);break;
  case 5: // alien
   o(0,13,9,10,dark);o(0,13,7,8,body);o(0,-7,20,17,dark);o(0,-7,17,14,body);line(-10,-19,-17,-27,dark);line(10,-19,17,-27,dark);o(-17,-27,4,4,dark);o(17,-27,4,4,dark);o(-17,-27,2,2,pink);o(17,-27,2,2,pink);break;
  case 6: // ghost
   poly(dark,-19,-4,-16,-18,-8,-24,8,-24,17,-17,19,3,22,18,12,14,5,21,-4,15,-13,21,-21,15);poly(body,-16,-4,-13,-16,-7,-21,7,-21,14,-15,16,3,18,14,12,11,5,17,-4,11,-13,17,-17,13);break;
  case 7: // octopus
   for(int i=0;i<4;i++){o(-16+i*10,13+(i%2)*3,7,8,dark);o(-16+i*10,13+(i%2)*3,5,6,body);}o(0,-4,18,17,dark);o(0,-4,16,15,body);break;
  case 8: // rooster
   o(18,5,11,13,dark);o(18,5,8,10,0xff79ae9a);o(0,9,15,14,dark);o(0,9,13,12,body);o(-4,-7,13,13,dark);o(-4,-7,11,11,hi);for(int i=0;i<3;i++)o(-11+i*7,-21+(i%2)*2,5,6,0xffd95d77);poly(dark,-4,0,-17,4,-4,8);poly(accent,-5,2,-14,4,-5,6);r(-9,20,3,5,accent);r(5,20,3,5,accent);break;
  case 9: // fairy
   o(-14,-1-wing,11,15,dark);o(14,-1-wing,11,15,dark);o(-14,-1-wing,9,12,0xffc2eaff);o(14,-1-wing,9,12,0xffc2eaff);poly(dark,-11,8,11,8,17,24,-17,24);poly(body,-8,9,8,9,13,21,-13,21);o(0,-8,12,13,dark);o(0,-8,10,11,hi);o(0,-17,12,5,body);star(20,-20,accent);break;
  case 10: // pixie
   poly(dark,-15,-12,-25,-16,-15,2,15,2,25,-16,15,-12);poly(body,-15,-10,-21,-13,-14,-1,14,-1,21,-13,15,-10);o(0,-8,14,14,dark);o(0,-8,12,12,hi);poly(dark,-17,-15,2,-29,17,-15);poly(body,-12,-16,2,-25,12,-16);poly(dark,-9,5,9,5,13,18,0,24,-13,18);poly(body,-7,7,7,7,10,17,0,21,-10,17);break;
  default: // owl
   poly(dark,-18,-11,-18,-24,-7,-16,7,-16,18,-24,18,-11,21,8,13,23,-13,23,-21,8);poly(body,-15,-11,-15,-19,-7,-13,7,-13,15,-19,15,-11,18,8,11,20,-11,20,-18,8);o(-7,-3,9,10,hi);o(7,-3,9,10,hi);o(0,11,8,8,hi);poly(accent,-3,4,3,4,0,9);break;
  }
  int ey=id==5?-9:(id==9||id==10||id==8?-7:-3),spread=id==5?9:7;
  for(int ex:new int[]{-spread,spread}){if(blink)r(ex-3,ey,6,1,dark);else{o(ex,ey,id==5?5:3,eyes==1?3:5,dark);r(ex-1,ey-3,2,2,hi);}}
  if(id!=8&&id!=11){r(-2,ey+9,5,1,dark);r(-12,ey+7,3,2,pink);r(9,ey+7,3,2,pink);}
 }
 private void sprite(PetState s,int x,int y,long tick,int scale){
  boolean asleep=s.sleeping();c.save();c.translate(x,y);c.scale(scale,scale);
  int bob=asleep?(int)(Math.sin(tick/1000.0)):(int)(Math.sin(tick/300.0)*2);c.translate(0,bob);if(asleep){c.translate(0,5);c.scale(1.05f,.78f);}
  int[] col={0xff9be5ac,0xfff4b6da,0xffffca89,0xffa3dcef,0xff85dbea,0xfff49cbd,0xffb8acfc,0xffe8b994,0xffb1a4fa,0xfff5c3e7,0xffffce79,0xffa4d8fa};
  int body=col[s.species()%col.length];int hi=0xfff9f2ff;
  o(0,19,22,4,0x334a3a77);if(s.stage>=1){int stride=asleep?0:(int)(tick/180)%2; r(-8,17+stride,4,2,ink);r(6,18-stride,4,2,ink);}
  if(s.stage==0){o(0,0,17,23,ink);o(0,-1,15,21,0xfffff4d3);o(-6,-10,5,4,0xffdab2ee);o(6,4,6,4,0xff9bd7dc);o(-4,13,4,4,0xfff2adc9);c.restore();return;}
  int shape=s.stage==1?s.field*4:s.species()%12;int palette=col[(s.species()+s.variant*5+s.color)%col.length];if(s.sick)palette=mix(palette,0xffa4a5bc,.5f);
  float size=s.stage==1?.8f:s.stage==2?.86f:s.stage==3?.94f:1f;c.scale(size,size);family(shape,palette,hi,tick,asleep||tick%3200<180,s.eyes);
  if(s.variant==1){star(-21,-22,0xffffde81);star(21,-22,0xffffde81);r(-10,24,20,2,0xffffde81);}
  if(!asleep&&s.hunger<=2)t("!",0,-28,8,0xffe26d78);
  if(s.equipped==1){r(-12,-20,24,4,ink);r(-8,-26,16,7,0xfff9ce63);star(0,-26,0xfffffae8);}
  if(s.equipped==2){r(-17,-14,9,6,0xffe661a0);r(-8,-12,4,3,ink);r(-4,-14,9,6,0xffe661a0);}
  if(s.equipped==3){o(0,-25,13,3,0xffffd65c);o(0,-25,9,1,0xff6459a5);}
  if(s.sick)star(21,-21,0xffb95a9b);if(asleep){t("zZ",18,-23,7,0xfff7e6b7);}else if(s.last-s.interactionAt<2500&&s.interactionAt>0){star(-22,-18,0xffee8fa7);star(22,-24,0xffffd566);}c.restore();
 }
 private void prop(PetState s){if(s.installation==0)return;int x=124,y=135;if(s.installation==4){r(x-14,y-8,28,15,ink);r(x-12,y-6,24,10,0xffe8f9ff);r(x-10,y-4,20,5,0xff72cde6);}else if(s.installation==5){r(x-21,y-17,6,24,ink);r(x+16,y-6,6,13,ink);r(x-19,y-13,40,16,ink);r(x-16,y-11,34,11,0xfff1e5fc);r(x-15,y-10,11,8,0xfffff9ff);r(x-3,y-9,21,10,0xff9e83d7);r(x-3,y-9,21,2,0xffd2bdf4);r(x-19,y+1,40,4,0xff8e6fae);r(x-17,y+5,4,4,ink);r(x+15,y+5,4,4,ink);}else{r(x-2,y-3,4,15,0xff78688b);r(x-10,y+10,20,3,ink);for(int i=0;i<5;i++)star(x-10+i*5,y-9+(i%2)*4,0xffff90b8);}}
 Bitmap itemIcon(int i){Bitmap b=Bitmap.createBitmap(48,48,Bitmap.Config.ARGB_8888);Canvas out=new Canvas(b);Paint q=new Paint();q.setAntiAlias(false);q.setColor(0xff353052);out.drawRoundRect(5,12,43,37,5,5,q);int[] colors={0xffffcf67,0xffe97db7,0xffffd98a,0xff7ddce9,0xffbca2ed,0xffed92b1};q.setColor(colors[i]);if(i==0){out.drawRect(13,7,35,25,q);out.drawRect(7,25,41,30,q);}else if(i==1){out.drawRect(8,13,21,33,q);out.drawRect(27,13,40,33,q);out.drawRect(21,20,27,27,q);}else if(i==2){out.drawOval(7,12,41,34,q);q.setColor(0xff353052);out.drawOval(13,17,35,29,q);}else if(i==3){out.drawRect(8,19,40,34,q);q.setColor(0xffe9ffff);out.drawRect(10,19,38,22,q);}else if(i==4){out.drawRect(7,11,12,36,q);out.drawRect(8,17,41,33,q);q.setColor(0xfffff1fe);out.drawRect(12,18,23,26,q);q.setColor(0xff9871c9);out.drawRect(24,18,39,30,q);out.drawRect(8,34,13,39,q);out.drawRect(35,34,40,39,q);}else{out.drawRect(21,20,27,39,q);for(int n=0;n<3;n++)out.drawOval(7+n*10,6+(n%2)*5,21+n*10,23+(n%2)*5,q);}return b;}
 Bitmap silhouette(PetState state){Bitmap im=creatureIcon(state);Bitmap out=Bitmap.createBitmap(64,64,Bitmap.Config.ARGB_8888);Canvas cv=new Canvas(out);Paint q=new Paint();q.setColorFilter(new PorterDuffColorFilter(0xff6e7294,PorterDuff.Mode.SRC_IN));cv.drawBitmap(im,0,0,q);im.recycle();return out;}
 Bitmap creatureIcon(PetState state){c.drawColor(Color.TRANSPARENT,PorterDuff.Mode.CLEAR);sprite(state,80,96,1000,1);return Bitmap.createBitmap(buffer,48,60,64,64);}
 void drawArcade(Canvas out,PetState s,Arcade game,long tick){
  c.drawColor(0xff9fdde1);for(int i=0;i<5;i++)cloud((i*41+12)%160,27+i%3*49,0xffe5f7f3);
  if(game.mode==Arcade.FIND){boolean refreshCrowd=crowdGame!=game||crowdRound!=game.round;crowdGame=game;crowdRound=game.round;c.drawColor(0xffb8ddc0);for(int i=0;i<16;i++){int x=20+i%4*40,y=51+i/4*38;r(x-18,y-17,36,34,(i%2==0)?0xffacd6b5:0xffc8e3c2);PetState d=s;if(i!=game.hidden){if(refreshCrowd||crowd[i]==null){d=new PetState();d.stage=4;d.field=game.faces[i]%12/4;d.body=game.faces[i]%4;d.variant=game.faces[i]/12;d.eyes=(i+1)%4;if(d.field==s.field&&d.body==s.body)d.body=(d.body+1)%4;crowd[i]=d;}else d=crowd[i];}c.save();c.translate(x,y);c.scale(.58f,.58f);sprite(d,0,0,1000,1);c.restore();}r(0,17,160,15,0xffe3f2da);t("FIND YOUR PET  "+game.wrong+"/5",80,27,7,ink);}
  else if(game.mode==Arcade.FLY){for(int i=0;i<5;i++){int x=(int)game.px[i],y=(int)game.py[i],gap=(int)Math.max(25,37-game.score*.4f);r(x-9,0,18,y-gap,ink);r(x-7,0,14,y-gap-2,0xff74b895);r(x-9,y+gap,18,192-y-gap,ink);r(x-7,y+gap+2,14,192-y-gap-2,0xff74b895);}}
  else if(game.mode==Arcade.JUMP){for(int i=0;i<5;i++){int x=(int)game.px[i],y=(int)game.py[i];r(x-15,y,30,5,ink);r(x-14,y,28,3,0xff91c98b);}}
  else{star((int)game.targetX,(int)game.targetY,0xffffbd52);}
  if(game.mode==Arcade.FIND){}else if(game.mode!=Arcade.STAR){c.save();c.translate(game.x,game.y);c.scale(.36f,.36f);sprite(s,0,0,tick,1);c.restore();}
  else {c.save();c.translate(20,170);c.scale(.48f,.48f);sprite(s,0,0,tick,1);c.restore();}
  r(0,0,160,17,0xff353052);t("SCORE "+game.score,80,12,9,0xffffebbd);
  if(!game.started||game.over){r(13,71,134,42,0xff353052);t(game.over?"GAME OVER":game.mode==Arcade.FLY?"TAP TO FLY":game.mode==Arcade.JUMP?"TOUCH TO STEER":game.mode==Arcade.FIND?"FIND YOUR PET":"TAP THE STARS",80,88,9,0xffffffff);t(game.over?"COLLECT REWARD":"READY?",80,103,8,0xffffd98a);}
  present(out);
 }
 private void present(Canvas out){out.drawColor(0xff171b39);float z=Math.min(out.getWidth()/160f,out.getHeight()/192f);float x=(out.getWidth()-160*z)/2,y=(out.getHeight()-192*z)/2;blit.setFilterBitmap(false);destinationRect.set(x,y,x+160*z,y+192*z);out.drawBitmap(buffer,null,destinationRect,blit);}
 void draw(Canvas out,PetState s,int zoom,boolean wall,long tick){
  p.setAntiAlias(false);c.drawColor(0xff20264d);
  if(zoom==0){for(int i=0;i<48;i++){int x=(i*73+19)%160,y=(i*61+7)%192;if(i%7==0)star(x,y,0xffc8b6f7);else r(x,y,1,1,0xffa8b1db);}o(80,95,49,49,0xff4b427e);o(80,95,46,46,0xff55b9db);o(67,76,23,17,0xff91d4a6);o(96,109,22,17,0xff96d2ab);o(62,112,12,8,0xff82c69d);o(66,59,10,4,0xffd4f6fb);o(117,68,4,4,0xffeac5ff);t("MY PLANET",80,17,9,0xfff4edff);t("BIOFUEL "+s.fuel,80,178,9,0xffeddfac);}
  else if(zoom==3){c.drawColor(0xff583c73);for(int i=0;i<24;i++)o((i*47)%160,(i*69)%192,8,6,0xff82598d);o(80,88,65,63,0xffe395c9);o(80,88,61,59,0xffffd7e9);t("CELL LAB",80,13,9,0xffffe7f5);
   for(int i=0;i<4;i++){int x=35+i*30;int color=i<s.cells[s.field]?0xff5eaf9a:0xffcba9d8;o(x,70,12,12,ink);o(x,70,10,10,color);if(i<s.cells[s.field])star(x,70,0xfff3ffdf);else r(x-3,69,7,2,0xfff4dcfb);}
   for(int i=0;i<s.germs;i++){int x=47+i*33;star(x,103,0xff9b3979);o(x,103,5,5,0xffa85294);r(x-2,102,1,1,0xffffffff);}
   t(s.sick?"TAP TO TREAT":s.stage==1?"FIELD CELLS "+s.cells[s.field]+"/4":"CARE RECORD",80,133,8,ink);t("FOOD "+s.hunger+"/5  JOY "+s.happy+"/10",80,157,8,0xffffe7f5);t("MISSES "+s.mistakes+"  DIET "+s.foods[0]+"/"+s.foods[1]+"/"+s.foods[2]+"/"+s.foods[3],80,173,7,0xffffe7f5);
  }else{
   boolean water=s.field==1,sky=s.field==2;int top=water?0xff3d87bd:sky?0xff8278ca:0xff79bddd, bottom=water?0xff74cbd0:sky?0xffd9b9ec:0xffbcf0c5;
   int minute=PetState.localMinute(System.currentTimeMillis(),java.util.TimeZone.getDefault());boolean night=minute<300||minute>=1140;
   float dark=night?1f:minute<420?(420-minute)/120f:minute>=1020?(minute-1020)/120f:0f;
   float twilight=(minute>=300&&minute<420)||(minute>=1020&&minute<1140)?(1f-Math.abs(dark*2f-1f)):0f;
   top=mix(mix(top,0xff202849,dark),0xffd18aa3,twilight*.8f);bottom=mix(mix(bottom,0xff495479,dark),0xffffcf9c,twilight*.85f);for(int y=0;y<192;y++){float f=y/191f;int rr=(int)(Color.red(top)*(1-f)+Color.red(bottom)*f),g=(int)(Color.green(top)*(1-f)+Color.green(bottom)*f),b=(int)(Color.blue(top)*(1-f)+Color.blue(bottom)*f);r(0,y,160,1,Color.rgb(rr,g,b));}
   if(night){o(127,31,11,11,0xfff7eddb);o(131,27,9,9,0xff35416f);for(int i=0;i<9;i++)star((i*37+14)%160,12+i%3*15,0xffe7d6fa);}else{float daylight=Math.max(0,Math.min(1,(minute-300)/840f));o(15+(int)(130*daylight),65-(int)(40*Math.sin(Math.PI*daylight)),13,13,0xffffe9a5);}cloud(32,27,mix(0xffe9f8f9,0xff657098,dark));cloud(92,43,mix(0xffe5e9fa,0xff626b93,dark));cloud(147,57,mix(0xffdcf3f4,0xff566486,dark));
   if(water){o(19,130,50,48,0xff4e9ba9);o(142,142,65,52,0xff539cab);r(0,140,160,52,0xff68bec2);for(int i=0;i<12;i++){int x=(i*37+5)%160,y=145+i%4*12;r(x,y,10,1,0xffa3e9df);r(x+2,y+1,4,1,0xff80d6d6);}for(int i=0;i<5;i++){int x=10+i*35;for(int j=0;j<3;j++)r(x+j%2*3,180-j*5,3,6,0xff4c9c9a);}}
   else{ o(14,134,62,50,0xff89c6aa);o(137,129,70,47,0xff91c9ac);r(0,143,160,49,0xff9ed7b1);for(int i=0;i<9;i++){int x=(i*29+6)%160,y=150+i%4*10;r(x,y,1,5,0xff5a9c8a);star(x,y,0xffffe3a9);} }
   if(dark>0)r(0,90,160,102,((int)(dark*90)<<24)|0x172342);prop(s);if(s.sleeping()){int bx=80,by=141;r(bx-38,by-9,76,16,ink);r(bx-36,by-8,72,12,0xffb7a2dc);r(bx-32,by-10,23,10,0xfff4e6f0);}int walk=s.sleeping()?0:(int)(Math.sin(tick/2400.0)*13);sprite(s,80+walk,111,tick,zoom==1?1:2);
   for(int i=0;i<s.waste;i++){int x=10+i*24;o(x,172,6,3,ink);o(x,170,4,4,0xffae805b);}
   if(!wall)t(zoom==1?s.fieldName().toUpperCase():s.creature().toUpperCase(),80,14,9,night?0xfff5e9fa:ink);else if(!wallClock.isEmpty()){r(52,181,56,11,0xff353052);t(wallClock,80,189,7,0xffffebbd);}
  }
  out.drawColor(0xff171b39);float z=Math.min(out.getWidth()/160f,out.getHeight()/192f);float x=(out.getWidth()-160*z)/2,y=(out.getHeight()-192*z)/2;blit.setFilterBitmap(false);destinationRect.set(x,y,x+160*z,y+192*z);out.drawBitmap(buffer,null,destinationRect,blit);
 }
}
