// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'options.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Options> _$optionsSerializer = new _$OptionsSerializer();

class _$OptionsSerializer implements StructuredSerializer<Options> {
  @override
  final Iterable<Type> types = const [Options, _$Options];
  @override
  final String wireName = 'Options';

  @override
  Iterable<Object?> serialize(Serializers serializers, Options object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'polling',
      serializers.serialize(object.polling,
          specifiedType: const FullType(bool)),
    ];

    return result;
  }

  @override
  Options deserialize(Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new OptionsBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'polling':
          result.polling = serializers.deserialize(value,
              specifiedType: const FullType(bool))! as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$Options extends Options {
  @override
  final bool polling;

  factory _$Options([void Function(OptionsBuilder)? updates]) =>
      (new OptionsBuilder()..update(updates))._build();

  _$Options._({required this.polling}) : super._() {
    BuiltValueNullFieldError.checkNotNull(polling, r'Options', 'polling');
  }

  @override
  Options rebuild(void Function(OptionsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OptionsBuilder toBuilder() => new OptionsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Options && polling == other.polling;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, polling.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Options')..add('polling', polling))
        .toString();
  }
}

class OptionsBuilder implements Builder<Options, OptionsBuilder> {
  _$Options? _$v;

  bool? _polling;
  bool? get polling => _$this._polling;
  set polling(bool? polling) => _$this._polling = polling;

  OptionsBuilder();

  OptionsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _polling = $v.polling;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Options other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$Options;
  }

  @override
  void update(void Function(OptionsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Options build() => _build();

  _$Options _build() {
    Options._finalizeBuilder(this);
    final _$result = _$v ??
        new _$Options._(
            polling: BuiltValueNullFieldError.checkNotNull(
                polling, r'Options', 'polling'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
