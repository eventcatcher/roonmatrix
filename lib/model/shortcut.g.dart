// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shortcut.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Shortcut> _$shortcutSerializer = _$ShortcutSerializer();

class _$ShortcutSerializer implements StructuredSerializer<Shortcut> {
  @override
  final Iterable<Type> types = const [Shortcut, _$Shortcut];
  @override
  final String wireName = 'Shortcut';

  @override
  Iterable<Object?> serialize(Serializers serializers, Shortcut object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'key',
      serializers.serialize(object.key, specifiedType: const FullType(String)),
      'control',
      serializers.serialize(object.control,
          specifiedType: const FullType(bool)),
      'shift',
      serializers.serialize(object.shift, specifiedType: const FullType(bool)),
      'alt',
      serializers.serialize(object.alt, specifiedType: const FullType(bool)),
      'meta',
      serializers.serialize(object.meta, specifiedType: const FullType(bool)),
    ];

    return result;
  }

  @override
  Shortcut deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = ShortcutBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'key':
          result.key = serializers.deserialize(value,
              specifiedType: const FullType(String))! as String;
          break;
        case 'control':
          result.control = serializers.deserialize(value,
              specifiedType: const FullType(bool))! as bool;
          break;
        case 'shift':
          result.shift = serializers.deserialize(value,
              specifiedType: const FullType(bool))! as bool;
          break;
        case 'alt':
          result.alt = serializers.deserialize(value,
              specifiedType: const FullType(bool))! as bool;
          break;
        case 'meta':
          result.meta = serializers.deserialize(value,
              specifiedType: const FullType(bool))! as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$Shortcut extends Shortcut {
  @override
  final String key;
  @override
  final bool control;
  @override
  final bool shift;
  @override
  final bool alt;
  @override
  final bool meta;

  factory _$Shortcut([void Function(ShortcutBuilder)? updates]) =>
      (ShortcutBuilder()..update(updates))._build();

  _$Shortcut._(
      {required this.key,
      required this.control,
      required this.shift,
      required this.alt,
      required this.meta})
      : super._();
  @override
  Shortcut rebuild(void Function(ShortcutBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ShortcutBuilder toBuilder() => ShortcutBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Shortcut &&
        key == other.key &&
        control == other.control &&
        shift == other.shift &&
        alt == other.alt &&
        meta == other.meta;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, key.hashCode);
    _$hash = $jc(_$hash, control.hashCode);
    _$hash = $jc(_$hash, shift.hashCode);
    _$hash = $jc(_$hash, alt.hashCode);
    _$hash = $jc(_$hash, meta.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Shortcut')
          ..add('key', key)
          ..add('control', control)
          ..add('shift', shift)
          ..add('alt', alt)
          ..add('meta', meta))
        .toString();
  }
}

class ShortcutBuilder implements Builder<Shortcut, ShortcutBuilder> {
  _$Shortcut? _$v;

  String? _key;
  String? get key => _$this._key;
  set key(String? key) => _$this._key = key;

  bool? _control;
  bool? get control => _$this._control;
  set control(bool? control) => _$this._control = control;

  bool? _shift;
  bool? get shift => _$this._shift;
  set shift(bool? shift) => _$this._shift = shift;

  bool? _alt;
  bool? get alt => _$this._alt;
  set alt(bool? alt) => _$this._alt = alt;

  bool? _meta;
  bool? get meta => _$this._meta;
  set meta(bool? meta) => _$this._meta = meta;

  ShortcutBuilder();

  ShortcutBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _key = $v.key;
      _control = $v.control;
      _shift = $v.shift;
      _alt = $v.alt;
      _meta = $v.meta;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Shortcut other) {
    _$v = other as _$Shortcut;
  }

  @override
  void update(void Function(ShortcutBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Shortcut build() => _build();

  _$Shortcut _build() {
    Shortcut._finalizeBuilder(this);
    final _$result = _$v ??
        _$Shortcut._(
          key: BuiltValueNullFieldError.checkNotNull(key, r'Shortcut', 'key'),
          control: BuiltValueNullFieldError.checkNotNull(
              control, r'Shortcut', 'control'),
          shift: BuiltValueNullFieldError.checkNotNull(
              shift, r'Shortcut', 'shift'),
          alt: BuiltValueNullFieldError.checkNotNull(alt, r'Shortcut', 'alt'),
          meta:
              BuiltValueNullFieldError.checkNotNull(meta, r'Shortcut', 'meta'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
