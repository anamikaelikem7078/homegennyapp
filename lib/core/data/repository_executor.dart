import '../config/app_config.dart';
import '../exceptions/exception_handler.dart';
import '../exceptions/failures.dart';
import '../network/network_info.dart';
import '../utils/result.dart';

/// Orchestrates remote → cache → local → dummy fallback for repositories.
class RepositoryExecutor {
  RepositoryExecutor({
    required NetworkInfo networkInfo,
    bool? useDummyApi,
    bool? enableOfflineCache,
  })  : _networkInfo = networkInfo,
        _useDummyApi = useDummyApi ?? AppConfig.useDummyApi,
        _enableOfflineCache = enableOfflineCache ?? AppConfig.enableOfflineCache;

  final NetworkInfo _networkInfo;
  final bool _useDummyApi;
  final bool _enableOfflineCache;

  /// Fetch data with offline-first cache strategy.
  Future<Result<T>> fetch<T>({
    Future<T> Function()? remote,
    Future<void> Function(T data)? cache,
    Future<T?> Function()? local,
    Future<T> Function()? dummy,
  }) async {
    try {
      if (_useDummyApi && dummy != null) {
        return Success(await dummy());
      }

      final connected = await _networkInfo.isConnected;
      if (connected && remote != null) {
        try {
          final data = await remote();
          if (_enableOfflineCache && cache != null) {
            await cache(data);
          }
          return Success(data);
        } catch (e, stack) {
          if (_enableOfflineCache && local != null) {
            final cached = await local();
            if (cached != null) return Success(cached);
          }
          return Error(ExceptionHandler.handle(e, stack));
        }
      }

      if (_enableOfflineCache && local != null) {
        final cached = await local();
        if (cached != null) return Success(cached);
      }

      if (dummy != null) return Success(await dummy());
      return const Error(NetworkFailure(message: 'No network connection'));
    } catch (e, stack) {
      return Error(ExceptionHandler.handle(e, stack));
    }
  }

  /// Mutations (POST/PUT/DELETE) — requires network unless dummy mode.
  Future<Result<T>> mutate<T>({
    Future<T> Function()? remote,
    Future<T> Function()? dummy,
  }) async {
    try {
      if (_useDummyApi && dummy != null) {
        return Success(await dummy());
      }
      if (!await _networkInfo.isConnected) {
        return const Error(NetworkFailure(message: 'No network connection'));
      }
      if (remote != null) {
        return Success(await remote());
      }
      if (dummy != null) return Success(await dummy());
      return const Error(NetworkFailure(message: 'No remote handler'));
    } catch (e, stack) {
      return Error(ExceptionHandler.handle(e, stack));
    }
  }

  /// Void mutation helper.
  Future<Result<void>> mutateVoid({
    Future<void> Function()? remote,
    Future<void> Function()? dummy,
  }) =>
      mutate(
        remote: remote != null ? () async { await remote(); return null; } : null,
        dummy: dummy != null ? () async { await dummy(); return null; } : null,
      );
}
