"""Overlay the official Godot 4.4.1 Android Gradle template, without editing engine files."""
import pathlib, shutil, sys, xml.etree.ElementTree as ET
source=pathlib.Path(__file__).parent
target=pathlib.Path(sys.argv[1])
manifest=target/'AndroidManifest.xml'
assert manifest.is_file() and (target/'build.gradle').is_file(),target
pkg=target/'src'/'org'/'myforeverpet'/'wallpaper'
pkg.mkdir(parents=True,exist_ok=True)
for f in source.glob('*.java'): shutil.copy2(f,pkg/f.name)
xml=target/'res'/'xml';xml.mkdir(parents=True,exist_ok=True)
(xml/'forever_wallpaper.xml').write_text('<wallpaper xmlns:android="http://schemas.android.com/apk/res/android" />\n')
A='{http://schemas.android.com/apk/res/android}'
ET.register_namespace('android',A[1:-1]);ET.register_namespace('tools','http://schemas.android.com/tools')
tree=ET.parse(manifest);root=tree.getroot();app=root.find('application');assert app is not None
ET.SubElement(root,'uses-feature',{A+'name':'android.software.live_wallpaper',A+'required':'false'})
ET.SubElement(app,'meta-data',{A+'name':'org.godotengine.plugin.v2.ForeverWallpaper',A+'value':'org.myforeverpet.wallpaper.ForeverWallpaperPlugin'})
service=ET.SubElement(app,'service',{A+'name':'org.myforeverpet.wallpaper.ForeverWallpaperService',A+'label':'My Forever Pet',A+'exported':'true',A+'permission':'android.permission.BIND_WALLPAPER'})
f=ET.SubElement(service,'intent-filter');ET.SubElement(f,'action',{A+'name':'android.service.wallpaper.WallpaperService'})
ET.SubElement(service,'meta-data',{A+'name':'android.service.wallpaper',A+'resource':'@xml/forever_wallpaper'})
tree.write(manifest,encoding='utf-8',xml_declaration=True)
print('FOREVER_WALLPAPER_TEMPLATE_READY')
