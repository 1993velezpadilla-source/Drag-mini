package org.myforeverpet.paradise;
public final class Economy {
 private Economy(){}
 public static int reward(int mode,int score,int ticks){if(ticks<60||score<=0)return 0;int factor=mode==Arcade.STAR?2:mode==Arcade.FLY?6:4;return Math.min(100,Math.min(100,score)*factor);}
 public static int foodPrice(int food){return food==3?0:food==0?4:food==1?2:3;}
}
