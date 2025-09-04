sealed class AppRegex {
  static const email = r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$';
  static const username = r'^[a-z0-9._]+$';
  static const password = r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[_\W]).{8,64}$';
}
