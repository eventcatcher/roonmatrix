import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:roonmatrix/model/serializers.dart';

part 'shortcut.g.dart';

abstract class Shortcut implements Built<Shortcut, ShortcutBuilder> {
  String get key;
  bool get control;
  bool get shift;
  bool get alt;
  bool get meta;

  Shortcut._();
  factory Shortcut([void Function(ShortcutBuilder) updates]) = _$Shortcut;

  // DEFAULTS
  static void _finalizeBuilder(ShortcutBuilder b) {
    b.key ??= '';
    b.control ??= false;
    b.shift ??= false;
    b.alt ??= false;
    b.meta ??= false;
  }

  Map<String, dynamic> toJson() {
    return serializers.serializeWith(Shortcut.serializer, this)
        as Map<String, dynamic>;
  }

  static Shortcut fromJson(Map<String, dynamic> json) {
    return serializers.deserializeWith(Shortcut.serializer, json) as Shortcut;
  }

  static Serializer<Shortcut> get serializer => _$shortcutSerializer;
}
