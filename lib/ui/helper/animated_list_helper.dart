import 'package:flutter/material.dart';

class AnimatedListHelper {
  /// insert item with animation
  static void insertItem<T>({
    required GlobalKey<AnimatedListState> listKey,
    required List<T> itemList,
    required int index,
    required T newItem,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    if (index < 0 || index > itemList.length) return;

    itemList.insert(index, newItem);

    listKey.currentState?.insertItem(
      index,
      duration: duration,
    );
  }

  /// remove item with animation
  static void removeItem<T>({
    required GlobalKey<AnimatedListState> listKey,
    required List<T> itemList,
    required int index,
    required Widget Function(T item, Animation<double> animation) buildItem,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    if (index < 0 || index >= itemList.length) return;

    final removedItem = itemList[index];

    listKey.currentState?.removeItem(
      index,
      (context, animation) => buildItem(removedItem, animation),
      duration: duration,
    );

    itemList.removeAt(index);
  }

  /// insert multiple items one after the other with animation
  static void insertMultipleAnimatedItems<T>({
    required GlobalKey<AnimatedListState> listKey,
    required List<T> itemList,
    required int startIndex,
    required List<T> newItems,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    if (startIndex < 0 || startIndex > itemList.length) return;

    for (int i = 0; i < newItems.length; i++) {
      final insertIndex = startIndex + i;
      itemList.insert(insertIndex, newItems[i]);

      listKey.currentState?.insertItem(
        insertIndex,
        duration: duration,
      );
    }
  }

  /// remove multiple items one after the other with animation
  static void removeMultipleAnimatedItems<T>({
    required GlobalKey<AnimatedListState> listKey,
    required List<T> itemList,
    required List<int> indexesToRemove,
    required Widget Function(T item, Animation<double> animation) buildItem,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    // Sort indexes (delete from back to front)
    indexesToRemove.sort((a, b) => b.compareTo(a));

    for (final index in indexesToRemove) {
      if (index >= 0 && index < itemList.length) {
        final removedItem = itemList[index];

        listKey.currentState?.removeItem(
          index,
          (context, animation) => buildItem(removedItem, animation),
          duration: duration,
        );

        itemList.removeAt(index);
      }
    }
  }
}
