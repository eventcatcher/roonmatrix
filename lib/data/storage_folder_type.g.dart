// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_folder_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const StorageFolderType _$app = const StorageFolderType._('APP');
const StorageFolderType _$temp = const StorageFolderType._('TEMP');
const StorageFolderType _$external = const StorageFolderType._('EXTERNAL');

StorageFolderType _$storageFolderTypeValueOf(String name) {
  switch (name) {
    case 'APP':
      return _$app;
    case 'TEMP':
      return _$temp;
    case 'EXTERNAL':
      return _$external;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<StorageFolderType> _$storageFolderTypeValues =
    BuiltSet<StorageFolderType>(const <StorageFolderType>[
  _$app,
  _$temp,
  _$external,
]);

Serializer<StorageFolderType> _$storageFolderTypeSerializer =
    _$StorageFolderTypeSerializer();

class _$StorageFolderTypeSerializer
    implements PrimitiveSerializer<StorageFolderType> {
  @override
  final Iterable<Type> types = const <Type>[StorageFolderType];
  @override
  final String wireName = 'StorageFolderType';

  @override
  Object serialize(Serializers serializers, StorageFolderType object,
          {FullType specifiedType = FullType.unspecified}) =>
      object.name;

  @override
  StorageFolderType deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      StorageFolderType.valueOf(serialized as String);
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
