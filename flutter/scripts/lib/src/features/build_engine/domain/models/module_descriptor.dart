import 'dart:io';

class ModuleDescriptor {
  ModuleDescriptor({
    required this.name,
    required this.path,
    required this.hasBuildRunner,
  });

  final String name;
  final String path;
  final bool hasBuildRunner;

  Directory get directory => Directory(path);
}
