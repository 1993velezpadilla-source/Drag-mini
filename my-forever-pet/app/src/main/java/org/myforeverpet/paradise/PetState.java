package org.myforeverpet.paradise;
import java.util.Arrays;
/** Standalone simulation. Exact known timing separated from provisional tuning. */
public final class PetState {
 public static final long MIN=60000L,HOUR=60*MIN;
 public static final int EGG=0,BABY=1,KID=2,YOUNG=3,ADULT=4;
 public int stage=EGG,field=0,hunger=5,happy=10,waste=0,mistakes=0,coins=0,body=0,eyes=0,color=0;
 public int[] cells=new int[3],foods=new int[4];
 public boolean sick=false;
 public int generation=1,friendship=0,inheritedEyes=-1;
 public int owned=0,equipped=0,installation=0,fuel=0,collection=0,germs=0;
 public int energy=100,bond=0,xp=0,crystals=0,materials=0,variant=0,training=0,quests=0,claimedQuests=0,journeys=0,pendingCoins=0,pendingMaterials=0,pendingCrystals=0,destination=0;
 public long sleepUntil=0,energyClock=0,interactionAt=0,expeditionEnd=0,dailyDay=-1;
 public int level(){return 1+xp/100;}
 public boolean sleeping(){return sleepUntil>last;}
 public boolean exploring(){return expeditionEnd>last;}
 private void earn(int n){xp=Math.min(999900,xp+Math.max(0,n));}
 public boolean interact(int kind,long now){if(stage==EGG||sleeping()||exploring()||now-interactionAt<1500)return false;interactionAt=now;bond=Math.min(100,bond+1);if(kind==2){training=Math.min(100,training+1);earn(4);}else{play();earn(2);}quests|=1;return true;}
 public boolean rest(long now){if(stage==EGG||exploring()||sleeping()||energy>=100)return false;sleepUntil=now+30*MIN;return true;}
 public boolean wake(){if(!sleeping())return false;sleepUntil=0;return true;}
 public boolean expedition(int region,long now){if(stage<KID||sick||hunger<2||energy<25||sleeping()||expeditionEnd!=0||pendingCoins>0||region<0||region>2||level()<1+region*2)return false;if(region>0&&fuel<region)return false;fuel-=region;energy-=25;destination=region;expeditionEnd=now+(10+region*10)*MIN;return true;}
 public boolean collectExpedition(){if(pendingCoins==0)return false;coins=Math.min(999999,coins+pendingCoins);materials=Math.min(9999,materials+pendingMaterials);crystals=Math.min(9999,crystals+pendingCrystals);pendingCoins=pendingMaterials=pendingCrystals=0;return true;}
 public boolean daily(long now){long day=Math.floorDiv(now,24*HOUR);if(stage==EGG||day<=dailyDay)return false;dailyDay=day;coins=Math.min(999999,coins+20);materials=Math.min(9999,materials+1);return true;}
 public boolean quest(int id){if(id<0||id>2||(quests&(1<<id))==0||(claimedQuests&(1<<id))!=0)return false;claimedQuests|=1<<id;coins=Math.min(999999,coins+15);earn(10);return true;}
 public boolean craft(){if(stage==EGG||materials<3)return false;materials-=3;crystals=Math.min(9999,crystals+1);return true;}
 public boolean evolveSecret(){if(stage!=ADULT||variant!=0||bond<30||training<10||crystals<3)return false;crystals-=3;variant=1;collection|=1<<species();return true;}
 public long age=0,last=0,hungerClock=0,happyClock=0,wasteClock=0,careClock=0,cellClock=0;
 public static int clamp(int x,int a,int b){return Math.max(a,Math.min(b,x));}
 public void hatch(long now){if(stage!=EGG)return;stage=BABY;last=now;age=0;}
 public void advance(long now){
  if(last==0){last=now;return;} if(now<=last)return;
  long previous=last;long left=now-last;last=now;
  if(stage==EGG)return;
  long elapsed=Math.min(left,30L*24*HOUR);long rested=Math.min(elapsed,Math.max(0,Math.min(now,sleepUntil)-previous));energyClock+=elapsed-rested;
  energy=clamp(energy-(int)(energyClock/(15*MIN)),0,100);energyClock%=15*MIN;
  if(sleepUntil>0&&now>=sleepUntil){energy=Math.min(100,energy+90);sleepUntil=0;}
  if(expeditionEnd>0&&now>=expeditionEnd){pendingCoins=25+destination*20+Math.min(20,training/2);pendingMaterials=2+destination;pendingCrystals=(journeys%3==2||destination==2)?1:0;expeditionEnd=0;journeys=Math.min(999999,journeys+1);earn(35+destination*15);quests|=4;}
  // Bounded per minute simulation; longer absence does not overflow timers.
  left=Math.min(left,30L*24*HOUR);
  while(left>0){
   int oldWaste=waste,oldMistakes=mistakes;long dt=Math.min(left,MIN);left-=dt;age+=dt;
   hungerClock+=dt;happyClock+=dt;wasteClock+=dt;
   long ht=stage==BABY?15*MIN:90*MIN, ha=stage==BABY?25*MIN:120*MIN;
   while(hungerClock>=ht){hungerClock-=ht;hunger=Math.max(0,hunger-1);}
   while(happyClock>=ha){happyClock-=ha;happy=Math.max(0,happy-1);}
   while(wasteClock>=45*MIN){wasteClock-=45*MIN;waste=Math.min(6,waste+1);}
   if(stage==BABY){cellClock+=dt;while(cellClock>=15*MIN){cellClock-=15*MIN;cells[field]=Math.min(4,cells[field]+1);}}
   if(stage>=KID&&(hunger==0||happy==0)){careClock+=dt;while(careClock>=15*MIN){careClock-=15*MIN;mistakes=Math.min(6,mistakes+1);}}
   else careClock=0;
   if(!sick&&((oldWaste<6&&waste>=6)||(oldMistakes<3&&mistakes>=3))&&germs==0){sick=true;germs=3;}
   if(stage==KID&&age>=24*HOUR){stage=YOUNG;age-=24*HOUR;body=dominantFood();}
   else if(stage==YOUNG&&age>=24*HOUR){stage=ADULT;age-=24*HOUR;eyes=inheritedEyes>=0?inheritedEyes:Math.min(3,mistakes/2);collection|=1<<species();}
  }
 }
 private int dominantFood(){int best=0;for(int i=1;i<foods.length;i++)if(foods[i]>foods[best])best=i;return best;}
 public boolean inspectCell(){if(stage==BABY&&cells[field]>=4){stage=KID;age=0;body=field;return true;}return false;}
 public void feed(int food){if(stage==EGG)return;food=clamp(food,0,3);hunger=clamp(hunger+1,0,5);foods[food]++;if(hunger>0&&happy>0)careClock=0;}
 public void play(){if(stage!=EGG){happy=clamp(happy+2,0,10);if(hunger>0&&happy>0)careClock=0;}}
 public void clean(){if(stage!=EGG&&waste>0){coins=Math.min(999999,coins+waste*2);fuel=Math.min(9999,fuel+waste);waste=0;wasteClock=0;quests|=2;}}
 public void treat(){if(stage!=EGG&&sick){if(germs>0)germs--;if(germs==0){sick=false;}}}
 public int species(){return field*4+body+12*variant;}
 public static final String[] SPECIES={"Mosskit","Bunberry","Dewfox","Pebblepup","Bubblefin","Coralhop","Moonray","Shellotter","Starbat","Cloudhare","Cometbird","Puffowl","Fernhorn","Roseling","Emberfox","Cloverpup","Pearlfin","Reefling","Lunamanta","Riverotter","NovaBat","Aurorahare","Sunphoenix","Dreamowl"};
 public String creature(){return stage<2?stageName():SPECIES[species()];}
 public static final String[] ITEMS={"Star cap","Berry ribbon","Moon halo","Garden bath","Cloud bed","Flower stand"};
 public static final int[] PRICES={40,50,75,80,100,60};
 public boolean buy(int i){if(i<0||i>=ITEMS.length||(owned&(1<<i))!=0||coins<PRICES[i])return false;coins-=PRICES[i];owned|=1<<i;return true;}
 public boolean useItem(int i){if(i<0||i>=ITEMS.length||(owned&(1<<i))==0)return false;if(i<3)equipped=equipped==i+1?0:i+1;else{installation=i+1;play();}return true;}
 public boolean travel(){if(fuel<4)return false;fuel-=4;coins=Math.min(999999,coins+10);return true;}
 public long nextCell(){return stage==BABY&&cells[field]<4?Math.max(1,(15*MIN-cellClock+999)/1000):0;}
 public void changeField(int f){if(stage==EGG||stage==BABY)field=clamp(f,0,2);}
 public void reward(int hits){grant((int)Math.min(100,Math.max(0L,(long)hits)*5));}
 public void grant(int amount){if(stage!=EGG&&amount>0){coins=Math.min(999999,coins+Math.min(100,amount));play();}}
 public boolean purchaseFood(int food){if(stage==EGG||food<0||food>3||hunger>=5||coins<Economy.foodPrice(food))return false;coins-=Economy.foodPrice(food);feed(food);return true;}
 /** Rank-based playdate rules from GMMan; local partner is a prototype feature. */
 public int rank(){return stage<ADULT?0:Math.max(1,4-Math.min(3,mistakes));}
 public int playdate(int partnerRank,int partnerHunger,int partnerHappy,boolean partnerLove){
  if(stage==EGG)return -1;
  if(friendship==0)friendship=PlaydateRules.base(rank(),partnerRank);
  if(PlaydateRules.fight(hunger,happy,partnerHunger,partnerHappy))return 0;
  friendship=PlaydateRules.after(friendship,happy==10,partnerLove);
  return friendship;
 }
 public boolean breed(int partnerRank,int partnerEyes,int partnerColor,long now){
  if(sleeping()||exploring()||pendingCoins>0||!PlaydateRules.canBreed(stage==ADULT,partnerRank>0,friendship,false,false))return false;
  generation++;variant=0;bond=0;training=0;energy=100;xp=0;energyClock=0;sleepUntil=0;interactionAt=0;expeditionEnd=0;inheritedEyes=clamp(partnerEyes,0,3);eyes=inheritedEyes;color=clamp(partnerColor,0,15);
  stage=EGG;age=0;last=now;hunger=5;happy=10;waste=mistakes=friendship=0;sick=false;germs=0;
  hungerClock=happyClock=wasteClock=careClock=cellClock=0;Arrays.fill(cells,0);Arrays.fill(foods,0);return true;
 }
 public String stageName(){return new String[]{"Egg","Baby","Kid","Young","Adult"}[stage];}
 public String fieldName(){return new String[]{"Land","Water","Sky"}[field];}
 public String encode(){return stage+","+field+","+hunger+","+happy+","+waste+","+mistakes+","+coins+","+body+","+eyes+","+color+","+(sick?1:0)+","+age+","+last+","+hungerClock+","+happyClock+","+wasteClock+","+careClock+","+cellClock+","+cells[0]+","+cells[1]+","+cells[2]+","+foods[0]+","+foods[1]+","+foods[2]+","+foods[3]+","+generation+","+friendship+","+inheritedEyes+","+owned+","+equipped+","+installation+","+fuel+","+collection+","+germs+","+energy+","+bond+","+xp+","+crystals+","+materials+","+variant+","+training+","+quests+","+claimedQuests+","+journeys+","+pendingCoins+","+pendingMaterials+","+pendingCrystals+","+sleepUntil+","+energyClock+","+interactionAt+","+expeditionEnd+","+dailyDay+","+destination;}
 public static PetState decode(String raw){PetState s=new PetState();if(raw==null)return s;try{String[] v=raw.split(",");if(v.length!=25&&v.length!=28&&v.length!=34&&v.length!=53)return s;long[] a=new long[v.length];for(int i=0;i<a.length;i++)a[i]=Long.parseLong(v[i]);s.stage=clamp((int)a[0],0,4);s.field=clamp((int)a[1],0,2);s.hunger=clamp((int)a[2],0,5);s.happy=clamp((int)a[3],0,10);s.waste=clamp((int)a[4],0,6);s.mistakes=clamp((int)a[5],0,6);s.coins=Math.max(0,(int)a[6]);s.body=clamp((int)a[7],0,3);s.eyes=clamp((int)a[8],0,3);s.color=clamp((int)a[9],0,15);s.sick=a[10]!=0;s.age=Math.max(0,a[11]);s.last=Math.max(0,a[12]);s.hungerClock=Math.max(0,a[13]);s.happyClock=Math.max(0,a[14]);s.wasteClock=Math.max(0,a[15]);s.careClock=Math.max(0,a[16]);s.cellClock=Math.max(0,a[17]);for(int i=0;i<3;i++)s.cells[i]=clamp((int)a[18+i],0,4);for(int i=0;i<4;i++)s.foods[i]=Math.max(0,(int)a[21+i]);if(a.length>=28){s.generation=Math.max(1,(int)a[25]);s.friendship=clamp((int)a[26],0,4);s.inheritedEyes=clamp((int)a[27],-1,3);}if(a.length>=34){s.owned=clamp((int)a[28],0,63);s.equipped=clamp((int)a[29],0,3);s.installation=clamp((int)a[30],0,6);s.fuel=clamp((int)a[31],0,9999);s.collection=clamp((int)a[32],0,16777215);s.germs=clamp((int)a[33],0,3);}else if(s.sick)s.germs=3;if(a.length==53){s.energy=clamp((int)a[34],0,100);s.bond=clamp((int)a[35],0,100);s.xp=clamp((int)a[36],0,999900);s.crystals=clamp((int)a[37],0,9999);s.materials=clamp((int)a[38],0,9999);s.variant=clamp((int)a[39],0,1);s.training=clamp((int)a[40],0,100);s.quests=clamp((int)a[41],0,7);s.claimedQuests=clamp((int)a[42],0,7);s.journeys=clamp((int)a[43],0,999999);s.pendingCoins=clamp((int)a[44],0,100);s.pendingMaterials=clamp((int)a[45],0,10);s.pendingCrystals=clamp((int)a[46],0,1);s.sleepUntil=Math.max(0,a[47]);s.energyClock=clamp((int)a[48],0,(int)(15*MIN));s.interactionAt=Math.max(0,a[49]);s.expeditionEnd=Math.max(0,a[50]);s.dailyDay=a[51];s.destination=clamp((int)a[52],0,2);}if(s.stage==ADULT)s.collection|=1<<s.species();return s;}catch(RuntimeException e){return new PetState();}}
}
