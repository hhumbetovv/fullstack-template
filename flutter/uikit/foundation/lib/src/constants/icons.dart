enum AppIcons {
  chevronLeft('chevron-left'),
  loader('loader'),
  chevronRight('chevron-right');

  const AppIcons(this._name);

  final String _name;

  String get path => 'assets/icons/$_name.svg';
}
