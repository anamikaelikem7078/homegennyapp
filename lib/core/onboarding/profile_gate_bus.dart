import 'dart:async';

/// Fires when any API call is refused with 403 `PROFILE_INCOMPLETE`, carrying
/// the server's `missing` list. A plain singleton for the same reason as
/// `SessionEventBus`: the Dio interceptor that reports it sits underneath the
/// providers that react to it.
class ProfileGateBus {
  ProfileGateBus._();
  static final ProfileGateBus instance = ProfileGateBus._();

  final _controller = StreamController<List<String>>.broadcast();

  Stream<List<String>> get onProfileIncomplete => _controller.stream;

  void notifyProfileIncomplete(List<String> missing) => _controller.add(missing);
}
