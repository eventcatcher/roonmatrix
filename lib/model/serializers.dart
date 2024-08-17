import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:roonmatrix/data/storage_folder_type.dart';
import 'package:roonmatrix/model/options.dart';
import 'package:roonmatrix/model/shortcut.dart';

part 'serializers.g.dart';

@SerializersFor([
  Options,
  Shortcut,
  StorageFolderType,
])
final Serializers serializers =
    (_$serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
