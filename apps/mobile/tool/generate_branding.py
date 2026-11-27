#!/usr/bin/env python3
"""Generate with Pillow 13.0.0; --apply needs stdlib only, AFTER flutter create.
Full-color canonical RGB logo is resized/letterboxed, never recolored/cropped.
"""
import argparse
import json
import plistlib
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'native_branding'
BG = '#160B28'

def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)

def generate():
    from PIL import Image, ImageDraw
    source = Image.open(ROOT / 'assets/images/branding/ludo_lovers_icon.webp').convert('RGB')
    def logo(path, size, fraction, transparent=False):
        canvas = Image.new('RGBA' if transparent else 'RGB', (size,size), (0,0,0,0) if transparent else BG)
        thumb = source.resize((round(size*fraction),)*2, Image.Resampling.LANCZOS)
        canvas.paste(thumb, ((size-thumb.width)//2,)*2)
        path.parent.mkdir(parents=True,exist_ok=True)
        canvas.save(path)
    res = OUT/'android/res'
    for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
        logo(res/f'mipmap-{density}/ic_launcher.png',size,.64)
    # Entire square fits inside the adaptive safe circle (diameter 66/108).
    logo(res/'drawable-nodpi/launcher_foreground.png',432,.42,True)
    logo(res/'drawable-nodpi/launch_logo.png',192,1)
    logo(res/'drawable-nodpi/splash_icon.png',288,.46,True)
    # Monochrome silhouette is a launcher-only derivative, never the full-color asset.
    mono=Image.new('RGBA',(432,432));mask=Image.new('L',(432,432))
    # Use source luminance inside the same safe square; dark background transparent.
    from PIL import ImageOps
    tile=ImageOps.grayscale(source.resize((181,181),Image.Resampling.LANCZOS)).point(lambda v: 255 if v>85 else 0)
    mask.paste(tile,(125,125));mono.paste('white',(0,0,432,432),mask)
    mono.save(res/'drawable-nodpi/launcher_monochrome.png')
    for version,monochrome in [('v26',''),('v33','<monochrome android:drawable="@drawable/launcher_monochrome"/>')]:
        write(res/f'mipmap-anydpi-{version}/ic_launcher.xml',f'<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/royal_background"/><foreground android:drawable="@drawable/launcher_foreground"/>{monochrome}</adaptive-icon>\n')
    write(res/'values/branding_colors.xml',f'<resources><color name="royal_background">{BG}</color></resources>\n')
    styles='''<resources><style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar"><item name="android:windowBackground">@drawable/launch_background</item><item name="android:windowLightStatusBar">false</item><item name="android:statusBarColor">@color/royal_background</item><item name="android:navigationBarColor">@color/royal_background</item></style><style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar"><item name="android:windowBackground">@color/royal_background</item><item name="android:statusBarColor">@color/royal_background</item><item name="android:navigationBarColor">@color/royal_background</item></style></resources>'''
    for folder in ['values','values-night']:
        write(res/f'{folder}/styles.xml',styles)
    for folder in ['drawable','drawable-v21']:
        write(res/f'{folder}/launch_background.xml','<layer-list xmlns:android="http://schemas.android.com/apk/res/android"><item android:drawable="@color/royal_background"/><item><bitmap android:gravity="center" android:src="@drawable/launch_logo"/></item></layer-list>\n')
    for folder in ['values-v31','values-night-v31']:
        write(res/f'{folder}/styles.xml',styles.replace('<item name="android:windowBackground">@drawable/launch_background</item>','<item name="android:windowBackground">@color/royal_background</item><item name="android:windowSplashScreenBackground">@color/royal_background</item><item name="android:windowSplashScreenAnimatedIcon">@drawable/splash_icon</item><item name="android:windowSplashScreenIconBackgroundColor">@color/royal_background</item>'))
    icons=OUT/'ios/Assets.xcassets/AppIcon.appiconset';images=[]
    for idiom,sizes,scales in [('iphone',[20,29,40,60],[2,3]),('ipad',[20,29,40,76],[1,2]),('ipad',[83.5],[2]),('ios-marketing',[1024],[1])]:
        for size in sizes:
            for scale in scales:
                name=f'icon-{size:g}-{scale}.png';logo(icons/name,round(size*scale),1)
                images.append({'idiom':idiom,'size':f'{size:g}x{size:g}','scale':f'{scale}x','filename':name})
    write(icons/'Contents.json',json.dumps({'images':images,'info':{'version':1,'author':'xcode'}},indent=2)+'\n')
    launch=OUT/'ios/Assets.xcassets/LaunchImage.imageset'
    for scale in [1,2,3]:logo(launch/f'launch-{scale}.png',192*scale,1)
    write(launch/'Contents.json',json.dumps({'images':[{'idiom':'universal','scale':f'{s}x','filename':f'launch-{s}.png'} for s in [1,2,3]],'info':{'version':1,'author':'xcode'}},indent=2)+'\n')
    write(OUT/'ios/LaunchScreen.storyboard','''<?xml version="1.0" encoding="UTF-8"?><document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="23501" targetRuntime="iOS.CocoaTouch" useAutolayout="YES" launchScreen="YES" initialViewController="launch"><scenes><scene sceneID="scene"><objects><viewController id="launch" sceneMemberID="viewController"><view key="view" contentMode="scaleToFill" id="root"><rect key="frame" x="0" y="0" width="393" height="852"/><subviews><imageView userInteractionEnabled="NO" contentMode="scaleAspectFit" image="LaunchImage" translatesAutoresizingMaskIntoConstraints="NO" id="logo"><constraints><constraint firstAttribute="width" constant="192" id="width"/><constraint firstAttribute="height" constant="192" id="height"/></constraints></imageView></subviews><color key="backgroundColor" red="0.08627451" green="0.04313725" blue="0.15686275" alpha="1" colorSpace="custom" customColorSpace="sRGB"/><constraints><constraint firstItem="logo" firstAttribute="centerX" secondItem="root" secondAttribute="centerX" id="centerX"/><constraint firstItem="logo" firstAttribute="centerY" secondItem="root" secondAttribute="centerY" id="centerY"/></constraints></view></viewController><placeholder placeholderIdentifier="IBFirstResponder" id="first" sceneMemberID="firstResponder"/></objects></scene></scenes><resources><image name="LaunchImage" width="192" height="192"/></resources></document>\n''')

def apply():
    android=ROOT/'android/app/src/main'
    if android.exists():
        shutil.copytree(OUT/'android/res',android/'res',dirs_exist_ok=True)
        p=android/'AndroidManifest.xml';text=p.read_text()
        import re
        text=re.sub(r'android:label="[^"]*"','android:label="Ludo Lovers"',text)
        p.write_text(text)
    ios=ROOT/'ios/Runner'
    if ios.exists():
        shutil.copytree(OUT/'ios/Assets.xcassets',ios/'Assets.xcassets',dirs_exist_ok=True)
        marketing=ios/'Assets.xcassets/AppIcon.appiconset/icon-1024-1.png'
        if not marketing.exists():
            # The 1.2MB marketing PNG is reproducibly generated on the Mac build
            # host from the canonical opaque image. No network/font downloads.
            subprocess.run(['sips','-s','format','png','--resampleHeightWidth',
                            '1024','1024',str(ROOT/'assets/images/branding/ludo_lovers_icon.webp'),
                            '--out',str(marketing)],check=True)
        shutil.copyfile(OUT/'ios/LaunchScreen.storyboard',ios/'Base.lproj/LaunchScreen.storyboard')
        p=ios/'Info.plist'
        with p.open('rb') as f:info=plistlib.load(f)
        info['CFBundleDisplayName']='Ludo Lovers';info['CFBundleName']='Ludo Lovers'
        with p.open('wb') as f:plistlib.dump(info,f,sort_keys=False)
    if not android.exists() and not ios.exists():
        raise SystemExit('Run flutter create for the required platform before --apply')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--generate',action='store_true');parser.add_argument('--apply',action='store_true');a=parser.parse_args()
    if a.generate:generate()
    if a.apply:apply()
