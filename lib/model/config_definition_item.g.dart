// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_definition_item.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ConfigDefinitionItem> _$configDefinitionItemSerializer =
    new _$ConfigDefinitionItemSerializer();

class _$ConfigDefinitionItemSerializer
    implements StructuredSerializer<ConfigDefinitionItem> {
  @override
  final Iterable<Type> types = const [
    ConfigDefinitionItem,
    _$ConfigDefinitionItem
  ];
  @override
  final String wireName = 'ConfigDefinitionItem';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, ConfigDefinitionItem object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'name',
      serializers.serialize(object.name, specifiedType: const FullType(String)),
      'editable',
      serializers.serialize(object.editable,
          specifiedType: const FullType(bool)),
      'type',
      serializers.serialize(object.type,
          specifiedType: const FullType(ItemType)),
      'label',
      serializers.serialize(object.label,
          specifiedType: const FullType(String)),
      'unit',
      serializers.serialize(object.unit, specifiedType: const FullType(String)),
      'value',
      serializers.serialize(object.value,
          specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  ConfigDefinitionItem deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ConfigDefinitionItemBuilder();

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
        case 'editable':
          result.editable = serializers.deserialize(value,
              specifiedType: const FullType(bool))! as bool;
          break;
        case 'type':
          result.type.replace(serializers.deserialize(value,
              specifiedType: const FullType(ItemType))! as ItemType);
          break;
        case 'label':
          result.label = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'unit':
          result.unit = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'value':
          result.value = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
      }
    }

    return result.build();
  }
}

class _$ConfigDefinitionItem extends ConfigDefinitionItem {
  @override
  final String name;
  @override
  final bool editable;
  @override
  final ItemType type;
  @override
  final String label;
  @override
  final String unit;
  @override
  final String value;

  factory _$ConfigDefinitionItem(
          [void Function(ConfigDefinitionItemBuilder)? updates]) =>
      (new ConfigDefinitionItemBuilder()..update(updates))._build();

  _$ConfigDefinitionItem._(
      {required this.name,
      required this.editable,
      required this.type,
      required this.label,
      required this.unit,
      required this.value})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        name, r'ConfigDefinitionItem', 'name');
    BuiltValueNullFieldError.checkNotNull(
        editable, r'ConfigDefinitionItem', 'editable');
    BuiltValueNullFieldError.checkNotNull(
        type, r'ConfigDefinitionItem', 'type');
    BuiltValueNullFieldError.checkNotNull(
        label, r'ConfigDefinitionItem', 'label');
    BuiltValueNullFieldError.checkNotNull(
        unit, r'ConfigDefinitionItem', 'unit');
    BuiltValueNullFieldError.checkNotNull(
        value, r'ConfigDefinitionItem', 'value');
  }

  @override
  ConfigDefinitionItem rebuild(
          void Function(ConfigDefinitionItemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConfigDefinitionItemBuilder toBuilder() =>
      new ConfigDefinitionItemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ConfigDefinitionItem &&
        name == other.name &&
        editable == other.editable &&
        type == other.type &&
        label == other.label &&
        unit == other.unit &&
        value == other.value;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, editable.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, label.hashCode);
    _$hash = $jc(_$hash, unit.hashCode);
    _$hash = $jc(_$hash, value.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ConfigDefinitionItem')
          ..add('name', name)
          ..add('editable', editable)
          ..add('type', type)
          ..add('label', label)
          ..add('unit', unit)
          ..add('value', value))
        .toString();
  }
}

class ConfigDefinitionItemBuilder
    implements Builder<ConfigDefinitionItem, ConfigDefinitionItemBuilder> {
  _$ConfigDefinitionItem? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  bool? _editable;
  bool? get editable => _$this._editable;
  set editable(bool? editable) => _$this._editable = editable;

  ItemTypeBuilder? _type;
  ItemTypeBuilder get type => _$this._type ??= new ItemTypeBuilder();
  set type(ItemTypeBuilder? type) => _$this._type = type;

  String? _label;
  String? get label => _$this._label;
  set label(String? label) => _$this._label = label;

  String? _unit;
  String? get unit => _$this._unit;
  set unit(String? unit) => _$this._unit = unit;

  String? _value;
  String? get value => _$this._value;
  set value(String? value) => _$this._value = value;

  ConfigDefinitionItemBuilder();

  ConfigDefinitionItemBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _editable = $v.editable;
      _type = $v.type.toBuilder();
      _label = $v.label;
      _unit = $v.unit;
      _value = $v.value;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ConfigDefinitionItem other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ConfigDefinitionItem;
  }

  @override
  void update(void Function(ConfigDefinitionItemBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ConfigDefinitionItem build() => _build();

  _$ConfigDefinitionItem _build() {
    ConfigDefinitionItem._finalizeBuilder(this);
    _$ConfigDefinitionItem _$result;
    try {
      _$result = _$v ??
          new _$ConfigDefinitionItem._(
              name: BuiltValueNullFieldError.checkNotNull(
                  name, r'ConfigDefinitionItem', 'name'),
              editable: BuiltValueNullFieldError.checkNotNull(
                  editable, r'ConfigDefinitionItem', 'editable'),
              type: type.build(),
              label: BuiltValueNullFieldError.checkNotNull(
                  label, r'ConfigDefinitionItem', 'label'),
              unit: BuiltValueNullFieldError.checkNotNull(
                  unit, r'ConfigDefinitionItem', 'unit'),
              value: BuiltValueNullFieldError.checkNotNull(
                  value, r'ConfigDefinitionItem', 'value'));
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'type';
        type.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'ConfigDefinitionItem', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
