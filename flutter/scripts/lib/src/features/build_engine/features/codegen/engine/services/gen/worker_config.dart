import 'dart:io';
import 'dart:math' as math;

class WorkerConfig {
  const WorkerConfig();

  int resolve(String? rawValue, int moduleCount) {
    if (moduleCount <= 1) return 1;

    final value = rawValue?.trim();
    if (value == null || value.isEmpty || value.toLowerCase() == 'auto') {
      final processors = Platform.numberOfProcessors;
      final suggested = processors > 2 ? processors ~/ 2 : processors;
      return math.max(1, math.min(suggested, moduleCount));
    }

    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return 1;
    }

    return math.max(1, math.min(parsed, moduleCount));
  }
}
