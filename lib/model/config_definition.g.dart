// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_definition.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ConfigDefinition> _$configDefinitionSerializer =
    new _$ConfigDefinitionSerializer();

class _$ConfigDefinitionSerializer
    implements StructuredSerializer<ConfigDefinition> {
  @override
  final Iterable<Type> types = const [ConfigDefinition, _$ConfigDefinition];
  @override
  final String wireName = 'ConfigDefinition';

  @override
  Iterable<Object?> serialize(Serializers serializers, ConfigDefinition object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'area',
      serializers.serialize(object.area,
          specifiedType: const FullType(
              BuiltList, const [const FullType(ConfigDefinitionArea)])),
    ];

    return result;
  }

  @override
  ConfigDefinition deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ConfigDefinitionBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'area':
          result.area.replace(serializers.deserialize(value,
                  specifiedType: const FullType(
                      BuiltList, const [const FullType(ConfigDefinitionArea)]))!
              as BuiltList<Object?>);
          break;
      }
    }

    return result.build();
  }
}

class _$ConfigDefinition extends ConfigDefinition {
  @override
  final BuiltList<ConfigDefinitionArea> area;

  factory _$ConfigDefinition(
          [void Function(ConfigDefinitionBuilder)? updates]) =>
      (new ConfigDefinitionBuilder()..update(updates))._build();

  _$ConfigDefinition._({required this.area}) : super._() {
    BuiltValueNullFieldError.checkNotNull(area, r'ConfigDefinition', 'area');
  }

  @override
  ConfigDefinition rebuild(void Function(ConfigDefinitionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConfigDefinitionBuilder toBuilder() =>
      new ConfigDefinitionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ConfigDefinition && area == other.area;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, area.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ConfigDefinition')..add('area', area))
        .toString();
  }
}

class ConfigDefinitionBuilder
    implements Builder<ConfigDefinition, ConfigDefinitionBuilder> {
  _$ConfigDefinition? _$v;

  ListBuilder<ConfigDefinitionArea>? _area;
  ListBuilder<ConfigDefinitionArea> get area =>
      _$this._area ??= new ListBuilder<ConfigDefinitionArea>();
  set area(ListBuilder<ConfigDefinitionArea>? area) => _$this._area = area;

  ConfigDefinitionBuilder();

  ConfigDefinitionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _area = $v.area.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ConfigDefinition other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ConfigDefinition;
  }

  @override
  void update(void Function(ConfigDefinitionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ConfigDefinition build() => _build();

  _$ConfigDefinition _build() {
    _$ConfigDefinition _$result;
    try {
      _$result = _$v ?? new _$ConfigDefinition._(area: area.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'area';
        area.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            r'ConfigDefinition', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
