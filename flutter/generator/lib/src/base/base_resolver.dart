abstract class BaseResolver<Config, Target> {
  Future<Config?> resolve(Target element);
}
