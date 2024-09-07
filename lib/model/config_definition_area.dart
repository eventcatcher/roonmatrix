import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:roonmatrix/model/config_definition_item.dart';
import 'package:roonmatrix/model/serializers.dart';

part 'config_definition_area.g.dart';

abstract class ConfigDefinitionArea
    implements Built<ConfigDefinitionArea, ConfigDefinitionAreaBuilder> {
  String get name;
  BuiltList<ConfigDefinitionItem> get items;

  ConfigDefinitionArea._();
  factory ConfigDefinitionArea(
          [void Function(ConfigDefinitionAreaBuilder) updates]) =
      _$ConfigDefinitionArea;

  Map<String, dynamic> toJson() {
    return serializers.serializeWith(ConfigDefinitionArea.serializer, this)
        as Map<String, dynamic>;
  }

  static ConfigDefinitionArea fromJson(Map<String, dynamic> json) {
    return serializers.deserializeWith(ConfigDefinitionArea.serializer, json)
        as ConfigDefinitionArea;
  }

  static Serializer<ConfigDefinitionArea> get serializer =>
      _$configDefinitionAreaSerializer;
}
