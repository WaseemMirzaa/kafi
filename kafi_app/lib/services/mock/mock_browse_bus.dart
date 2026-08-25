import 'dart:async';

/// Shared bus so mock nanny create/approve notifies the family browse watch.
class MockBrowseBus {
  MockBrowseBus._();

  static final _controller = StreamController<void>.broadcast();

  static Stream<void> get stream => _controller.stream;

  static void notify() {
    if (!_controller.isClosed) _controller.add(null);
  }
}
