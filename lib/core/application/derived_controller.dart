import 'dart:async';

import 'package:flutter/foundation.dart';

/// A controller whose state is derived from one or more repositories:
/// any change in a source invalidates the cached state and notifies.
abstract class DerivedController<S> extends ChangeNotifier {
  DerivedController(this._sources) {
    for (final source in _sources) {
      source.addListener(_invalidate);
    }
  }

  final List<Listenable> _sources;
  S? _cached;

  /// Recomputes the state from the sources.
  @protected
  S build();

  S get state => _cached ??= build();

  @protected
  void invalidate() => _invalidate();

  void _invalidate() {
    _cached = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final source in _sources) {
      source.removeListener(_invalidate);
    }
    super.dispose();
  }
}

/// One-shot UI message (snackbar) emitted by a controller.
@immutable
class UiMessage {
  const UiMessage(this.key, {this.args = const [], this.canUndo = false});

  final String key;
  final List<Object?> args;
  final bool canUndo;
}

mixin UiMessages on ChangeNotifier {
  final _messages = StreamController<UiMessage>.broadcast();

  Stream<UiMessage> get messages => _messages.stream;

  @protected
  void emit(UiMessage message) {
    if (!_messages.isClosed) {
      _messages.add(message);
    }
  }

  @override
  void dispose() {
    _messages.close();
    super.dispose();
  }
}
