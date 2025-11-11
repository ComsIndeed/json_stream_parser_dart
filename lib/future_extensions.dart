import 'dart:async';

extension FutureTimeout<T> on Future<T> {
  Future<T> withTestTimeout([Duration timeout = const Duration(seconds: 5)]) {
    return this.timeout(
      timeout,
      onTimeout: () =>
          throw TimeoutException('Future timed out after $timeout'),
    );
  }
}
