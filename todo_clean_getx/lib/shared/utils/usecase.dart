import 'package:dartz/dartz.dart';
import 'package:todo_clean_getx/shared/errors/failure.dart';

abstract class UseCase<T, H> {
  Future<Either<Failure, T>> call(H object);
}

class Params<T> {
  final T data;
  Params(this.data);
}

class NoParams {
  final void data;
  NoParams(this.data);
}
