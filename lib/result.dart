// Generic Result type for operations that can fail
// Similar to Either or Result types in other languages
sealed class Result<T> {
  const Result();
}

// Success case with value
class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  String toString() => 'Success($value)';
}

// Failure case with error
class Failure<T> extends Result<T> {
  final String error;
  final Exception? exception;

  const Failure(this.error, [this.exception]);

  @override
  String toString() => 'Failure($error)';
}

// Extension methods for Result
extension ResultExtension<T> on Result<T> {
  // Check if result is success
  bool get isSuccess => this is Success<T>;

  // Check if result is failure
  bool get isFailure => this is Failure<T>;

  // Get value or null
  T? get valueOrNull {
    return switch (this) {
      Success(:final value) => value,
      Failure() => null,
    };
  }

  // Get value or default
  T valueOr(T defaultValue) {
    return switch (this) {
      Success(:final value) => value,
      Failure() => defaultValue,
    };
  }

  // Map success value to new type
  Result<R> map<R>(R Function(T) transform) {
    return switch (this) {
      Success(:final value) => Success(transform(value)),
      Failure(:final error, :final exception) => Failure(error, exception),
    };
  }

  // Execute action on success
  void onSuccess(void Function(T) action) {
    if (this case Success(:final value)) {
      action(value);
    }
  }

  // Execute action on failure
  void onFailure(void Function(String) action) {
    if (this case Failure(:final error)) {
      action(error);
    }
  }
}
