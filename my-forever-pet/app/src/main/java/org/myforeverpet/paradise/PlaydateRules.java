package org.myforeverpet.paradise;
/** Documented rules, independent implementation.
 * Source: https://github.com/GMMan/tama-para-research/blob/master/gameplay/playdate.md
 * Consumer interactions, network protocol and actual official characters not implemented.
 */
public final class PlaydateRules {
 private PlaydateRules(){}
 public static int base(int a,int b){if(a==5||b==5)return 4;if(a==0||b==0)return 1;return 4-Math.abs(a-b);}
 public static boolean fight(int h1,int j1,int h2,int j2){return (h1<=2||j1<=5)&&(h2<=2||j2<=5);}
 public static int after(int f,boolean love1,boolean love2){return f==0?0:Math.min(4,f+1+(love1?1:0)+(love2?1:0));}
 public static boolean canBreed(boolean adult1,boolean adult2,int friendship,boolean blocked1,boolean blocked2){return adult1&&adult2&&friendship==4&&!blocked1&&!blocked2;}
}
