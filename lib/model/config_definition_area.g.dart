// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_definition_area.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ConfigDefinitionArea> _$configDefinitionAreaSerializer =
    _$ConfigDefinitionAreaSerializer();

class _$ConfigDefinitionAreaSerializer
    implements StructuredSerializer<ConfigDefinitionArea> {
  @override
  final Iterable<Type> types = const [
    ConfigDefinitionArea,
    _$ConfigDefinitionArea
  ];
  @override
  final String wireName = 'ConfigDefinitionArea';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, ConfigDefinitionArea object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'name',
      serializers.serialize(object.name, specifiedType: const FullType(String)),
      'items',
      serializers.serialize(object.items,
          specifiedType: const FullType(
              BuiltList, const [const FullType(ConfigDefinitionItem)])),
    ];

    return result;
  }

  @override
  ConfigDefinitionArea deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = ConfigDefinitionAreaBuilder();

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
        case 'items':
          result.items.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(ConfigDefinitionItem)]))!
              as BuiltList<Object?>);
          break;
      }
    }

    return result.build();
  }
}

class _$ConfigDefinitionArea extends ConfigDefinitionArea {
  @override
  final String name;
  @override
  final BuiltList<ConfigDefinitionItem> items;

  factory _$ConfigDefinitionArea(
          [void Function(ConfigDefinitionAreaBuilder)? updates]) =>
      (ConfigDefinitionAreaBuilder()..update(updates))._build();

  _$ConfigDefinitionArea._({required this.name, required this.items})
      : super._();
  @override
  ConfigDefinitionArea rebuild(
          void Function(ConfigDefinitionAreaBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConfigDefinitionAreaBuilder toBuilder() =>
      ConfigDefinitionAreaBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ConfigDefinitionArea &&
        name == other.name &&
        items == other.items;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ConfigDefinitionArea')
          ..add('name', name)
          ..add('items', items))
        .toString();
  }
}

class ConfigDefinitionAreaBuilder
    implements Builder<ConfigDefinitionArea, ConfigDefinitionAreaBuilder> {
  _$ConfigDefinitionArea? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  ListBuilder<ConfigDefinitionItem>? _items;
  ListBuilder<ConfigDefinitionItem> get items =>
      _$this._items ??= ListBuilder<ConfigDefinitionItem>();
  set items(ListBuilder<ConfigDefinitionItem>? items) => _$this._items = items;

  ConfigDefinitionAreaBuilder();

  ConfigDefinitionAreaBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ConfigDefinitionArea other) {
    _$v = other as _$ConfigDefinitionArea;
  }

  @override
  void update(void Function(ConfigDefinitionAreaBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ConfigDefinitionArea build() => _build();

  _$ConfigDefinitionArea _build() {
    _$ConfigDefinitionArea _$result;
    try {
      _$result = _$v ??
          _$ConfigDefinitionArea._(
            name: BuiltValueNullFieldError.checkNotNull(
                name, r'ConfigDefinitionArea', 'name'),
            items: items.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ConfigDefinitionArea', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
