class NavKey {
  const NavKey(this.name);

  factory NavKey.empty() => const NavKey('');

  final String name;
}
