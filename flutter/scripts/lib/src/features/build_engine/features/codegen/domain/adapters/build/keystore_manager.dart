import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scripts/src/core/command/errors.dart';
import 'package:scripts/src/core/logging/console.dart';

class AndroidKeystoreState {
  AndroidKeystoreState({
    required this.file,
    required this.hadExistingFile,
    required this.usingFallback,
  });

  final File file;
  final bool hadExistingFile;
  final bool usingFallback;
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

class AndroidKeystoreManager {
  const AndroidKeystoreManager();

  AndroidKeystoreState prepare(
    Directory appDir,
    bool needsAndroidKeystore,
  ) {
    final keyPropertiesFile = File('${appDir.path}/android/key.properties');
    final hadExistingKeyProperties = keyPropertiesFile.existsSync();

    if (!needsAndroidKeystore) {
      return AndroidKeystoreState(
        file: keyPropertiesFile,
        hadExistingFile: hadExistingKeyProperties,
        usingFallback: false,
      );
    }

    final loadResult = _loadAndroidCredentials();
    final credentials = loadResult.credentials;
    if (credentials == null) {
      throw const CommandError(
        'Android release builds require ANDROID_KEYSTORE_PATH, '
        'ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD.',
        exitCode: 64,
      );
    }

    if (loadResult.usingFallback) {
      Console.warning(
        'Android release keystore variables not found. Using debug keystore as fallback.',
      );
    }

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
      usingFallback: loadResult.usingFallback,
    );
  }

  void cleanup(AndroidKeystoreState state, bool keepKeyProperties) {
    if (keepKeyProperties || state.hadExistingFile) {
      return;
    }
    if (state.file.existsSync()) {
      state.file.deleteSync();
    }
  }

  _LoadResult _loadAndroidCredentials() {
    final envCredentials = _loadEnvCredentials();
    if (envCredentials != null) {
      return _LoadResult(
        credentials: envCredentials,
        usingFallback: false,
      );
    }

    final debugCredentials = _loadDebugCredentials();
    if (debugCredentials != null) {
      return _LoadResult(
        credentials: debugCredentials,
        usingFallback: true,
      );
    }

    return const _LoadResult(credentials: null, usingFallback: false);
  }

  AndroidKeystoreCredentials? _loadEnvCredentials() {
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
      return null;
    }

    return AndroidKeystoreCredentials(
      storeFilePath: keystorePath!,
      storePassword: keystorePassword!,
      keyAlias: keyAlias!,
      keyPassword: keyPassword!,
    );
  }

  AndroidKeystoreCredentials? _loadDebugCredentials() {
    final homeDir =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (homeDir == null || homeDir.trim().isEmpty) {
      return null;
    }
    final debugKeystore = File(p.join(homeDir, '.android', 'debug.keystore'));
    if (!debugKeystore.existsSync()) {
      return null;
    }
    return AndroidKeystoreCredentials(
      storeFilePath: debugKeystore.path,
      storePassword: 'android',
      keyAlias: 'androiddebugkey',
      keyPassword: 'android',
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
}

class _LoadResult {
  const _LoadResult({
    required this.credentials,
    required this.usingFallback,
  });

  final AndroidKeystoreCredentials? credentials;
  final bool usingFallback;
}
