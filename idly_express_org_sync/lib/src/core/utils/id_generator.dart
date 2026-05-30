import 'dart:math';

class IdGenerator {
  static final Random _random = Random.secure();

  static String uuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final values = bytes.map(hex).toList();

    return '${values.sublist(0, 4).join()}${values.sublist(4, 6).join()}-'
        '${values.sublist(6, 8).join()}-'
        '${values.sublist(8, 10).join()}-'
        '${values.sublist(10, 12).join()}-'
        '${values.sublist(12, 16).join()}';
  }
}