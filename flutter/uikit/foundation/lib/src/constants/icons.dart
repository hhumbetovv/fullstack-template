enum AppIcons {
  loader('loader'),
  close('close'),
  search('search'),
  chevronLeft('chevron-left'),
  chevronRight('chevron-right');

  const AppIcons(this._name);

  final String _name;

  String get path => 'assets/icons/$_name.svg';
}
