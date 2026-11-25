package org.myforeverpet.paradise;
public class PetStateTest {
 static void eq(boolean ok,String m){if(!ok)throw new AssertionError(m);}
 public static void main(String[] args){
  long t=1000000;PetState s=new PetState();eq(s.stage==0,"egg");s.changeField(1);s.hatch(t);s.advance(t+PetState.HOUR);eq(s.cells[1]==4,"field cells");eq(s.hunger==1,"baby hunger");eq(s.happy==8,"baby happiness");eq(s.inspectCell()&&s.stage==2,"kid");
  for(int i=0;i<4;i++)s.feed(2);eq(s.hunger==5,"feeding");s.clean();eq(s.waste==0,"clean");
  s.advance(t+25*PetState.HOUR);eq(s.stage==3&&s.body==2,"young food branch");s.advance(t+49*PetState.HOUR);eq(s.stage==4,"adult");eq(s.sick,"illness");int misses=s.mistakes;s.treat();eq(s.sick&&s.germs==2,"one germ treated");s.treat();s.treat();eq(!s.sick&&s.mistakes==misses,"treat preserves care history");s.reward(5);eq(s.coins==25,"minigame reward");
  eq(PetState.decode(s.encode()).encode().equals(s.encode()),"save round trip");String before=s.encode();s.advance(t+48*PetState.HOUR);eq(before.equals(s.encode()),"backwards clock");
  PetState p=new PetState();p.hatch(t);p.advance(t+30*PetState.MIN);p.changeField(2);p.advance(t+60*PetState.MIN);eq(!p.inspectCell(),"matching field requirement");p.advance(t+90*PetState.MIN);eq(p.inspectCell(),"second field completed");
  eq(PlaydateRules.base(2,3)==3,"rank difference");eq(PlaydateRules.base(5,0)==4,"secret priority");eq(PlaydateRules.fight(2,9,5,5),"fight mixed conditions");eq(!PlaydateRules.fight(2,9,5,10),"no fight if one side well");eq(!PlaydateRules.canBreed(false,true,4,false,false),"adult gate");eq(!PlaydateRules.canBreed(true,true,4,true,false),"unbreedable gate");
  eq(!s.breed(3,2,1,t+49*PetState.HOUR),"friendship gate");s.playdate(3,5,10,true);s.playdate(3,5,10,true);eq(s.friendship==4,"friendship cap");eq(s.breed(3,2,1,t+49*PetState.HOUR)&&s.stage==0&&s.generation==2&&s.inheritedEyes==2&&s.coins==25,"offspring state and retained coins");eq(PetState.decode(s.encode()).generation==2,"generation persistence");s.hatch(t+49*PetState.HOUR);s.advance(t+50*PetState.HOUR);s.inspectCell();s.advance(t+98*PetState.HOUR);eq(s.eyes==2,"inherited eyes");
  s.coins=200;eq(s.buy(0)&&s.coins==160,"shop debit");eq(!s.buy(0)&&s.coins==160,"no duplicate debit");eq(s.useItem(0)&&s.equipped==1,"equip");eq(PetState.decode(s.encode()).equipped==1,"inventory persistence");s.waste=4;s.clean();eq(s.fuel>=4&&s.travel(),"recycle and travel");eq(s.species()>=0&&s.species()<12,"species bounds");
  System.out.println("PASS: egg, cell growth, food, cleaning, adulthood, illness, rewards, save, clock, field matching");
 }
}
