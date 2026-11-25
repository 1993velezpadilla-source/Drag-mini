package org.myforeverpet.paradise;
import android.app.*;import android.content.*;import android.graphics.*;import android.os.*;import android.view.*;import android.widget.*;
public class MainActivity extends Activity{
 private final PetRuntime pet=PetRuntime.get();private final PetArt art=new PetArt();private final Handler h=new Handler(Looper.getMainLooper());
 private int zoom=2,hits=0,remaining=0;private boolean playing=false,active=false;private long gameEnd;private float targetX=.5f,targetY=.5f;
 private TextView status,caption;private LinearLayout actions;private View scene;
 private final Runnable refresh=new Runnable(){public void run(){if(!active)return;if(playing&&SystemClock.elapsedRealtime()>=gameEnd)finishGame();update();h.postDelayed(this,100);}};
 private int dp(float x){return (int)(x*getResources().getDisplayMetrics().density+.5f);}
 @Override public void onCreate(Bundle b){super.onCreate(b);pet.init(this);getWindow().setStatusBarColor(0xff17243c);getWindow().setNavigationBarColor(0xff17243c);
 LinearLayout root=new LinearLayout(this);root.setOrientation(1);root.setPadding(dp(12),dp(8),dp(12),dp(8));root.setBackgroundColor(0xfff1f5f5);
 TextView title=new TextView(this);title.setText("MY FOREVER PET");title.setTextSize(22);title.setTextColor(0xff253851);title.setGravity(17);root.addView(title);
 status=new TextView(this);status.setTextColor(0xff253851);status.setGravity(17);root.addView(status);
 scene=new View(this){Paint p=new Paint(3);protected void onDraw(Canvas c){if(playing){c.drawColor(0xffd9f3ef);p.setColor(0xffeab75b);c.drawCircle(targetX*getWidth(),targetY*getHeight(),dp(25),p);p.setColor(0xff34475e);p.setTextSize(dp(19));p.setTextAlign(Paint.Align.CENTER);c.drawText("Tap the star  •  "+hits+" hits",getWidth()/2f,dp(30),p);}else art.draw(c,pet.snapshot(),zoom,false,SystemClock.elapsedRealtime());}
 @Override public boolean onTouchEvent(android.view.MotionEvent e){if(e.getActionMasked()==MotionEvent.ACTION_DOWN){if(playing){float dx=e.getX()-targetX*getWidth(),dy=e.getY()-targetY*getHeight();if(dx*dx+dy*dy<dp(32)*dp(32)){hits++;targetX=.15f+(float)Math.random()*.7f;targetY=.2f+(float)Math.random()*.65f;invalidate();}}else if(pet.snapshot().stage==0){pet.action(0,0);rebuild();}else if(zoom==3){pet.action(5,0);update();}return true;}return true;}};
 root.addView(scene,new LinearLayout.LayoutParams(-1,0,1));
 caption=new TextView(this);caption.setGravity(17);caption.setTextColor(0xff56657b);root.addView(caption);
 LinearLayout zooms=new LinearLayout(this);String[] names={"Space","Field","Pet","Cell"};for(int i=0;i<4;i++){final int z=i;button(zooms,names[i],()->{if(playing)finishGame();zoom=z;rebuild();});}root.addView(zooms);
 actions=new LinearLayout(this);actions.setOrientation(1);root.addView(actions);
 LinearLayout footer=new LinearLayout(this);button(footer,"Live wallpaper",()->{Intent i=new Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER);i.putExtra(WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,new ComponentName(this,PetWallpaper.class));try{startActivity(i);}catch(ActivityNotFoundException e){Toast.makeText(this,"Wallpaper picker unavailable",0).show();}});root.addView(footer);setContentView(root);rebuild();}
 private void button(LinearLayout row,String label,Runnable run){Button b=new Button(this);b.setAllCaps(false);b.setText(label);b.setTextSize(12);b.setMinWidth(0);b.setPadding(dp(3),0,dp(3),0);b.setOnClickListener(v->run.run());row.addView(b,new LinearLayout.LayoutParams(0,dp(48),1));}
 private void act(int a,int v){pet.action(a,v);update();}
 private void rebuild(){actions.removeAllViews();LinearLayout r=new LinearLayout(this);actions.addView(r);PetState s=pet.snapshot();if(playing){button(r,"Finish",()->finishGame());}
 else if(s.stage==0){button(r,"Hatch egg",()->{pet.action(0,0);rebuild();});button(r,"Land",()->act(6,0));button(r,"Water",()->act(6,1));button(r,"Sky",()->act(6,2));}
 else if(zoom==0){button(r,"Visit field",()->{zoom=1;rebuild();});}
 else if(zoom==1){button(r,"Clean field",()->act(3,0));button(r,"Land",()->act(6,0));button(r,"Water",()->act(6,1));button(r,"Sky",()->act(6,2));}
 else if(zoom==2){button(r,"Feed",()->new AlertDialog.Builder(this).setTitle("Choose food").setItems(new String[]{"Meat","Carrot","Fish","Grain"},(d,i)->act(1,i)).show());button(r,"Play",()->act(2,0));button(r,"Mini game",()->{hits=0;playing=true;gameEnd=SystemClock.elapsedRealtime()+15000;rebuild();});}
 else {button(r,"Inspect cells",()->{act(5,0);rebuild();});button(r,"Treat",()->act(4,0));}update();}
 private void finishGame(){if(!playing)return;playing=false;pet.action(7,hits);rebuild();}
 private void update(){PetState s=pet.snapshot();status.setText(s.stageName()+"  •  "+s.fieldName()+"  •  "+s.coins+" coins\nFood "+s.hunger+"/5     Happy "+s.happy+"/10     Care "+s.mistakes);caption.setText(playing?"Time: "+Math.max(0,(gameEnd-SystemClock.elapsedRealtime()+999)/1000)+"s":s.stage==0?"Tap your egg to begin":zoom==3?"Inspect cells to trigger growth":s.sick?"Your pet needs treatment in Cell":"Your pet lives even while the app is closed");scene.invalidate();}
 @Override protected void onStart(){super.onStart();active=true;h.post(refresh);}
 @Override protected void onStop(){active=false;h.removeCallbacks(refresh);if(playing)finishGame();pet.flush();super.onStop();}
}
