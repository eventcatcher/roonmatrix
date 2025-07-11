// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ItemType> _$itemTypeSerializer = _$ItemTypeSerializer();

class _$ItemTypeSerializer implements StructuredSerializer<ItemType> {
  @override
  final Iterable<Type> types = const [ItemType, _$ItemType];
  @override
  final String wireName = 'ItemType';

  @override
  Iterable<Object?> serialize(Serializers serializers, ItemType object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'type',
      serializers.serialize(object.type, specifiedType: const FullType(String)),
      'structure',
      serializers.serialize(object.structure,
          specifiedType: const FullType(
              BuiltList, const [const FullType(ItemTypeStructure)])),
    ];

    return result;
  }

  @override
  ItemType deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = ItemTypeBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'type':
          result.type = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'structure':
          result.structure.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(ItemTypeStructure)]))!
              as BuiltList<Object?>);
          break;
      }
    }

    return result.build();
  }
}

class _$ItemType extends ItemType {
  @override
  final String type;
  @override
  final BuiltList<ItemTypeStructure> structure;

  factory _$ItemType([void Function(ItemTypeBuilder)? updates]) =>
      (ItemTypeBuilder()..update(updates))._build();

  _$ItemType._({required this.type, required this.structure}) : super._();
  @override
  ItemType rebuild(void Function(ItemTypeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ItemTypeBuilder toBuilder() => ItemTypeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ItemType &&
        type == other.type &&
        structure == other.structure;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, structure.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ItemType')
          ..add('type', type)
          ..add('structure', structure))
        .toString();
  }
}

class ItemTypeBuilder implements Builder<ItemType, ItemTypeBuilder> {
  _$ItemType? _$v;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  ListBuilder<ItemTypeStructure>? _structure;
  ListBuilder<ItemTypeStructure> get structure =>
      _$this._structure ??= ListBuilder<ItemTypeStructure>();
  set structure(ListBuilder<ItemTypeStructure>? structure) =>
      _$this._structure = structure;

  ItemTypeBuilder();

  ItemTypeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _type = $v.type;
      _structure = $v.structure.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ItemType other) {
    _$v = other as _$ItemType;
  }

  @override
  void update(void Function(ItemTypeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ItemType build() => _build();

  _$ItemType _build() {
    ItemType._finalizeBuilder(this);
    _$ItemType _$result;
    try {
      _$result = _$v ??
          _$ItemType._(
            type: BuiltValueNullFieldError.checkNotNull(
                type, r'ItemType', 'type'),
            structure: structure.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'structure';
        structure.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ItemType', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
