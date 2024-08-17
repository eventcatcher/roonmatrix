import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:roonmatrix/model/serializers.dart';

part 'storage_folder_type.g.dart';

class StorageFolderType extends EnumClass {
  // ignore:constant_identifier_names
  static const StorageFolderType APP = _$app;
  // ignore:constant_identifier_names
  static const StorageFolderType TEMP = _$temp;
  // ignore:constant_identifier_names
  static const StorageFolderType EXTERNAL = _$external;

  const StorageFolderType._(super.name);

  static BuiltSet<StorageFolderType> get values => _$storageFolderTypeValues;
  static StorageFolderType valueOf(String name) =>
      _$storageFolderTypeValueOf(name);

  String serialize() {
    return serializers.serializeWith(StorageFolderType.serializer, this)
        as String;
  }

  static StorageFolderType deserialize(String string) {
    return serializers.deserializeWith(StorageFolderType.serializer, string)
        as StorageFolderType;
  }

  static Serializer<StorageFolderType> get serializer =>
      _$storageFolderTypeSerializer;
}
