import 'dart:async';

/// Fires when the network layer detects the session is no longer valid (a
/// 401 that couldn't be silently refreshed). Deliberately a plain singleton
/// with no Riverpod provider of its own: `AuthInterceptor` sits underneath
/// `authProvider` in the DI graph (auth state -> auth repository -> API
/// service -> Dio client -> auth interceptor), so wiring the interceptor
/// straight to `authProvider` (e.g. via `ref.read(authProvider.notifier)`
/// captured in a provider closure) closes that graph into a cycle and Dart
/// fails to compile it ("circularity found during type inference"). Both
/// sides depending on this dependency-free bus instead avoids the cycle.
class SessionEventBus {
  SessionEventBus._();
  static final SessionEventBus instance = SessionEventBus._();

  final _controller = StreamController<void>.broadcast();

  Stream<void> get onSessionExpired => _controller.stream;

  void notifySessionExpired() => _controller.add(null);
}
