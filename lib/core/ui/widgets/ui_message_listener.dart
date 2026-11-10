import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/application/derived_controller.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';

/// Shows a snackbar for every [UiMessage] emitted by [messages] while this
/// widget is mounted (with an "Undo" action when the message allows it).
class UiMessageListener extends StatefulWidget {
  const UiMessageListener({
    super.key,
    required this.messages,
    required this.child,
    this.onUndo,
  });

  final Stream<UiMessage> messages;
  final Widget child;
  final VoidCallback? onUndo;

  @override
  State<UiMessageListener> createState() => _UiMessageListenerState();
}

class _UiMessageListenerState extends State<UiMessageListener> {
  StreamSubscription<UiMessage>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.messages.listen(_show);
  }

  @override
  void didUpdateWidget(covariant UiMessageListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages != widget.messages) {
      _sub?.cancel();
      _sub = widget.messages.listen(_show);
    }
  }

  void _show(UiMessage message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.tr(message.key, message.args)),
          duration: const Duration(seconds: 6),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          action: message.canUndo && widget.onUndo != null
              ? SnackBarAction(label: context.tr('gro_snackbar_undo'), onPressed: widget.onUndo!)
              : null,
        ),
      );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
