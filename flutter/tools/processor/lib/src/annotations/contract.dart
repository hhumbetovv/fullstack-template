final class Intent {
  const Intent();
}

const intent = Intent();

final class Effect {
  const Effect({
    this.from = const [],
  });

  final List<Type> from;
}

const effect = Effect();
