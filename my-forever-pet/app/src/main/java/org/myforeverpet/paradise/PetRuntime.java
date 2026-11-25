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
 synchronized PetState snapshot(){state.advance(System.currentTimeMillis());if(System.currentTimeMillis()-savedAt>=10000)save();PetState copy=PetState.decode(state.encode());copy.clockNow=state.clockNow;copy.nickname=prefs.getString("nickname","");return copy;}
 synchronized void rename(String name){prefs.edit().putString("nickname",name.trim()).apply();}
 synchronized boolean action(int a,int value){state.advance(System.currentTimeMillis());String before=state.encode();switch(a){case 0:state.hatch(System.currentTimeMillis());break;case 1:state.feed(value);break;case 2:state.play();break;case 3:state.clean();break;case 4:state.treat();break;case 5:state.inspectCell();break;case 6:state.changeField(value);break;case 7:state.reward(value);break;case 8:state.playdate(3,5,10,true);break;case 9:if(state.breed(3,2,1,System.currentTimeMillis()))prefs.edit().remove("nickname").apply();break;case 10:state.buy(value);break;case 11:state.useItem(value);break;case 12:state.travel();break;case 13:state.grant(value);break;case 14:state.purchaseFood(value);break;case 15:state.interact(value,System.currentTimeMillis());break;case 16:if(state.sleeping())state.wake();else state.rest(System.currentTimeMillis());break;case 17:state.expedition(value,System.currentTimeMillis());break;case 18:state.collectExpedition();break;case 19:state.daily(System.currentTimeMillis());break;case 20:state.quest(value);break;case 21:state.craft();break;case 22:state.evolveSecret();break;case 23:state.cook();break;case 24:state.bath(System.currentTimeMillis());break;case 25:state.autoSleep=!state.autoSleep;state.awakeUntil=0;break;case 26:state.buySupply(value);break;case 27:state.snack();break;case 28:state.medicate();break;case 29:state.scrub(System.currentTimeMillis());break;case 30:state.rinse();break;case 31:state.bathroom();break;case 32:state.plant(System.currentTimeMillis());break;case 33:state.harvest(System.currentTimeMillis());break;case 34:state.toy(value,System.currentTimeMillis());break;case 35:state.decorate(value);break;case 36:state.lamp(System.currentTimeMillis());break;}boolean changed=!before.equals(state.encode());if(changed)save();return changed;}
}
