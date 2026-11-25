package org.myforeverpet.paradise;
import java.util.Random;
/** Fixed timestep, normalized 160x192 world. No Android dependency. */
public final class Arcade {
 public static final int STAR=0,FLY=1,JUMP=2,FIND=3;
 public final int mode;public boolean over,started;public int score,ticks;public float x=48,y=96,vy,steer,targetX=80,targetY=96;
 public final float[] px=new float[5],py=new float[5];private final boolean[] passed=new boolean[5];private final Random rng;private boolean claimed;public int hidden,round=0,wrong=0;public final int[] faces=new int[16];
 public Arcade(int mode,long seed){this.mode=mode;rng=new Random(seed);if(mode==FIND)shuffle();if(mode==FLY){for(int i=0;i<5;i++){px[i]=180+i*65;py[i]=55+rng.nextInt(75);}}else if(mode==JUMP){x=80;y=145;vy=-3.8f;for(int i=0;i<5;i++){px[i]=i==0?80:25+rng.nextInt(110);py[i]=165-i*40;}}}
 private void shuffle(){hidden=rng.nextInt(16);for(int i=0;i<16;i++)faces[i]=i==hidden?-1:rng.nextInt(24);}
 public void input(float a,float b){if(over)return;if(mode==FIND){if(!started){started=true;return;}if(a<0||a>=160||b<32||b>=184)return;int hit=(int)((b-32)/38)*4+(int)(a/40);if(hit==hidden){score++;round++;if(round>=8)over=true;else shuffle();}else{wrong++;if(wrong>=5)over=true;}return;}started=true;if(mode==FLY){vy=-3.4f;}else if(mode==JUMP){steer=Math.max(-1,Math.min(1,(a-x)/24));}else if(Math.hypot(a-targetX,b-targetY)<13){score++;targetX=18+rng.nextInt(124);targetY=30+rng.nextInt(140);}}
 public void release(){steer=0;}
 public void step(){if(over||!started)return;ticks++;if(ticks>=3600){over=true;return;}
 if(mode==FIND){if(ticks>=1800)over=true;return;}
 if(mode==STAR){if(ticks>=900)over=true;return;}
 if(mode==FLY){vy=Math.min(5,vy+.20f);y+=vy;if(y<9||y>181)over=true;for(int i=0;i<5;i++){px[i]-=1.35f;float gap=Math.max(25,37-score*.4f);if(Math.abs(px[i]-x)<12&&(y-8<py[i]-gap||y+8>py[i]+gap))over=true;if(!passed[i]&&px[i]+9<x-8&&!over){score++;passed[i]=true;}if(px[i]<-12){float max=0;for(float p:px)max=Math.max(max,p);px[i]=max+65;py[i]=55+rng.nextInt(75);passed[i]=false;}}}
 else{float oldY=y;x+=steer*2.5f;if(x<0)x+=160;if(x>160)x-=160;vy+=.13f;y+=vy;for(int i=0;i<5;i++){if(vy>0&&oldY+7<=py[i]&&y+7>=py[i]&&Math.abs(x-px[i])<20){y=py[i]-7;vy=-3.9f;score++;break;}}if(y<75){float delta=75-y;y=75;for(int i=0;i<5;i++){py[i]+=delta;if(py[i]>195){float min=192;for(float p:py)min=Math.min(min,p);py[i]=min-40;px[i]=22+rng.nextInt(116);}}}if(y>202)over=true;}
 }
 public int claim(){if(claimed)return 0;claimed=true;return Economy.reward(mode,score,ticks);}
}
