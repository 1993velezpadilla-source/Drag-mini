package org.myforeverpet.wallpaper;
import android.service.wallpaper.WallpaperService;
import android.content.*;
import android.graphics.*;
import android.os.*;
import android.view.*;
import android.util.AtomicFile;
import java.io.*;
import java.util.Calendar;
import org.json.JSONObject;

public final class ForeverWallpaperService extends WallpaperService {
    static final Object ACTION_LOCK=new Object();
    @Override public Engine onCreateEngine(){return new PetEngine();}
    private final class PetEngine extends Engine {
        final Handler handler=new Handler(Looper.getMainLooper());
        final Paint paint=new Paint(Paint.ANTI_ALIAS_FLAG|Paint.FILTER_BITMAP_FLAG);
        final RectF rect=new RectF();
        final Runnable frame=this::drawFrame;
        SharedPreferences prefs;
        JSONObject state=new JSONObject();
        Bitmap awake,sleep,room;
        String awakeKey="",sleepKey="",roomKey="",snapshot="";
        boolean shown,surface;
        long loaded,lastTap,reaction,downAt,projectedAt=-1;
        int hunger=5,mood=10,waste=0;
        float downX,downY,petX,petY,petRadius;
        int finger=-1;
        @Override public void onCreate(SurfaceHolder holder){
            super.onCreate(holder);prefs=getSharedPreferences("forever_wallpaper",MODE_PRIVATE);setTouchEventsEnabled(true);
        }
        @Override public void onVisibilityChanged(boolean visible){shown=visible;handler.removeCallbacks(frame);if(visible){loaded=0;projectedAt=-1;lastTap=0;finger=-1;drawFrame();}}
        @Override public void onSurfaceCreated(SurfaceHolder holder){super.onSurfaceCreated(holder);surface=true;drawFrame();}
        @Override public void onSurfaceChanged(SurfaceHolder holder,int format,int width,int height){super.onSurfaceChanged(holder,format,width,height);drawFrame();}
        @Override public void onSurfaceDestroyed(SurfaceHolder holder){surface=false;handler.removeCallbacks(frame);super.onSurfaceDestroyed(holder);}
        @Override public void onDestroy(){shown=false;surface=false;handler.removeCallbacks(frame);recycle(awake);recycle(sleep);recycle(room);super.onDestroy();}
        void recycle(Bitmap b){if(b!=null&&!b.isRecycled())b.recycle();}
        Bitmap loadImage(String key){
            if(!key.matches("(awake|sleep|room)_[0-9]{1,2}"))return null;
            try(FileInputStream in=new AtomicFile(new File(new File(getFilesDir(),"forever_wallpaper"),key+".png")).openRead()){
                return BitmapFactory.decodeStream(in);
            }catch(IOException|RuntimeException e){return null;}
        }
        void refresh(long now){
            if(prefs==null||now-loaded<1000)return;
            loaded=now;
            String next=prefs.getString("snapshot","");
            if(!next.equals(snapshot)){
                try{state=new JSONObject(next);snapshot=next;projectedAt=-1;}catch(Exception ignored){}
            }
            int species=Math.max(32,Math.min(60,state.optInt("portrait",32)));
            String a="awake_"+species,b="sleep_"+species,r="room_"+Math.max(0,Math.min(5,state.optInt("room",0)));
            if(!a.equals(awakeKey)||awake==null){Bitmap image=loadImage(a);if(image!=null){recycle(awake);awake=image;awakeKey=a;}}
            if(!b.equals(sleepKey)||sleep==null){Bitmap image=loadImage(b);if(image!=null){recycle(sleep);sleep=image;sleepKey=b;}}
            if(!r.equals(roomKey)||room==null){Bitmap image=loadImage(r);if(image!=null){recycle(room);room=image;roomKey=r;}}
            projectNeeds();
        }
        boolean asleepAt(long at,Calendar local){
            local.setTimeInMillis(at*1000L);
            return WallpaperRules.sleeping(state.optInt("stage",0),at,state.optLong("trip_end"),
                state.optLong("sleep_until"),state.optLong("awake_until"),state.optBoolean("auto_sleep",true),local.get(Calendar.HOUR_OF_DAY));
        }
        boolean asleep(){return asleepAt(System.currentTimeMillis()/1000L,Calendar.getInstance());}
        // Display-only estimate. Godot remains the sole authority for growth, economy and save.
        void projectNeeds(){
            long now=System.currentTimeMillis()/1000L;
            if(projectedAt>=0&&now>=projectedAt&&now-projectedAt<30)return;
            projectedAt=now;
            long saved=state.optLong("last",now),cursor=Math.max(saved,now-86400);
            long awakeSeconds=0;
            Calendar local=Calendar.getInstance();
            while(cursor<now){
                long next=Math.min(now,cursor+60-cursor%60);
                for(String key:new String[]{"sleep_until","awake_until","trip_end"}){
                    long boundary=state.optLong(key);if(boundary>cursor)next=Math.min(next,boundary);
                }
                if(!asleepAt(cursor,local))awakeSeconds+=next-cursor;
                cursor=next;
            }
            int stage=state.optInt("stage",0);
            hunger=WallpaperRules.projectedHunger(state.optInt("hunger",5),stage,state.optDouble("food_clock",0),awakeSeconds);
            mood=WallpaperRules.projectedMood(state.optInt("happy",10),stage,state.optDouble("mood_clock",0),awakeSeconds);
            waste=stage==0?0:WallpaperRules.projectedWaste(state.optInt("waste"),state.optDouble("waste_clock",0),awakeSeconds);
        }
        void drawFrame(){
            handler.removeCallbacks(frame);if(!shown||!surface)return;
            long now=SystemClock.elapsedRealtime();refresh(now);
            Canvas c=null;try{c=getSurfaceHolder().lockCanvas();if(c!=null)draw(c,now);}catch(RuntimeException ignored){}
            finally{if(c!=null)try{getSurfaceHolder().unlockCanvasAndPost(c);}catch(RuntimeException ignored){}}
            if(shown&&surface)handler.postDelayed(frame,state.optBoolean("battery",false)?250:asleep()?125:67);
        }
        void draw(Canvas c,long now){
            float w=c.getWidth(),h=c.getHeight(),u=Math.min(w,h);
            boolean night=asleep(),minimal=state.optBoolean("minimal",false);
            paint.setColor(Color.WHITE);paint.setAlpha(255);
            paint.setShader(new LinearGradient(0,0,0,h,new int[]{0xff17132e,0xff50346b,0xff1a263b},null,Shader.TileMode.CLAMP));
            c.drawRect(0,0,w,h,paint);paint.setShader(null);
            if(!minimal&&room!=null){
                float z=Math.max(w/room.getWidth(),h/room.getHeight()),dw=room.getWidth()*z,dh=room.getHeight()*z;
                rect.set((w-dw)/2,(h-dh)/2,(w+dw)/2,(h+dh)/2);c.drawBitmap(room,null,rect,paint);
                paint.setColor(night?0x770c1435:0x3323173a);c.drawRect(0,0,w,h,paint);
            }
            float t=(now%600000L)/1000f;
            float pulse=now-reaction<850?(float)Math.sin(Math.PI*Math.max(0,now-reaction)/850f):0;
            float[] placement=WallpaperRules.placement(w,h,state.optInt("stage",0),state.optInt("wallpaper_x",1),state.optInt("wallpaper_y",2),state.optInt("wallpaper_size",1));
            float size=placement[2];
            petX=placement[0];petY=placement[1];petRadius=size*.48f;
            float bob=(float)Math.sin(t*(night?1.4:2.5))*u*.009f-pulse*u*.045f;
            paint.setColor(0x55000000);rect.set(petX-size*.31f,petY+size*.31f,petX+size*.31f,petY+size*.39f);c.drawOval(rect,paint);
            int portrait=state.optInt("portrait",32);
            Bitmap b=night&&sleep!=null&&sleepKey.equals("sleep_"+portrait)?sleep:awakeKey.equals("awake_"+portrait)?awake:null;
            if(b!=null){paint.setColor(Color.WHITE);paint.setFilterBitmap(false);float scale=1+pulse*.06f;
                rect.set(petX-size*scale/2,petY-size*scale/2+bob,petX+size*scale/2,petY+size*scale/2+bob);c.drawBitmap(b,null,rect,paint);paint.setFilterBitmap(true);}
            else{paint.setColor(0xffe9d8b5);rect.set(petX-size*.22f,petY-size*.29f,petX+size*.22f,petY+size*.29f);c.drawOval(rect,paint);}
            if(night){paint.setColor(0xffd5c5ff);paint.setTextSize(u*.045f);c.drawText("z  z",petX+size*.28f,petY-size*.28f,paint);}
            if(pulse>0){
                paint.setColor(0xfff9a1d1);
                for(int j=0;j<5;j++){double a=j*2*Math.PI/5;float x=petX+(float)Math.cos(a)*size*(.35f+pulse*.18f),y=petY+(float)Math.sin(a)*size*.39f-pulse*u*.05f;c.drawCircle(x,y,u*.012f*(1+pulse),paint);}
            }
            if(state.optBoolean("show_status",true)){
                String msg=night?"Resting":state.optInt("germs")>0?"Needs care":state.optInt("stage",0)==0?"Ready to hatch":state.optLong("trip_end")>System.currentTimeMillis()/1000L?"Exploring":hunger<2?"Hungry":mood<4?"Wants to play":waste>0?"Time to clean":"Happy to see you";
                if(prefs!=null&&WallpaperRules.validRequest(prefs.getString("request",""),System.currentTimeMillis()-prefs.getLong("request_at",0),prefs.getInt("request_generation",-1),state.optInt("generation",1)))msg="Care queued • open game";
                paint.setTextSize(u*.032f);paint.setTextAlign(Paint.Align.CENTER);paint.setColor(0xfff3e6ff);
                paint.setShadowLayer(4,0,2,0xff120b25);float labelX=WallpaperRules.clamp(petX,w*.23f,w*.77f);
                String companionName=state.optString("name","Ponoko");
                if(companionName.trim().isEmpty()||"Mosky".equals(companionName)||"Mosskit".equals(companionName))companionName="Ponoko";
                c.drawText(companionName,labelX,placement[3],paint);
                paint.setTextSize(u*.026f);c.drawText(msg,labelX,placement[3]+u*.038f,paint);paint.clearShadowLayer();paint.setTextAlign(Paint.Align.LEFT);
            }
        }
        void queue(String request){
            if(prefs==null||isPreview()||state.optInt("stage",0)==0||state.optLong("trip_end")>System.currentTimeMillis()/1000L)return;
            if("feed".equals(request)&&hunger>=5)return;
            synchronized(ACTION_LOCK){
                long now=System.currentTimeMillis();int generation=state.optInt("generation",1);
                if(WallpaperRules.validRequest(prefs.getString("request",""),now-prefs.getLong("request_at",0),prefs.getInt("request_generation",-1),generation))return;
                prefs.edit().putString("request",request).putInt("request_generation",generation).putLong("request_at",now).commit();
            }
        }
        @Override public void onTouchEvent(MotionEvent e){
            if(!shown){super.onTouchEvent(e);return;}
            int action=e.getActionMasked();
            if(action==MotionEvent.ACTION_DOWN){finger=e.getPointerId(0);downX=e.getX();downY=e.getY();downAt=SystemClock.elapsedRealtime();}
            else if(action==MotionEvent.ACTION_CANCEL||action==MotionEvent.ACTION_POINTER_DOWN){finger=-1;}
            else if(action==MotionEvent.ACTION_UP&&finger==e.getPointerId(0)){
                long now=SystemClock.elapsedRealtime();float dx=e.getX()-downX,dy=e.getY()-downY;
                boolean hit=Math.hypot(downX-petX,downY-petY)<petRadius;
                if(hit&&!asleep()){
                    String gesture=WallpaperRules.gesture(dx,dy,petRadius,now-downAt,lastTap>0?now-lastTap:0);
                    if("feed".equals(gesture)||"bond".equals(gesture)){queue(gesture);reaction=now;lastTap=0;}
                    else if("tap".equals(gesture)){reaction=now;lastTap=now;}
                }
                finger=-1;
            }
            super.onTouchEvent(e);
        }
    }
}
