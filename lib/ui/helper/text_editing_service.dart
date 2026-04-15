import 'package:flutter/widgets.dart';

class TextEditingService {
  static final TextEditingService instance = TextEditingService._();

  TextEditingService._();

  EditableTextState? _editable;
  UndoHistoryController? _undoController;

  void init() {
    FocusManager.instance.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    final focus = FocusManager.instance.primaryFocus;
    final context = focus?.context;

    final editable = context?.findAncestorStateOfType<EditableTextState>();

    if (editable != null) {
      _editable = editable;

      final widget = editable.widget;
      _undoController = widget.undoController;
    }
  }

  // ===== Actions =====

  void copy() {
    _editable?.copySelection(SelectionChangedCause.toolbar);
  }

  void cut() {
    _editable?.cutSelection(SelectionChangedCause.toolbar);
  }

  void paste() {
    //_editable?.requestFocus();
    _editable?.pasteText(SelectionChangedCause.toolbar);
  }

  void selectAll() {
    _editable?.selectAll(SelectionChangedCause.toolbar);
  }

  void undo() {
    _undoController?.undo();
  }

  void redo() {
    _undoController?.redo();
  }

  // ===== State (für Menü-Enable/Disable) =====

  bool get hasFocus => _editable != null;

  bool get canUndo => _undoController?.value.canUndo ?? false;

  bool get canRedo => _undoController?.value.canRedo ?? false;

  bool get hasSelection {
    final selection = _editable?.textEditingValue.selection;
    return selection != null && !selection.isCollapsed;
  }
}
