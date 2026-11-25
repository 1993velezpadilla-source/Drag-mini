// SPDX-License-Identifier: GPL-3.0-only
package org.myforeverpet.paradise;
import android.app.*;import android.content.*;import android.graphics.*;import android.os.*;import android.view.*;import android.widget.*;
public class MainActivity extends Activity {
 private final PetRuntime pet=PetRuntime.get();private EditText key;private TextView status;private View screen;private final Handler h=new Handler(Looper.getMainLooper());private boolean active;
 private final Runnable refresh=new Runnable(){public void run(){if(!active)return;screen.invalidate();status.setText(pet.status);h.postDelayed(this,67);}};
 @Override public void onCreate(Bundle b){super.onCreate(b);pet.init(this);LinearLayout root=new LinearLayout(this);root.setOrientation(1);root.setPadding(16,16,16,16);
 status=new TextView(this);root.addView(status);screen=new View(this){protected void onDraw(Canvas c){PetRuntime.draw(c,pet.frame);}};root.addView(screen,new LinearLayout.LayoutParams(-1,0,1));
 LinearLayout controls=new LinearLayout(this);String[] labels={"A","B","C","Dial","▲","▼"};for(int i=0;i<labels.length;i++){final int code=i;Button x=new Button(this);x.setText(labels[i]);x.setMinWidth(0);x.setPadding(0,0,0,0);x.setOnClickListener(v->pet.input(code));controls.addView(x,new LinearLayout.LayoutParams(0,-2,1));}root.addView(controls);
 key=new EditText(this);key.setSingleLine(true);key.setHint("Personal device key (8 hex digits)");root.addView(key);
 Button imp=new Button(this);imp.setText("Import personal firmware");imp.setOnClickListener(v->{if(!key.getText().toString().matches("[0-9a-fA-F]{8}")){key.setError("Enter 8 hex digits");return;}Intent i=new Intent(Intent.ACTION_OPEN_DOCUMENT);i.setType("application/octet-stream");i.addCategory(Intent.CATEGORY_OPENABLE);startActivityForResult(i,10);});root.addView(imp);
 Button wall=new Button(this);wall.setText("Set live wallpaper");wall.setOnClickListener(v->{Intent i=new Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER);i.putExtra(WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,new ComponentName(this,PetWallpaper.class));try{startActivity(i);}catch(ActivityNotFoundException e){status.setText("Wallpaper picker unavailable");}});root.addView(wall);setContentView(root);}
 @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(request==10&&result==RESULT_OK&&data!=null&&data.getData()!=null)try{pet.importRom(data.getData(),Long.parseLong(key.getText().toString(),16));}catch(NumberFormatException e){key.setError("Invalid key");}}
 @Override protected void onStart(){super.onStart();active=true;pet.visible(true);h.post(refresh);}
 @Override protected void onStop(){active=false;h.removeCallbacks(refresh);pet.visible(false);super.onStop();}
}
