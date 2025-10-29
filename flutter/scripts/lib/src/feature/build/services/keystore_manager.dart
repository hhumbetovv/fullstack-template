import 'dart:io';

import 'package:scripts/src/core/core.dart';

class AndroidKeystoreState {
  AndroidKeystoreState({
    required this.file,
    required this.hadExistingFile,
  });

  final File file;
  final bool hadExistingFile;
}

class AndroidKeystoreCredentials {
  AndroidKeystoreCredentials({
    required this.storeFilePath,
    required this.storePassword,
    required this.keyAlias,
    required this.keyPassword,
  });

  final String storeFilePath;
  final String storePassword;
  final String keyAlias;
  final String keyPassword;
}

AndroidKeystoreState prepareAndroidKeystore(
  Directory appDir,
  bool needsAndroidKeystore,
) {
  final keyPropertiesFile = File('${appDir.path}/android/key.properties');
  final hadExistingKeyProperties = keyPropertiesFile.existsSync();

  if (!needsAndroidKeystore) {
    return AndroidKeystoreState(
      file: keyPropertiesFile,
      hadExistingFile: hadExistingKeyProperties,
    );
  }

  final credentials = _loadAndroidCredentials();

  _writeKeyProperties(
    keyPropertiesFile,
    credentials.storeFilePath,
    credentials.storePassword,
    credentials.keyAlias,
    credentials.keyPassword,
  );

  return AndroidKeystoreState(
    file: keyPropertiesFile,
    hadExistingFile: hadExistingKeyProperties,
  );
}

void cleanupAndroidKeystore(
  AndroidKeystoreState state,
  bool keepKeyProperties,
) {
  if (keepKeyProperties) {
    return;
  }
  if (state.hadExistingFile) {
    return;
  }
  if (state.file.existsSync()) {
    state.file.deleteSync();
  }
}

AndroidKeystoreCredentials _loadAndroidCredentials() {
  final keystorePath = _resolveKeystorePath();
  final keystorePassword = _normalizedEnv('ANDROID_KEYSTORE_PASSWORD');
  final keyAlias = _normalizedEnv('ANDROID_KEY_ALIAS');
  final keyPassword = _normalizedEnv('ANDROID_KEY_PASSWORD');

  if ([
    keystorePath,
    keystorePassword,
    keyAlias,
    keyPassword,
  ].any((value) => value == null)) {
    throw const CommandError(
      'Android release builds require ANDROID_KEYSTORE_PATH, '
      'ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD.',
      exitCode: 64,
    );
  }

  return AndroidKeystoreCredentials(
    storeFilePath: keystorePath!,
    storePassword: keystorePassword!,
    keyAlias: keyAlias!,
    keyPassword: keyPassword!,
  );
}

String? _normalizedEnv(String key) {
  final value = Platform.environment[key];
  return (value == null || value.trim().isEmpty) ? null : value.trim();
}

String? _resolveKeystorePath() {
  final directPath = _normalizedEnv('ANDROID_KEYSTORE_PATH');
  if (directPath != null && directPath.isNotEmpty) {
    return directPath;
  }
  final relativePath = File('android/key.properties');
  if (relativePath.existsSync()) {
    return relativePath.path;
  }
  return null;
}

void _writeKeyProperties(
  File file,
  String storeFilePath,
  String storePassword,
  String keyAlias,
  String keyPassword,
) {
  file
    ..createSync(recursive: true)
    ..writeAsStringSync(
      'storeFile=${_escapePropertyValue(storeFilePath)}\n'
      'storePassword=${_escapePropertyValue(storePassword)}\n'
      'keyAlias=${_escapePropertyValue(keyAlias)}\n'
      'keyPassword=${_escapePropertyValue(keyPassword)}\n',
    );
  try {
    Process.runSync('chmod', ['600', file.path]);
  } on ProcessException {
    // Ignore platforms without chmod.
  }
}

String _escapePropertyValue(String value) {
  return value
      .replaceAll(r'\\', r'\\\\')
      .replaceAll('\n', r'\\n')
      .replaceAll('\r', r'\\r')
      .replaceAll('\t', r'\\t')
      .replaceAll('#', r'\\#')
      .replaceAll('=', r'\\=')
      .replaceAll(':', r'\\:')
      .replaceAll(' ', r'\\ ');
}
