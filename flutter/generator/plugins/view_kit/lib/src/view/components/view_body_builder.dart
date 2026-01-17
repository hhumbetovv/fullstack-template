import 'package:code_builder/code_builder.dart';
import 'package:gen_core/extensions.dart';
import 'package:processor/public.dart';

class ViewBodyBuilder {
  ViewBodyBuilder({
    required this.bodyChild,
    required this.effectMethodName,
  });

  final String bodyChild;
  final String Function(String baseName) effectMethodName;

  Code build(
    String baseName,
    Map<String, List<MethodConfig>> effectMap,
    bool isStateful,
  ) {
    var child = bodyChild;

    if (isStateful) {
      child =
          '''
        StatefulWrapper(
          initState: initState,
          dispose: dispose,
          child: $child
        )
        ''';
    }

    for (final entry in effectMap.entries) {
      final trimmed = entry.key.trimBefore('viewmodel');

      child =
          '''
        ViewModelListener<${entry.key}, ${trimmed}Effect>(
          onEffectUpdate: ${effectMethodName(trimmed)},
          child: $child,
        )
        ''';
    }

    final builder = 'Builder(builder: (ctx) { return $child; })';

    return Code(
      'return builder(context: context, '
      'child: ViewModelProvider<${baseName}ViewModel, ${baseName}Effect>( '
      'create: viewModelFactory, '
      'child: $builder, '
      ')'
      ');',
    );
  }
}
