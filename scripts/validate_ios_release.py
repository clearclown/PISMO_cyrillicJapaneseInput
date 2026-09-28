#!/usr/bin/env python3
"""Local packaging checks. This does not assert signing or App Review readiness."""
import hashlib
from pathlib import Path
import plistlib
import struct
import sys
from prepare_ios_resources import MODELS

ROOT = Path(__file__).resolve().parents[1]
errors = []


def check(condition, description):
    print(f"{'PASS' if condition else 'FAIL'} {description}")
    if not condition:
        errors.append(description)


def plist(path):
    with (ROOT / path).open('rb') as file:
        return plistlib.load(file)


for target in ['MainApp', 'Keyboard']:
    manifest = plist(f'iOS/{target}/PrivacyInfo.xcprivacy')
    check(manifest.get('NSPrivacyTracking') is False, f'{target}: no tracking')
    reasons = [item for item in manifest['NSPrivacyAccessedAPITypes']
               if item['NSPrivacyAccessedAPIType'] == 'NSPrivacyAccessedAPICategoryUserDefaults']
    check(bool(reasons) and {'CA92.1', '1C8F.1'} <= set(reasons[0]['NSPrivacyAccessedAPITypeReasons']),
          f'{target}: local and shared defaults declarations')
    check(bool(manifest['NSPrivacyCollectedDataTypes']), f'{target}: optional reports disclosed')
    check(plist(f'iOS/{target}/' + ('Pismo.entitlements' if target == 'MainApp' else 'Keyboard.entitlements'))
          ['com.apple.security.application-groups'] == ['group.com.pismo.keyboard'], f'{target}: App Group')

extension = plist('iOS/Keyboard/Info.plist')['NSExtension']
check(extension['NSExtensionPointIdentifier'] == 'com.apple.keyboard-service', 'keyboard extension identifier')
check(extension['NSExtensionAttributes']['PrimaryLanguage'] == 'ja-JP', 'Japanese output language')
check(plist('iOS/MainApp/Info.plist')['ITSAppUsesNonExemptEncryption'] is False, 'export declaration present')
orientations = plist('iOS/MainApp/Info.plist').get('UISupportedInterfaceOrientations~ipad', [])
check(set(orientations) == {
    'UIInterfaceOrientationPortrait', 'UIInterfaceOrientationPortraitUpsideDown',
    'UIInterfaceOrientationLandscapeLeft', 'UIInterfaceOrientationLandscapeRight'
}, 'iPad portrait and landscape support')

icon = (ROOT / 'iOS/MainApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png').read_bytes()
width, height, depth, color = struct.unpack('>IIBB', icon[16:26])
check((width, height) == (1024, 1024) and color in (0, 2), '1024px opaque App Store icon')
for size, _, checksum in MODELS:
    path = ROOT / f'iOS/zenz-v3.1-{size}-gguf/ggml-model-Q5_K_M.gguf'
    check(path.exists() and hashlib.sha256(path.read_bytes()).hexdigest() == checksum, f'Zenzai {size} checksum')
for version in ['15.1', '16.0']:
    for kind in ['all', 'dict', 'genre']:
        check((ROOT / f'iOS/pismo_emoji_dictionary_storage/EmojiDictionary/emoji_{kind}_E{version}.txt').is_file(),
              f'emoji {kind} E{version}')
dictionary = ROOT / 'iOS/pismo_dictionary_storage/Dictionary'
check((dictionary / 'louds/charID.chid').is_file() and (dictionary / 'mm.binary').is_file(), 'bundled conversion dictionary')
for name in ['RELEASE.md', 'METADATA.md', 'PRIVACY.md']:
    check((ROOT / 'docs/appstore' / name).is_file(), name)
print('\nLocal checks only. Still required: device acceptance, valid signing, public policy URL, App Store Connect validation.')
sys.exit(bool(errors))
