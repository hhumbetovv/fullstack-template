import 'package:core_domain/src/entity/failure.dart';
import 'package:core_domain/src/entity/paged.dart';
import 'package:core_domain/src/result/result.dart';

typedef DataResult<Data> = Result<Data, Failure>;
typedef AsyncResult<Data> = Future<DataResult<Data>>;
typedef PagedResult<Data> = AsyncResult<Paged<Data>>;
typedef FlowResult<Data> = Future<Stream<DataResult<Data>>>;
