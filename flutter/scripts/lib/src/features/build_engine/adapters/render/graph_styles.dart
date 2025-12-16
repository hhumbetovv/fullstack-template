void writeEdgeStyles(
  StringBuffer buffer,
  Map<String, List<int>> edgeColorMap,
) {
  if (edgeColorMap.isEmpty) {
    return;
  }

  buffer.writeln('');
  final styleEntries = edgeColorMap.entries.toList()
    ..sort((a, b) => a.value.first.compareTo(b.value.first));
  for (final entry in styleEntries) {
    final indices = entry.value..sort();
    buffer.writeln(
      '    linkStyle ${indices.join(',')} stroke:${entry.key},stroke-width:1.9,opacity:0.9',
    );
  }
}

void writeClassStyles(
  StringBuffer buffer,
  Set<String> presentClasses,
  bool focusUsed,
) {
  const classOrder = <String>[
    'presentation',
    'domain',
    'data',
    'ui',
    'common',
    'core',
    'unused',
  ];
  const classStyles = <String, String>{
    'presentation':
        '    classDef presentation fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000000',
    'domain':
        '    classDef domain fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000000',
    'data':
        '    classDef data fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#000000',
    'ui':
        '    classDef ui fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000000',
    'common':
        '    classDef common fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000000',
    'core':
        '    classDef core fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000000',
    'unused':
        '    classDef unused fill:#ffebee,stroke:#c62828,stroke-width:2px,color:#000000',
  };

  for (final className in classOrder) {
    if (presentClasses.contains(className)) {
      buffer.writeln(classStyles[className]);
    }
  }

  if (focusUsed) {
    buffer.writeln(
      '    classDef focus fill:#fffde7,stroke:#fbc02d,stroke-width:2.5px,color:#000000',
    );
  }
}
