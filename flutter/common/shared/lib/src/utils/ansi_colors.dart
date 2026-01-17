import 'dart:ui';

enum AnsiColors {
  kDefault('\x1B[0m'),

  red('\x1B[38;2;255;85;85m'),
  green('\x1B[38;2;0;204;102m'),
  yellow('\x1B[38;2;255;221;51m'),
  blue('\x1B[38;2;51;153;255m'),

  purple('\x1B[38;2;186;85;211m'),
  cyan('\x1B[36m'),
  white('\x1B[37m'),
  orange('\x1B[38;2;255;136;0m'),
  amber('\x1B[38;2;255;193;7m'),
  teal('\x1B[38;2;0;150;136m'),
  indigo('\x1B[38;2;63;81;181m'),
  blueGrey('\x1B[38;2;96;125;139m'),

  brightBlack('\x1B[90m'),
  brightRed('\x1B[91m'),
  brightGreen('\x1B[92m'),
  brightYellow('\x1B[93m'),
  brightBlue('\x1B[94m'),
  brightPurple('\x1B[38;2;209;108;253m'),
  brightCyan('\x1B[96m'),
  brightWhite('\x1B[97m'),

  lightRed('\x1B[38;2;255;102;102m'),
  lightGreen('\x1B[38;2;144;238;144m'),
  lightYellow('\x1B[38;2;255;255;153m'),
  lightBlue('\x1B[38;2;173;216;230m'),
  lightPurple('\x1B[38;2;218;112;214m'),
  lightCyan('\x1B[38;2;224;255;255m'),
  lightWhite('\x1B[38;2;245;245;245m'),

  lightPink('\x1B[38;2;255;182;193m'),
  pink('\x1B[38;2;255;105;180m'),
  gold('\x1B[38;2;255;215;0m'),
  darkGreen('\x1B[38;2;0;100;0m'),
  brown('\x1B[38;2;139;69;19m');

  const AnsiColors(this._code);

  final String _code;

  String get code => enabled ? _code : '';

  String apply(String text) => '$code$text${kDefault.code}';

  static const bool enabled = bool.fromEnvironment('ANSI', defaultValue: true);

  Color? toHex() {
    final ansiToHex = {
      '30': 0xFF000000,
      '31': 0xFFFF5555,
      '32': 0xFF00CC66,
      '33': 0xFFFFDD33,
      '34': 0xFF3399FF,
      '35': 0xFFBA55D3,
      '36': 0xFF00CED1,
      '37': 0xFFFFFFFF,
      '90': 0xFF555555,
      '91': 0xFFFF6B6B,
      '92': 0xFF69F0AE,
      '93': 0xFFFFFF00,
      '94': 0xFF40C4FF,
      '95': 0xFFD16CFD,
      '96': 0xFF80DEEA,
      '97': 0xFFFFFFFF,
    };

    if (code.contains('[38;2;')) {
      final start = code.indexOf('[38;2;') + '[38;2;'.length;
      final end = code.indexOf('m', start);
      final rgbPart = code.substring(start, end);
      final rgbValues = rgbPart.split(';');

      if (rgbValues.length == 3) {
        final r = int.parse(rgbValues[0]);
        final g = int.parse(rgbValues[1]);
        final b = int.parse(rgbValues[2]);

        return Color.fromARGB(255, r, g, b);
      }
    }

    if (code.contains('[') && code.contains('m')) {
      final start = code.indexOf('[') + 1;
      final end = code.indexOf('m', start);
      final ansiCode = code.substring(start, end);

      if (ansiToHex.containsKey(ansiCode)) {
        return Color(ansiToHex[ansiCode]!);
      }
    }

    return null;
  }
}
