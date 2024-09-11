import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:roonmatrix/model/item_type.dart';
import 'package:roonmatrix/model/serializers.dart';

part 'config_definition_item.g.dart';

abstract class ConfigDefinitionItem
    implements Built<ConfigDefinitionItem, ConfigDefinitionItemBuilder> {
  String get name;
  bool get editable;
  ItemType get type;
  String get label;
  String get unit;
  String get value;
  String get link;

  ConfigDefinitionItem._();
  factory ConfigDefinitionItem(
          [void Function(ConfigDefinitionItemBuilder) updates]) =
      _$ConfigDefinitionItem;

  // DEFAULTS
  static void _finalizeBuilder(ConfigDefinitionItemBuilder b) {
    b.editable ??= false;
    b.label ??= '';
    b.unit ??= '';
    b.value ??= '';
    b.link ??= '';
  }

  Map<String, dynamic> toJson() {
    return serializers.serializeWith(ConfigDefinitionItem.serializer, this)
        as Map<String, dynamic>;
  }

  static ConfigDefinitionItem fromJson(Map<String, dynamic> json) {
    return serializers.deserializeWith(ConfigDefinitionItem.serializer, json)
        as ConfigDefinitionItem;
  }

  static Serializer<ConfigDefinitionItem> get serializer =>
      _$configDefinitionItemSerializer;
}
