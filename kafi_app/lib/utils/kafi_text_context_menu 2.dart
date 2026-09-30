import 'package:flutter/material.dart';

/// Flutter-drawn text selection toolbar for [TextField]s.
///
/// iOS [TextField] defaults to [SystemContextMenu], which asserts when there is
/// no active [TextInputConnection] (common in modal sheets during autofocus /
/// rebuild). Prefer this builder so Select Location and other sheets stay
/// stable.
Widget kafiEditableTextContextMenu(
  BuildContext context,
  EditableTextState editableTextState,
) {
  final items = editableTextState.contextMenuButtonItems;
  if (items.isEmpty) return const SizedBox.shrink();
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: items,
  );
}

/// No-op context menu — use on search fields in modal sheets where selection
/// menus are unnecessary and SystemContextMenu is crash-prone.
Widget kafiNoTextContextMenu(
  BuildContext context,
  EditableTextState editableTextState,
) =>
    const SizedBox.shrink();
