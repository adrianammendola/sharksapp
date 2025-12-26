import 'package:hive_flutter/hive_flutter.dart';

class CustomStatsService {
  static const _customStatsBoxName = 'customStats';

  Future<Box<String>> _openBox() async {
    return await Hive.openBox<String>(_customStatsBoxName);
  }

  Future<List<String>> getCustomStats() async {
    final box = await _openBox();
    return box.values.toList();
  }

  Future<void> addCustomStat(String statName) async {
    final box = await _openBox();
    await box.add(statName);
  }

  Future<void> deleteCustomStat(String statName) async {
    final box = await _openBox();
    final key = box.keys.firstWhere((key) => box.get(key) == statName, orElse: () => null);
    if (key != null) {
      await box.delete(key);
    }
  }

    Future<void> editCustomStat(String oldName, String newName) async {
    final box = await _openBox();
    final key = box.keys.firstWhere((key) => box.get(key) == oldName, orElse: () => null);
    if (key != null) {
      await box.put(key, newName);
    }
  }
}
