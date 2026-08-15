import 'dart:io';

Future<void> main() async {
  final File gradleFile = File('android/app/build.gradle.kts');
  if (!await gradleFile.exists()) {
    stderr.writeln(
      'android/app/build.gradle.kts is missing. Run tool/bootstrap_platforms.dart first.',
    );
    exitCode = 1;
    return;
  }

  String content = await gradleFile.readAsString();
  if (content.contains('create("release")') &&
      content.contains('WORKKIT_KEYSTORE_PATH')) {
    stdout.writeln('Android release signing is already configured.');
    return;
  }

  const String buildTypesMarker = '    buildTypes {';
  if (!content.contains(buildTypesMarker)) {
    stderr.writeln('Unable to locate Android buildTypes block.');
    exitCode = 1;
    return;
  }

  const String signingBlock = '''    signingConfigs {
        create("release") {
            val keystorePath = System.getenv("WORKKIT_KEYSTORE_PATH")
                ?: error("WORKKIT_KEYSTORE_PATH is required")
            storeFile = file(keystorePath)
            storePassword = System.getenv("WORKKIT_KEYSTORE_PASSWORD")
                ?: error("WORKKIT_KEYSTORE_PASSWORD is required")
            keyAlias = System.getenv("WORKKIT_KEY_ALIAS")
                ?: error("WORKKIT_KEY_ALIAS is required")
            keyPassword = System.getenv("WORKKIT_KEY_PASSWORD")
                ?: error("WORKKIT_KEY_PASSWORD is required")
        }
    }

''';
  content = content.replaceFirst(
    buildTypesMarker,
    '$signingBlock$buildTypesMarker',
  );

  final RegExp debugSigning = RegExp(
    r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
  );
  if (!debugSigning.hasMatch(content)) {
    stderr.writeln('Unable to locate Flutter default release signing config.');
    exitCode = 1;
    return;
  }
  content = content.replaceFirst(
    debugSigning,
    'signingConfig = signingConfigs.getByName("release")',
  );
  await gradleFile.writeAsString(content);
  stdout.writeln('Android release signing configured from environment variables.');
}
