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
  await _patchIos();
  stdout.writeln('WorkKit Android/iOS platform bootstrap complete.');
}

Future<void> _deleteFlutterTemplateTest() async {
  final File templateTest = File('test/widget_test.dart');
  if (await templateTest.exists()) {
    await templateTest.delete();
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
