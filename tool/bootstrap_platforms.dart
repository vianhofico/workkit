import 'dart:io';

Future<void> main() async {
  final ProcessResult result = await Process.run(
    'flutter',
    <String>[
      'create',
      '--no-pub',
      '--org',
      'com.workkit',
      '--project-name',
      'workkit',
      '--platforms=android,ios',
      '.',
    ],
    runInShell: Platform.isWindows,
  );

  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exitCode = result.exitCode;
    return;
  }

  await _deleteFlutterTemplateTest();
  await _patchAndroid();
  await _patchIos();
  await _verifyAndroidPrivacyHardening();
  await _verifyAndroidReleaseHardening();
  await _verifyProductIdentity();
  stdout.writeln('WorkKit Android/iOS platform bootstrap complete.');
}

Future<void> _deleteFlutterTemplateTest() async {
  final File templateTest = File('test/widget_test.dart');
  if (await templateTest.exists()) {
    await templateTest.delete();
  }
}

Future<void> _patchAndroid() async {
  final File manifest = File('android/app/src/main/AndroidManifest.xml');
  if (await manifest.exists()) {
    String content = await manifest.readAsString();
    content = content.replaceFirst(
      RegExp(r'android:label="[^"]*"'),
      'android:label="WorkKit"',
    );
    if (!content.contains('android:allowBackup=')) {
      content = content.replaceFirst(
        '<application',
        '<application\n'
            '        android:allowBackup="false"\n'
            '        android:fullBackupContent="@xml/backup_rules"\n'
            '        android:dataExtractionRules="@xml/data_extraction_rules"\n'
            '        android:usesCleartextTraffic="false"\n'
            '        android:networkSecurityConfig="@xml/network_security_config"',
      );
    }
    await manifest.writeAsString(content);
  }

  final Directory xml = Directory('android/app/src/main/res/xml');
  await xml.create(recursive: true);
  await File('${xml.path}${Platform.pathSeparator}backup_rules.xml').writeAsString(
    '''<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <exclude domain="root" path="." />
    <exclude domain="file" path="." />
    <exclude domain="database" path="." />
    <exclude domain="sharedpref" path="." />
    <exclude domain="external" path="." />
</full-backup-content>
''',
  );
  await File('${xml.path}${Platform.pathSeparator}data_extraction_rules.xml')
      .writeAsString(
    '''<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="root" path="." />
        <exclude domain="file" path="." />
        <exclude domain="database" path="." />
        <exclude domain="sharedpref" path="." />
        <exclude domain="external" path="." />
        <exclude domain="device_root" path="." />
        <exclude domain="device_file" path="." />
        <exclude domain="device_database" path="." />
        <exclude domain="device_sharedpref" path="." />
    </cloud-backup>
    <device-transfer>
        <exclude domain="root" path="." />
        <exclude domain="file" path="." />
        <exclude domain="database" path="." />
        <exclude domain="sharedpref" path="." />
        <exclude domain="external" path="." />
        <exclude domain="device_root" path="." />
        <exclude domain="device_file" path="." />
        <exclude domain="device_database" path="." />
        <exclude domain="device_sharedpref" path="." />
    </device-transfer>
</data-extraction-rules>
''',
  );
  await File('${xml.path}${Platform.pathSeparator}network_security_config.xml')
      .writeAsString(
    '''<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false" />
</network-security-config>
''',
  );

  const String proguardRules = '''# WorkKit uses only ML Kit's Latin text recognizer.
# The Flutter plugin references optional recognizers in a runtime switch, so R8
# must tolerate their classes being absent when their language artifacts are not bundled.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
''';
  await File('android/app/proguard-rules.pro').writeAsString(proguardRules);

  final File gradle = File('android/app/build.gradle.kts');
  if (await gradle.exists()) {
    String content = await gradle.readAsString();
    if (!content.contains('proguard-rules.pro')) {
      const String signingMarker =
          'signingConfig = signingConfigs.getByName("debug")';
      if (!content.contains(signingMarker)) {
        throw StateError(
          'Unable to locate Flutter default release signing configuration.',
        );
      }
      content = content.replaceFirst(
        signingMarker,
        '''$signingMarker
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )''',
      );
      await gradle.writeAsString(content);
    }
  }
}

