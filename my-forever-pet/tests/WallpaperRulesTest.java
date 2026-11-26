package org.myforeverpet.wallpaper;
public final class WallpaperRulesTest {
    static int count;
    static void check(boolean b,String name){if(!b)throw new AssertionError(name);count++;System.out.println("WALLPAPER_OK "+name);}
    public static void main(String[] args){
        check(WallpaperRules.validRequest("bond",10,1,1),"valid cuddle");
        check(!WallpaperRules.validRequest("feed",10,1,2),"generation changed");
        check(!WallpaperRules.validRequest("feed",-1,1,1),"clock rollback");
        check(!WallpaperRules.validRequest("feed",900000,1,1),"expired action");
        check(!WallpaperRules.validRequest("buy",10,1,1),"no purchase command");
        check(WallpaperRules.sleeping(4,100,0,200,0,false,12),"manual sleep");
        check(WallpaperRules.sleeping(4,100,0,0,0,true,22),"night sleep");
        check(!WallpaperRules.sleeping(4,100,0,0,200,true,22),"manual wake");
        check(!WallpaperRules.sleeping(4,100,200,200,0,true,22),"travel");
        check(!WallpaperRules.sleeping(0,100,0,200,0,true,22),"egg");
        check(WallpaperRules.projectedHunger(5,1,800,100)==4,"baby hunger");
        check(WallpaperRules.projectedHunger(5,4,2600,100)==4,"adult hunger");
        check(WallpaperRules.projectedHunger(1,4,0,999999)==0,"hunger clamp");
        check(WallpaperRules.projectedWaste(5,2600,100)==6,"waste clamp");
        check(WallpaperRules.projectedMood(10,1,1490,10)==9,"baby mood");
        check(WallpaperRules.gesture(0,-80,100,150,0).equals("feed"),"up swipe");
        check(WallpaperRules.gesture(0,0,100,120,250).equals("bond"),"double tap");
        check(WallpaperRules.gesture(0,0,100,120,0).equals("tap"),"single tap");
        check(WallpaperRules.gesture(100,0,100,120,0).isEmpty(),"launcher horizontal gesture");
        check(WallpaperRules.gesture(0,0,100,800,0).isEmpty(),"long press ignored");
        float[] a=WallpaperRules.placement(1080,2400,4,0,0,2);
        check(a[0]-a[2]/2>=0 && a[1]-a[2]/2>=0,"top left large fits");
        float[] b=WallpaperRules.placement(2400,1080,4,2,2,2);
        check(b[0]+b[2]/2<=2400 && b[1]+b[2]/2<=1080,"landscape large fits");
        check(b[3]+1080*.038f<=1080,"status stays on screen");
        check(WallpaperRules.placement(1080,2400,0,1,1,1)[2]<WallpaperRules.placement(1080,2400,4,1,1,1)[2],"baby scale");
        System.out.println("FOREVER_WALLPAPER_RULES_PASS "+count);
    }
}
