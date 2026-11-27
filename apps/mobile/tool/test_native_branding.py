"""Native branding invariants; run with Python/Pillow on the host."""
import hashlib
import json
from pathlib import Path
import plistlib
import tempfile
import unittest
from unittest.mock import patch
from PIL import Image
import generate_branding as branding

class BrandingChecks(unittest.TestCase):
    def test_source_unchanged_and_ios_icons_opaque_at_required_sizes(self):
        source=branding.ROOT/'assets/images/branding/ludo_lovers_icon.webp'
        self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(),'ba8aba9f3486fa01939bafca8bea6e74a6a99bf00861dab163d8224f7dfb9793')
        root=branding.OUT/'ios/Assets.xcassets/AppIcon.appiconset'
        icons=json.loads((root/'Contents.json').read_text())['images']
        self.assertTrue(any(i['idiom']=='ios-marketing' for i in icons))
        for icon in icons:
            with Image.open(root/icon['filename']) as image:
                self.assertEqual(image.mode,'RGB')
                self.assertEqual(image.size,(round(float(icon['size'].split('x')[0])*int(icon['scale'][0])),)*2)
    def test_adaptive_content_is_inside_safe_circle(self):
        with Image.open(branding.OUT/'android/res/drawable-nodpi/launcher_foreground.png') as image:
            box=image.getchannel('A').getbbox()
            center=image.width/2
            # Android adaptive safe circle diameter66/108 of complete layer.
            radius=image.width*66/108/2
            for x in [box[0],box[2]]:
                for y in [box[1],box[3]]:
                    self.assertLessEqual((x-center)**2+(y-center)**2,radius**2)
    def test_apply_is_idempotent_and_preserves_identifiers(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);android=root/'android/app/src/main';android.mkdir(parents=True)
            manifest=android/'AndroidManifest.xml'
            manifest.write_text('<manifest package="com.ludolovers.ludo_lovers"><application android:label="ludo_lovers"/></manifest>')
            ios=root/'ios/Runner';(ios/'Base.lproj').mkdir(parents=True)
            with (ios/'Info.plist').open('wb') as file:plistlib.dump({'CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)'},file)
            with patch.object(branding,'ROOT',root):
                branding.apply();first=manifest.read_bytes();branding.apply()
            self.assertEqual(first,manifest.read_bytes())
            self.assertIn(b'com.ludolovers.ludo_lovers',first)
            self.assertIn(b'android:label="Ludo Lovers"',first)
            with (ios/'Info.plist').open('rb') as file:info=plistlib.load(file)
            self.assertEqual(info['CFBundleIdentifier'],'$(PRODUCT_BUNDLE_IDENTIFIER)')
            self.assertEqual(info['CFBundleDisplayName'],'Ludo Lovers')

if __name__=='__main__':unittest.main()
