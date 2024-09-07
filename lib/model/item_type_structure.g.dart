// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_type_structure.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ItemTypeStructure> _$itemTypeStructureSerializer =
    new _$ItemTypeStructureSerializer();

class _$ItemTypeStructureSerializer
    implements StructuredSerializer<ItemTypeStructure> {
  @override
  final Iterable<Type> types = const [ItemTypeStructure, _$ItemTypeStructure];
  @override
  final String wireName = 'ItemTypeStructure';

  @override
  Iterable<Object?> serialize(Serializers serializers, ItemTypeStructure object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'name',
      serializers.serialize(object.name, specifiedType: const FullType(String)),
      'type',
      serializers.serialize(object.type, specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  ItemTypeStructure deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ItemTypeStructureBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'type':
          result.type = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
      }
    }

    return result.build();
  }
}

class _$ItemTypeStructure extends ItemTypeStructure {
  @override
  final String name;
  @override
  final String type;

  factory _$ItemTypeStructure(
          [void Function(ItemTypeStructureBuilder)? updates]) =>
      (new ItemTypeStructureBuilder()..update(updates))._build();

  _$ItemTypeStructure._({required this.name, required this.type}) : super._() {
    BuiltValueNullFieldError.checkNotNull(name, r'ItemTypeStructure', 'name');
    BuiltValueNullFieldError.checkNotNull(type, r'ItemTypeStructure', 'type');
  }

  @override
  ItemTypeStructure rebuild(void Function(ItemTypeStructureBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ItemTypeStructureBuilder toBuilder() =>
      new ItemTypeStructureBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ItemTypeStructure &&
        name == other.name &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ItemTypeStructure')
          ..add('name', name)
          ..add('type', type))
        .toString();
  }
}

class ItemTypeStructureBuilder
    implements Builder<ItemTypeStructure, ItemTypeStructureBuilder> {
  _$ItemTypeStructure? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  ItemTypeStructureBuilder();

  ItemTypeStructureBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ItemTypeStructure other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ItemTypeStructure;
  }

  @override
  void update(void Function(ItemTypeStructureBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ItemTypeStructure build() => _build();

  _$ItemTypeStructure _build() {
    ItemTypeStructure._finalizeBuilder(this);
    final _$result = _$v ??
        new _$ItemTypeStructure._(
            name: BuiltValueNullFieldError.checkNotNull(
                name, r'ItemTypeStructure', 'name'),
            type: BuiltValueNullFieldError.checkNotNull(
                type, r'ItemTypeStructure', 'type'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
