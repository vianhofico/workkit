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
      await manifest.writeAsString(content);
    }
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
    if (!content.contains('NSCameraUsageDescription')) {
      content = content.replaceFirst(
        '</dict>',
        '\t<key>NSCameraUsageDescription</key>\n'
            '\t<string>WorkKit uses the camera only to scan documents and QR codes on this device.</string>\n'
            '</dict>',
      );
      await plist.writeAsString(content);
    }
  }
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
