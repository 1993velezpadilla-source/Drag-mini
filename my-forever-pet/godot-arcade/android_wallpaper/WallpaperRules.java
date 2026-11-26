package org.myforeverpet.wallpaper;

/** Pure Java rules shared by the wallpaper and its independent JVM regression gate. */
public final class WallpaperRules {
    public static final long REQUEST_LIFETIME_MS=15*60*1000L;
    private WallpaperRules(){}
    public static boolean validRequest(String request,long age,int requestGeneration,int currentGeneration){
        return ("bond".equals(request)||"feed".equals(request))
            && age>=0 && age<REQUEST_LIFETIME_MS && requestGeneration==currentGeneration && currentGeneration>0;
    }
    public static boolean sleeping(int stage,long now,long tripEnd,long sleepUntil,long awakeUntil,boolean autoSleep,int hour){
        return stage>0 && tripEnd<=now && (sleepUntil>now || (autoSleep&&awakeUntil<=now&&(hour>=21||hour<7)));
    }
    public static int projectedHunger(int hunger,int stage,double clock,long awakeSeconds){
        if(stage==0)return hunger;
        int period=stage==1?900:2700;
        return Math.max(0,Math.min(5,hunger)-(int)((Math.max(0,clock)+Math.max(0,awakeSeconds))/period));
    }
    public static int projectedWaste(int waste,double clock,long awakeSeconds){
        return Math.min(6,Math.max(0,waste)+(int)((Math.max(0,clock)+Math.max(0,awakeSeconds))/2700));
    }
    public static int projectedMood(int mood,int stage,double clock,long awakeSeconds){
        if(stage==0)return mood;
        return Math.max(0,Math.min(10,mood)-(int)((Math.max(0,clock)+Math.max(0,awakeSeconds))/(stage==1?1500:3600)));
    }
    public static float clamp(float v,float lo,float hi){return Math.max(lo,Math.min(hi,v));}
    /** Placement fits all orientations and reserves space for system dock and status text. */
    public static float[] placement(float w,float h,int stage,int x,int y,int scale){
        float u=Math.min(w,h);
        float size=u*(stage<=1?.75f:1f)*new float[]{.42f,.60f,.76f}[Math.max(0,Math.min(2,scale))];
        float cx=clamp(w*new float[]{.25f,.5f,.75f}[Math.max(0,Math.min(2,x))],size*.55f,w-size*.55f);
        float cy=clamp(h*new float[]{.26f,.47f,.68f}[Math.max(0,Math.min(2,y))],size*.56f,h-size*.60f-u*.09f);
        return new float[]{cx,cy,size,Math.min(h-u*.075f,cy+size*.55f+u*.035f)};
    }
    public static String gesture(float dx,float dy,float radius,long duration,long sinceTap){
        if(radius<=0||duration<0||duration>=650)return "";
        if(dy<-radius*.65f&&Math.abs(dx)<radius*.35f)return "feed";
        if(Math.hypot(dx,dy)<radius*.14f)return sinceTap>0&&sinceTap<350?"bond":"tap";
        return "";
    }
}
