import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:roonmatrix/model/config_definition_area.dart';
import 'package:roonmatrix/model/serializers.dart';

part 'config_definition.g.dart';

abstract class ConfigDefinition
    implements Built<ConfigDefinition, ConfigDefinitionBuilder> {
  BuiltList<ConfigDefinitionArea> get area;

  ConfigDefinition._();
  factory ConfigDefinition([void Function(ConfigDefinitionBuilder) updates]) =
      _$ConfigDefinition;

  Map<String, dynamic> toJson() {
    return serializers.serializeWith(ConfigDefinition.serializer, this)
        as Map<String, dynamic>;
  }

  static ConfigDefinition fromJson(Map<String, dynamic> json) {
    return serializers.deserializeWith(ConfigDefinition.serializer, json)
        as ConfigDefinition;
  }

  static Serializer<ConfigDefinition> get serializer =>
      _$configDefinitionSerializer;
}
