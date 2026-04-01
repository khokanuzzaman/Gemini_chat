sealed class Either<L, R> {
  const Either();

  T fold<T>(T Function(L value) onLeft, T Function(R value) onRight) {
    return switch (this) {
      Left(:final value) => onLeft(value),
      Right(:final value) => onRight(value),
    };
  }
}

final class Left<L, R> extends Either<L, R> {
  const Left(this.value);

  final L value;
}

final class Right<L, R> extends Either<L, R> {
  const Right(this.value);

  final R value;
}
