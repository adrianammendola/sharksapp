import 'package:hive/hive.dart';

class CustomStatConfig {
  final String id;
  final String name;

  CustomStatConfig({required this.id, required this.name});
}

// Adaptador manual para Hive
class CustomStatConfigAdapter extends TypeAdapter<CustomStatConfig> {
  @override
  final int typeId = 10;

  @override
  CustomStatConfig read(BinaryReader reader) {
    return CustomStatConfig(
      id: reader.read(),
      name: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, CustomStatConfig obj) {
    writer.write(obj.id);
    writer.write(obj.name);
  }
}