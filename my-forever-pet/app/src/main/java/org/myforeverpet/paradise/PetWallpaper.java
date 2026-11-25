package org.myforeverpet.paradise;
import android.service.wallpaper.WallpaperService;import android.graphics.Canvas;import android.os.*;import android.view.*;
public class PetWallpaper extends WallpaperService{
 public Engine onCreateEngine(){PetRuntime.get().init(this);return new Live();}
 private final class Live extends Engine{
  private final Handler h=new Handler(Looper.getMainLooper());private final PetRuntime pet=PetRuntime.get();private final PetArt art=new PetArt();private boolean visible,surface;private long tapAt,cachedAt,clockMinute=Long.MIN_VALUE;private String clockZone="";private PetState cached;private final Runnable draw=()->render();
  public void onCreate(SurfaceHolder holder){super.onCreate(holder);setTouchEventsEnabled(true);}
  private void render(){h.removeCallbacks(draw);if(!visible||!surface)return;Canvas c=null;try{c=getSurfaceHolder().lockCanvas();if(c!=null){long n=SystemClock.elapsedRealtime();if(cached==null||n-cachedAt>=1000){cached=pet.snapshot();cachedAt=n;}long now=System.currentTimeMillis();java.util.TimeZone zone=java.util.TimeZone.getDefault();String key=zone.getID()+":"+zone.getOffset(now)+":"+android.text.format.DateFormat.is24HourFormat(PetWallpaper.this);if(clockMinute!=now/60000||!key.equals(clockZone)){clockMinute=now/60000;clockZone=key;java.text.DateFormat fmt=android.text.format.DateFormat.getTimeFormat(PetWallpaper.this);fmt.setTimeZone(zone);art.setWallClock(fmt.format(new java.util.Date(now)));}art.drawHome(c,cached,n,true);}}catch(RuntimeException ignored){}finally{if(c!=null)try{getSurfaceHolder().unlockCanvasAndPost(c);}catch(RuntimeException ignored){}}h.postDelayed(draw,cached!=null&&cached.sleeping()?250:100);}
  public void onVisibilityChanged(boolean v){visible=v;cached=null;tapAt=0;h.removeCallbacks(draw);if(v)render();else pet.flush();}
  public void onSurfaceCreated(SurfaceHolder s){super.onSurfaceCreated(s);surface=true;render();}
  public void onSurfaceChanged(SurfaceHolder s,int f,int w,int h){super.onSurfaceChanged(s,f,w,h);render();}
  public void onSurfaceDestroyed(SurfaceHolder s){surface=false;h.removeCallbacks(draw);pet.flush();super.onSurfaceDestroyed(s);}
  public void onTouchEvent(MotionEvent e){if(visible&&e.getActionMasked()==MotionEvent.ACTION_UP){long n=SystemClock.elapsedRealtime();if(n-tapAt<350&&tapAt>0){if(pet.snapshot().stage==0)pet.action(0,0);else pet.action(15,0);cached=null;tapAt=0;render();}else tapAt=n;}super.onTouchEvent(e);}
  public void onDestroy(){visible=false;h.removeCallbacks(draw);pet.flush();super.onDestroy();}
 }
}
