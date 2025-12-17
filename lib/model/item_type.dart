import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:roonmatrix/model/item_type_structure.dart';
import 'package:roonmatrix/model/serializers.dart';

part 'item_type.g.dart';

abstract class ItemType implements Built<ItemType, ItemTypeBuilder> {
  String get type;
  BuiltList<ItemTypeStructure> get structure;
  BuiltMap<String, String>? get options;

  ItemType._();
  factory ItemType([void Function(ItemTypeBuilder) updates]) = _$ItemType;

  // DEFAULTS
  static void _finalizeBuilder(ItemTypeBuilder b) {
    b.type ??= '';
  }

  Map<String, dynamic> toJson() {
    return serializers.serializeWith(ItemType.serializer, this)
        as Map<String, dynamic>;
  }

  static ItemType fromJson(Map<String, dynamic> json) {
    return serializers.deserializeWith(ItemType.serializer, json) as ItemType;
  }

  static Serializer<ItemType> get serializer => _$itemTypeSerializer;
}
