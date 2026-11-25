package org.myforeverpet.paradise;
import android.content.*;import android.graphics.*;
/** Single synchronized state, same process for Activity and WallpaperService. */
final class PetRuntime {
 private static final PetRuntime INSTANCE=new PetRuntime();
 static PetRuntime get(){return INSTANCE;}
 private android.content.SharedPreferences prefs;private PetState state;
 private long savedAt;
 synchronized void init(Context c){if(state==null){prefs=c.getApplicationContext().getSharedPreferences("standalone_v2",0);state=PetState.decode(prefs.getString("state",null));state.advance(System.currentTimeMillis());save();}}
 private void save(){prefs.edit().putString("state",state.encode()).apply();savedAt=System.currentTimeMillis();}
 synchronized void flush(){if(state!=null){state.advance(System.currentTimeMillis());save();}}
 synchronized PetState snapshot(){state.advance(System.currentTimeMillis());if(System.currentTimeMillis()-savedAt>=10000)save();return PetState.decode(state.encode());}
 synchronized void action(int a,int value){state.advance(System.currentTimeMillis());switch(a){case 0:state.hatch(System.currentTimeMillis());break;case 1:state.feed(value);break;case 2:state.play();break;case 3:state.clean();break;case 4:state.treat();break;case 5:state.inspectCell();break;case 6:state.changeField(value);break;case 7:state.reward(value);break;}save();}
}
