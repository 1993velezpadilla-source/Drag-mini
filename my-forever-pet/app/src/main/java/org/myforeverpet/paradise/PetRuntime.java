// SPDX-License-Identifier: GPL-3.0-only
package org.myforeverpet.paradise;
import android.content.*;import android.graphics.*;import android.os.*;import android.net.Uri;
import java.io.*;import java.security.*;import java.util.concurrent.*;
final class PetRuntime {
 static { System.loadLibrary("forever_pet"); }
 static native String nativeOpen(String path,String save,long key);
 static native String nativeClose();
 static native void nativeInput(int code);
 static native int[] nativeTick(int elapsedMs);
 private static final PetRuntime INSTANCE=new PetRuntime();
 static PetRuntime get(){return INSTANCE;}
 private final ScheduledExecutorService worker=Executors.newSingleThreadScheduledExecutor();
 private final Handler main=new Handler(Looper.getMainLooper());
 private Context ctx;private int viewers;private boolean opened;private long last;
 volatile Bitmap frame;volatile String status="Import your own firmware and device key";
 private PetRuntime(){worker.scheduleWithFixedDelay(this::tick,0,16,TimeUnit.MILLISECONDS);}
 void init(Context c){ctx=c.getApplicationContext();}
 void visible(boolean on){worker.execute(()->{viewers=Math.max(0,viewers+(on?1:-1));if(viewers>0&&!opened)restore();if(viewers==0&&opened){String error=nativeClose();if(error.isEmpty()){opened=false;last=0;}else status=error;}});}
 private android.content.SharedPreferences prefs(){return ctx.getSharedPreferences("pet",0);}
 private void restore(){if(ctx==null)return;String p=prefs().getString("rom",null);if(p==null)return;open(p,prefs().getString("save",""),prefs().getLong("key",0));}
 private void open(String rom,String save,long key){String error=nativeOpen(rom,save,key);if(error.isEmpty()){opened=true;last=0;frame=null;status="Firmware running";}else status=error;}
 void importRom(Uri uri,long key){worker.execute(()->{
  File tmp=new File(ctx.getFilesDir(),"incoming.tmp");
  try(InputStream in=ctx.getContentResolver().openInputStream(uri);OutputStream out=new FileOutputStream(tmp)){
   if(in==null)throw new IOException("Cannot open dump");MessageDigest digest=MessageDigest.getInstance("SHA-256");byte[] buf=new byte[65536];long len=0;int n;
   while((n=in.read(buf))!=-1){len+=n;if(len>16777216)throw new IOException("Dump too large");digest.update(buf,0,n);out.write(buf,0,n);}
   if(len!=16777216)throw new IOException("Expected 16 MiB");StringBuilder hash=new StringBuilder();for(byte b:digest.digest())hash.append(String.format(java.util.Locale.ROOT,"%02x",b&255));
   String name="device";try(android.database.Cursor c=ctx.getContentResolver().query(uri,null,null,null,null)){if(c!=null&&c.moveToFirst()){int col=c.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME);if(col>=0)name=c.getString(col).replaceAll("[^A-Za-z0-9._-]","_");}}
   File rom=new File(ctx.getFilesDir(),hash+"-"+name);if(!rom.exists()&&!tmp.renameTo(rom))throw new IOException("Cannot store dump");
   File save=new File(ctx.getFilesDir(),hash+".tamasave");
   open(rom.getPath(),save.getPath(),key);if(status.equals("Firmware running"))prefs().edit().putString("rom",rom.getPath()).putString("save",save.getPath()).putLong("key",key).commit();
  }catch(Exception e){status=e.toString();}finally{tmp.delete();}
 });}
 void input(int n){worker.execute(()->{if(opened&&viewers>0)nativeInput(n);});}
 private void tick(){try{if(!opened||viewers==0)return;long now=SystemClock.elapsedRealtime();int dt=last==0?16:(int)Math.min(250,now-last);last=now;int[] p=nativeTick(dt);if(p!=null&&p.length==16384)frame=Bitmap.createBitmap(p,128,128,Bitmap.Config.ARGB_8888);}catch(Exception e){status=e.toString();}}
 static void draw(Canvas c,Bitmap b){c.drawColor(0xff111827);if(b==null)return;float size=Math.min(c.getWidth(),c.getHeight());RectF dst=new RectF((c.getWidth()-size)/2,(c.getHeight()-size)/2,(c.getWidth()+size)/2,(c.getHeight()+size)/2);Paint p=new Paint();p.setFilterBitmap(false);c.drawBitmap(b,null,dst,p);}
}
