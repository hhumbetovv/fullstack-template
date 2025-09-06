import 'package:demo_domain/src/repository/demo_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class DemoUseCase {
  DemoUseCase({
    required this.repository,
  });

  final DemoRepository repository;

  int call() {
    return repository.demoMethod();
  }
}
