import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/helper/cover_transition_preset.dart';

class CoverTransition {
  static AnimatedSwitcherTransitionBuilder presets(
    CoverTransitionPreset preset,
  ) {
    switch (preset) {
      case CoverTransitionPreset.fade:
        return _fade;

      case CoverTransitionPreset.fadeScale:
        return _fadeScale;

      case CoverTransitionPreset.slide:
        return _slide;

      case CoverTransitionPreset.vinylFlip:
        return _vinylFlip;
    }
  }

  // --- Presets ---

  static Widget _fade(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  static Widget _fadeScale(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
        child: child,
      ),
    );
  }

  static Widget _slide(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.15, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  static Widget _vinylFlip(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    );

    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        final value = curved.value;
        final rotation = (1 - value) * 0.5;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(rotation),
          child: FadeTransition(
            opacity: curved,
            child: child,
          ),
        );
      },
    );
  }
}
