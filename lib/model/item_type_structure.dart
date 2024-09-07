import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:roonmatrix/model/serializers.dart';

part 'item_type_structure.g.dart';

abstract class ItemTypeStructure
    implements Built<ItemTypeStructure, ItemTypeStructureBuilder> {
  String get name;
  String get type;

  ItemTypeStructure._();
  factory ItemTypeStructure([void Function(ItemTypeStructureBuilder) updates]) =
      _$ItemTypeStructure;

  // DEFAULTS
  static void _finalizeBuilder(ItemTypeStructureBuilder b) {
    b.name ??= '';
    b.type ??= '';
  }

  Map<String, dynamic> toJson() {
    return serializers.serializeWith(ItemTypeStructure.serializer, this)
        as Map<String, dynamic>;
  }

  static ItemTypeStructure fromJson(Map<String, dynamic> json) {
    return serializers.deserializeWith(ItemTypeStructure.serializer, json)
        as ItemTypeStructure;
  }

  static Serializer<ItemTypeStructure> get serializer =>
      _$itemTypeStructureSerializer;
}
