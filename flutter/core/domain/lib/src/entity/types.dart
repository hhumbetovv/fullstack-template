import 'package:core_domain/src/entity/failure.dart';
import 'package:core_domain/src/entity/paged.dart';
import 'package:core_domain/src/result/result.dart';
import 'package:core_domain/src/usecase/pagination_usecase.dart';

typedef DataResult<Data> = Result<Data, Failure>;
typedef AsyncResult<Data> = Future<DataResult<Data>>;
typedef PaginationResult<Data> = AsyncResult<Page<Data>>;
typedef PagedResult<Data> = AsyncResult<Paged<Data>>;
typedef FlowResult<Data> = Future<Stream<DataResult<Data>>>;
