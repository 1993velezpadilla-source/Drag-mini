// SPDX-License-Identifier: GPL-3.0-only
package org.myforeverpet.paradise;
import android.service.wallpaper.WallpaperService;import android.graphics.Canvas;import android.os.*;import android.view.*;
public class PetWallpaper extends WallpaperService {
 public Engine onCreateEngine(){PetRuntime.get().init(this);return new PetEngine();}
 private class PetEngine extends Engine {
  private final Handler h=new Handler(Looper.getMainLooper());private boolean visible,surface;private final PetRuntime pet=PetRuntime.get();private final Runnable draw=()->drawFrame();
  public void onCreate(SurfaceHolder holder){super.onCreate(holder);setTouchEventsEnabled(true);}
  private void drawFrame(){h.removeCallbacks(draw);if(!visible||!surface)return;Canvas c=null;try{c=getSurfaceHolder().lockCanvas();if(c!=null)PetRuntime.draw(c,pet.frame);}catch(RuntimeException ignored){}finally{if(c!=null)getSurfaceHolder().unlockCanvasAndPost(c);}h.postDelayed(draw,100);}
  public void onVisibilityChanged(boolean v){if(visible!=v){visible=v;pet.visible(v);}h.removeCallbacks(draw);if(v)drawFrame();}
  public void onSurfaceCreated(SurfaceHolder holder){super.onSurfaceCreated(holder);surface=true;drawFrame();}
  public void onSurfaceChanged(SurfaceHolder holder,int format,int width,int height){super.onSurfaceChanged(holder,format,width,height);drawFrame();}
  public void onSurfaceDestroyed(SurfaceHolder holder){surface=false;h.removeCallbacks(draw);super.onSurfaceDestroyed(holder);}
  public void onTouchEvent(MotionEvent event){if(visible&&event.getActionMasked()==MotionEvent.ACTION_UP)pet.input(1);super.onTouchEvent(event);}
  public void onDestroy(){if(visible){visible=false;pet.visible(false);}h.removeCallbacks(draw);super.onDestroy();}
 }
}
