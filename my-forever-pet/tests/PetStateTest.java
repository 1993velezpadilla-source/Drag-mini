package org.myforeverpet.paradise;
public class PetStateTest {
 static void eq(boolean ok,String m){if(!ok)throw new AssertionError(m);}
 public static void main(String[] args){
  long t=1000000;PetState s=new PetState();eq(s.stage==0,"egg");s.changeField(1);s.hatch(t);s.advance(t+PetState.HOUR);eq(s.cells[1]==4,"field cells");eq(s.hunger==1,"baby hunger");eq(s.happy==8,"baby happiness");eq(s.inspectCell()&&s.stage==2,"kid");
  for(int i=0;i<4;i++)s.feed(2);eq(s.hunger==5,"feeding");s.clean();eq(s.waste==0,"clean");
  s.advance(t+25*PetState.HOUR);eq(s.stage==3&&s.body==2,"young food branch");s.advance(t+49*PetState.HOUR);eq(s.stage==4,"adult");eq(s.sick,"illness");s.treat();eq(!s.sick,"treat");s.reward(5);eq(s.coins==25,"minigame reward");
  eq(PetState.decode(s.encode()).encode().equals(s.encode()),"save round trip");String before=s.encode();s.advance(t+48*PetState.HOUR);eq(before.equals(s.encode()),"backwards clock");
  PetState p=new PetState();p.hatch(t);p.advance(t+30*PetState.MIN);p.changeField(2);p.advance(t+60*PetState.MIN);eq(!p.inspectCell(),"matching field requirement");p.advance(t+90*PetState.MIN);eq(p.inspectCell(),"second field completed");
  System.out.println("PASS: egg, cell growth, food, cleaning, adulthood, illness, rewards, save, clock, field matching");
 }
}
