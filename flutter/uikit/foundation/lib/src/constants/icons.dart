enum AppIcons {
  demo('');

  const AppIcons(this._name);

  final String _name;

  String get path => 'assets/icons/$_name.svg';
}