Future<void> _patchIos() async {
  final File podfile = File('ios/Podfile');
  if (await podfile.exists()) {
    String content = await podfile.readAsString();
    final RegExp platformLine = RegExp(
      r"^#?\s*platform :ios, '[^']+'",
      multiLine: true,
    );
    if (platformLine.hasMatch(content)) {
      content = content.replaceFirst(platformLine, "platform :ios, '15.5'");
    } else {
      content = "platform :ios, '15.5'\n\n$content";
    }

    const String marker = 'flutter_additional_ios_build_settings(target)';
    const String permissionBlock = '''flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '\$(inherited)',
        'PERMISSION_CAMERA=1',
      ]
    end''';
    if (!content.contains('PERMISSION_CAMERA=1') && content.contains(marker)) {
      content = content.replaceFirst(marker, permissionBlock);
    }
    await podfile.writeAsString(content);
  }

  final File plist = File('ios/Runner/Info.plist');
  if (await plist.exists()) {
    String content = await plist.readAsString();
    content = content.replaceFirst(
      RegExp(
        r'<key>CFBundleDisplayName</key>\s*<string>[^<]*</string>',
        multiLine: true,
      ),
      '<key>CFBundleDisplayName</key>\n\t<string>WorkKit</string>',
    );
    if (!content.contains('NSCameraUsageDescription')) {
      content = content.replaceFirst(
        '</dict>',
        '\t<key>NSCameraUsageDescription</key>\n'
            '\t<string>WorkKit uses the camera only to scan documents and QR codes on this device.</string>\n'
            '</dict>',
      );
    }
    if (!content.contains('CFBundleLocalizations')) {
      content = content.replaceFirst(
        '</dict>',
        '\t<key>CFBundleLocalizations</key>\n'
            '\t<array>\n'
            '\t\t<string>en</string>\n'
            '\t\t<string>vi</string>\n'
            '\t</array>\n'
            '</dict>',
      );
    }
    await plist.writeAsString(content);
  }

  final Directory en = Directory('ios/Runner/en.lproj');
  final Directory vi = Directory('ios/Runner/vi.lproj');
  await en.create(recursive: true);
  await vi.create(recursive: true);
  await File('${en.path}${Platform.pathSeparator}InfoPlist.strings').writeAsString(
    '"CFBundleDisplayName" = "WorkKit";\n'
    '"NSCameraUsageDescription" = "WorkKit uses the camera to scan documents and QR codes on this device.";\n',
  );
  await File('${vi.path}${Platform.pathSeparator}InfoPlist.strings').writeAsString(
    '"CFBundleDisplayName" = "WorkKit";\n'
    '"NSCameraUsageDescription" = "WorkKit sử dụng camera để quét tài liệu và mã QR trên thiết bị này.";\n',
  );
}

Future<void> _verifyAndroidPrivacyHardening() async {
  final File manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!await manifest.exists()) {
    throw StateError('Android manifest is missing after platform bootstrap.');
  }
  final String content = await manifest.readAsString();
  for (final String required in <String>[
    'android:allowBackup="false"',
    'android:fullBackupContent="@xml/backup_rules"',
    'android:dataExtractionRules="@xml/data_extraction_rules"',
    'android:usesCleartextTraffic="false"',
    'android:networkSecurityConfig="@xml/network_security_config"',
  ]) {
    if (!content.contains(required)) {
      throw StateError('Android privacy hardening is missing: $required');
    }
  }

  for (final String path in <String>[
    'android/app/src/main/res/xml/backup_rules.xml',
    'android/app/src/main/res/xml/data_extraction_rules.xml',
    'android/app/src/main/res/xml/network_security_config.xml',
  ]) {
    if (!await File(path).exists()) {
      throw StateError('Android privacy hardening resource is missing: $path');
    }
  }
}

Future<void> _verifyAndroidReleaseHardening() async {
  final File gradle = File('android/app/build.gradle.kts');
  final File proguard = File('android/app/proguard-rules.pro');
  if (!await gradle.exists() || !await proguard.exists()) {
    throw StateError('Android release hardening files are missing.');
  }

  final String gradleContent = await gradle.readAsString();
  if (!gradleContent.contains('proguard-rules.pro')) {
    throw StateError('Android release build is missing custom R8 rules.');
  }

  final String rules = await proguard.readAsString();
  for (final String namespace in <String>[
    'com.google.mlkit.vision.text.chinese.**',
    'com.google.mlkit.vision.text.devanagari.**',
    'com.google.mlkit.vision.text.japanese.**',
    'com.google.mlkit.vision.text.korean.**',
  ]) {
    if (!rules.contains('-dontwarn $namespace')) {
      throw StateError('Android release R8 rule is missing: $namespace');
    }
  }
}

Future<void> _verifyProductIdentity() async {
  final String androidManifest =
      await File('android/app/src/main/AndroidManifest.xml').readAsString();
  if (!androidManifest.contains('android:label="WorkKit"')) {
    throw StateError('Android display name must be WorkKit.');
  }

  final String iosPlist = await File('ios/Runner/Info.plist').readAsString();
  if (!iosPlist.contains('<string>WorkKit</string>')) {
    throw StateError('iOS display name must be WorkKit.');
  }
}
