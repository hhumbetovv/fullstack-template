import 'package:demo_domain/public.dart';
import 'package:injectable/injectable.dart';

@Singleton(as: DemoRepository)
class DemoRepositoryImpl extends DemoRepository {
  @override
  int demoMethod() {
    return 5;
  }
}
