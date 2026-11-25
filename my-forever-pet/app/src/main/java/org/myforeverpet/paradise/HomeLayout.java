package org.myforeverpet.paradise;
import java.io.InputStream;
import java.io.IOException;
import java.util.Properties;
/** Coordinates in the 160x192 scene, exported by Blender's actual render camera. */
final class HomeLayout {
 static final int NONE=0,PET=1,BED=2,BOWL=3,BALL=4,LAB=5,CONSOLE=6;
 final float[] rug={80,161},bedAnchor={36,107};
 final float[][] bounds={{0,0,0,0},{0,0,0,0},{8,42,66,120},{113,127,151,158},{16,128,44,166},{110,20,157,87},{5,123,30,147}};
 static HomeLayout read(InputStream stream)throws IOException {HomeLayout h=new HomeLayout();Properties p=new Properties();p.load(stream);parse(p,"rug",h.rug);parse(p,"bed_anchor",h.bedAnchor);String[] keys={"bed","bowl","ball","lab","console"};for(int i=0;i<keys.length;i++)parse(p,keys[i],h.bounds[i+2]);return h;}
 private static void parse(Properties p,String key,float[] dst)throws IOException {String s=p.getProperty(key);if(s==null)throw new IOException("Missing "+key);String[] a=s.split(",");if(a.length!=dst.length)throw new IOException("Invalid "+key);try{for(int i=0;i<a.length;i++){float v=Float.parseFloat(a[i]);if(!Float.isFinite(v)||v<0||v>(i%2==0?160:192))throw new IOException("Out of bounds "+key);dst[i]=v;}if(dst.length==4&&(dst[2]<=dst[0]||dst[3]<=dst[1]))throw new IOException("Empty bounds "+key);}catch(NumberFormatException e){throw new IOException("Invalid "+key,e);}}
 float scale(boolean asleep){return asleep?1.02f:1.56f;}
 float x(boolean asleep){return asleep?bedAnchor[0]:rug[0];}
 float y(boolean asleep,float ratioY){return (asleep?bedAnchor[1]:rug[1])-scale(asleep)*23*ratioY;}
 boolean pet(float x,float y,boolean asleep,float rx,float ry){float sz=scale(asleep);return Math.abs(x-x(asleep))<=sz*27*rx&&Math.abs(y-y(asleep,ry))<=sz*31*ry;}
 int hit(float x,float y,boolean asleep,float rx,float ry){if(pet(x,y,asleep,rx,ry))return asleep?BED:PET;int[] order={BOWL,BALL,CONSOLE,LAB,BED};for(int id:order){float[] b=bounds[id];if(x>=b[0]-2&&x<=b[2]+2&&y>=b[1]-2&&y<=b[3]+2)return id;}return NONE;}
}
