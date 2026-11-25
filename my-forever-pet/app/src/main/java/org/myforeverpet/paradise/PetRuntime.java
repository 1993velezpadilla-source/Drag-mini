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
 synchronized void action(int a,int value){state.advance(System.currentTimeMillis());switch(a){case 0:state.hatch(System.currentTimeMillis());break;case 1:state.feed(value);break;case 2:state.play();break;case 3:state.clean();break;case 4:state.treat();break;case 5:state.inspectCell();break;case 6:state.changeField(value);break;case 7:state.reward(value);break;case 8:state.playdate(3,5,10,true);break;case 9:state.breed(3,2,1,System.currentTimeMillis());break;case 10:state.buy(value);break;case 11:state.useItem(value);break;case 12:state.travel();break;case 13:state.grant(value);break;case 14:state.purchaseFood(value);break;case 15:state.interact(value,System.currentTimeMillis());break;case 16:if(state.sleeping())state.wake();else state.rest(System.currentTimeMillis());break;case 17:state.expedition(value,System.currentTimeMillis());break;case 18:state.collectExpedition();break;case 19:state.daily(System.currentTimeMillis());break;case 20:state.quest(value);break;case 21:state.craft();break;case 22:state.evolveSecret();break;}save();}
}
