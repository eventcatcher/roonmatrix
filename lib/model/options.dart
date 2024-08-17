import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:roonmatrix/model/serializers.dart';

part 'options.g.dart';

abstract class Options implements Built<Options, OptionsBuilder> {
  bool get polling;

  Options._();
  factory Options([void Function(OptionsBuilder) updates]) = _$Options;

  // DEFAULTS
  static void _finalizeBuilder(OptionsBuilder b) {
    b.polling ??= true;
  }

  Map<String, dynamic> toJson() {
    return serializers.serializeWith(Options.serializer, this)
        as Map<String, dynamic>;
  }

  static Options fromJson(Map<String, dynamic> json) {
    return serializers.deserializeWith(Options.serializer, json) as Options;
  }

  static Serializer<Options> get serializer => _$optionsSerializer;
}
