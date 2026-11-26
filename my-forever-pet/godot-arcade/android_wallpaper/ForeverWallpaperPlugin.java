package org.myforeverpet.wallpaper;
import android.app.Activity;
import android.app.WallpaperManager;
import android.content.*;
import android.util.AtomicFile;
import android.util.Log;
import java.io.*;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

public final class ForeverWallpaperPlugin extends GodotPlugin {
    public ForeverWallpaperPlugin(Godot godot){super(godot);}
    @Override public String getPluginName(){return "ForeverWallpaper";}
    @UsedByGodot public boolean putImage(String key, byte[] png){
        Activity a=getActivity();
        if(a==null || !key.matches("(awake|sleep|room)_[0-9]{1,2}") || png==null || png.length>4000000)return false;
        File dir=new File(a.getFilesDir(),"forever_wallpaper");
        if(!dir.isDirectory()&&!dir.mkdirs())return false;
        AtomicFile file=new AtomicFile(new File(dir,key+".png"));
        FileOutputStream out=null;
        try{out=file.startWrite();out.write(png);file.finishWrite(out);return true;}
        catch(IOException e){if(out!=null)file.failWrite(out);Log.w("ForeverWallpaper","Image write failed",e);return false;}
    }
    @UsedByGodot public void syncState(String json){
        Activity a=getActivity(); if(a!=null&&json.length()<12000)
            a.getSharedPreferences("forever_wallpaper",Context.MODE_PRIVATE).edit().putString("snapshot",json).apply();
    }
    @UsedByGodot public String consumeAction(){
        Activity a=getActivity();if(a==null)return "";
        synchronized(ForeverWallpaperService.ACTION_LOCK){
            android.content.SharedPreferences p=a.getSharedPreferences("forever_wallpaper",Context.MODE_PRIVATE);
            String request=p.getString("request","");
            long at=p.getLong("request_at",0);
            p.edit().remove("request").remove("request_at").commit();
            return System.currentTimeMillis()-at<900000 && System.currentTimeMillis()>=at?request:"";
        }
    }
    @UsedByGodot public boolean openPicker(){
        Activity a=getActivity();if(a==null)return false;
        Intent i=new Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER);
        i.putExtra(WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,new ComponentName(a,ForeverWallpaperService.class));
        if(i.resolveActivity(a.getPackageManager())==null)return false;
        a.runOnUiThread(()->{try{a.startActivity(i);}catch(RuntimeException e){Log.w("ForeverWallpaper","Picker failed",e);}});
        return true;
    }
    @UsedByGodot public boolean isActive(){
        Activity a=getActivity();if(a==null)return false;
        android.app.WallpaperInfo i=WallpaperManager.getInstance(a).getWallpaperInfo();
        return i!=null && a.getPackageName().equals(i.getPackageName()) && ForeverWallpaperService.class.getName().equals(i.getServiceName());
    }
}
