import 'package:hive/hive.dart';

part 'partido_dobles.g.dart';

@HiveType(typeId: 2)
class PartidoDobles extends HiveObject {
  @HiveField(0)
  List<String> equipo1;

  @HiveField(1)
  List<String> equipo2;

  @HiveField(2)
  List<int> setsEquipo1;

  @HiveField(3)
  List<int> setsEquipo2;

  @HiveField(4)
  DateTime fecha;

  PartidoDobles({
    required this.equipo1,
    required this.equipo2,
    required this.setsEquipo1,
    required this.setsEquipo2,
    required this.fecha,
  });

  int setsGanadosEquipo1() {
    int count = 0;
    for (int i = 0; i < setsEquipo1.length; i++) {
      if (setsEquipo1[i] > setsEquipo2[i]) count++;
    }
    return count;
  }

  int setsGanadosEquipo2() {
    int count = 0;
    for (int i = 0; i < setsEquipo2.length; i++) {
      if (setsEquipo2[i] > setsEquipo1[i]) count++;
    }
    return count;
  }

  String ganador() {
    final ganados1 = setsGanadosEquipo1();
    final ganados2 = setsGanadosEquipo2();
    if (ganados1 > ganados2) return equipo1.join(', ');
    if (ganados2 > ganados1) return equipo2.join(', ');
    return 'Empate';
  }
}
