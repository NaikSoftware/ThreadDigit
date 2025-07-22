import 'dart:io';

import 'package:flutter/foundation.dart';

class PesThreadColor {
  final String catalog;
  final String code;
  final int red;
  final int green;
  final int blue;

  const PesThreadColor({
    required this.catalog,
    required this.code,
    required this.red,
    required this.green,
    required this.blue,
  });

  @override
  String toString() => 'PesThread($catalog $code: RGB($red,$green,$blue))';
}

class PesReader {
  // Кінець метадани: "CEmbOnes" => [0x43, 0x45, 0x6D, 0x62, 0x4F, 0x6E, 0x65, 0x73].
  static const _endMarker = [0x43, 0x45, 0x6D, 0x62, 0x4F, 0x6E, 0x65, 0x73];

  // Сепаратор, який сигналізує «початок наступного сегмента» (часто рядка каталогів тощо).
  static const _separator = [0xFF, 0xFE, 0xFF];

  /// Основний метод читання кольорів із PES-файлу [filePath].
  static Future<List<PesThreadColor>> readColorSequence(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final colors = _parseColors(bytes);

      debugPrint('Colors found in PES file:');
      for (var color in colors) {
        debugPrint(color.toString());
      }

      return colors;
    } catch (e) {
      debugPrint('Error reading PES file: $e');
      return [];
    }
  }

  /// Парсимо всі нитки (кольори) з [bytes].
  /// Логіка:
  ///  1. Шукаємо 4 wide-char (8 байтів) як код нитки (наприклад "1154").
  ///  2. Читаємо 3 байти (R,G,B).
  ///  3. Пропускаємо «сміття», поки не знайдемо _separator (0xFF, 0xFE, 0xFF) або _endMarker.
  ///  4. Якщо знайшли separator — читаємо назву каталогу (wide-char, доки не наступний separator / endMarker).
  ///  5. Створюємо PesThreadColor і додаємо до списку.
  ///  6. Шукаємо наступний код нитки, повторюємо.
  static List<PesThreadColor> _parseColors(List<int> bytes) {
    final colors = <PesThreadColor>[];
    int position = 0;

    while (true) {
      // Якщо кінець масиву або зустріли "CEmbOnes" => зупиняємо цикл
      if (position >= bytes.length) break;
      if (_isEndMarker(bytes, position)) break;

      // 1) Шукаємо 4 wide-char (код нитки).
      final codeOffset = _findColorCodeOffset(bytes, position);
      if (codeOffset < 0) {
        // Не знайшли більше «колірного коду»
        break;
      }

      position = codeOffset;

      // Перевіримо, чи вистачає 4 wide-char (8 байтів) для коду
      if (position + 7 >= bytes.length) break;
      final code = _readWideString(bytes, position, 4);
      position += 8; // зрушуємося на 8 байтів

      // 2) Перевіряємо, чи вистачає 3 байтів для кольору
      if (position + 2 >= bytes.length) break;
      final red = bytes[position];
      final green = bytes[position + 1];
      final blue = bytes[position + 2];
      position += 3;

      // 3) Пропускаємо всякі службові/невідомі дані, поки не зустрінемо _separator або _endMarker
      while (position < bytes.length) {
        if (_isEndMarker(bytes, position)) {
          // Якщо зустріли кінець — каталог залишимо порожнім (або "")
          break;
        }
        if (_isSeparator(bytes, position)) {
          // Знайшли separator, виходимо, щоб прочитати назву каталогу
          break;
        }
        position++;
      }

      // Якщо кінець або endMarker — зразу формуємо колір (каталог = "")
      if (position >= bytes.length || _isEndMarker(bytes, position)) {
        colors.add(PesThreadColor(
          catalog: "",
          code: code,
          red: red,
          green: green,
          blue: blue,
        ));
        break;
      }

      // 4) Інакше, тут _separator => пропустимо його
      position += 3;

      // 5) Тепер читаємо каталог (catalog) як wide-char, поки не натрапимо на новий _separator або endMarker.
      final catalog = _readWideStringUntilSeparatorOrEnd(bytes, position);
      position += catalog.consumedBytes; // зрушуємось на скільки байтів реально витратили

      // Додаємо до списку:
      colors.add(PesThreadColor(
        catalog: catalog.text.trim(),
        code: code,
        red: red,
        green: green,
        blue: blue,
      ));
    }

    return colors;
  }

  /// Перевірка, чи з позиції [position] починається "CEmbOnes" (кінець блоку кольорів).
  static bool _isEndMarker(List<int> bytes, int position) {
    if (position + _endMarker.length > bytes.length) return false;
    for (int i = 0; i < _endMarker.length; i++) {
      if (bytes[position + i] != _endMarker[i]) return false;
    }
    return true;
  }

  /// Перевірка, чи з позиції [position] починається [0xFF, 0xFE, 0xFF].
  static bool _isSeparator(List<int> bytes, int position) {
    if (position + 2 >= bytes.length) return false;
    return bytes[position] == _separator[0] &&
        bytes[position + 1] == _separator[1] &&
        bytes[position + 2] == _separator[2];
  }

  /// Шукаємо, де починаються "4 wide-char" (тобто digit,0, digit,0, digit,0, digit,0).
  /// Починаємо з [startPos], йдемо вперед, поки не знайдемо такий патерн,
  /// або не дійдемо до кінця.
  /// Повертає індекс початку, або -1, якщо не знайшли.
  static int _findColorCodeOffset(List<int> bytes, int startPos) {
    for (int i = startPos; i < bytes.length - 7; i++) {
      // Перевіряємо 4 пари байтів [ digit, 0x00 ]
      if (_is4DigitsWide(bytes, i)) {
        return i;
      }
    }
    return -1;
  }

  /// Перевірка, чи з [offset] є 4 wide-char, кожен з яких – це ASCII-цифра (0x30..0x39) і далі 0x00.
  static bool _is4DigitsWide(List<int> bytes, int offset) {
    // Має бути принаймні 8 байтів
    if (offset + 7 >= bytes.length) return false;
    for (int j = 0; j < 4; j++) {
      final ch = bytes[offset + j * 2];
      final nullByte = bytes[offset + j * 2 + 1];
      if (ch < 0x30 || ch > 0x39) return false; // не цифра
      if (nullByte != 0x00) return false;       // має бути 0x00
    }
    return true;
  }

  /// Зчитує [length] wide-char (UTF-16 LE), починаючи з [position].
  /// Кожен символ – 2 байти: (char, 0x00) якщо це ASCII.
  /// Повертає готовий рядок.
  static String _readWideString(List<int> bytes, int position, int length) {
    final sb = StringBuffer();
    for (int i = 0; i < length; i++) {
      if (position + i * 2 + 1 >= bytes.length) break;
      final lo = bytes[position + i * 2];
      final hi = bytes[position + i * 2 + 1];
      final codeUnit = (hi << 8) | lo;
      sb.writeCharCode(codeUnit);
    }
    return sb.toString();
  }

  /// Зчитує рядок у wide-char до моменту, поки не зустрінемо:
  ///  - _separator (0xFF, 0xFE, 0xFF),
  ///  - _endMarker (CEmbOnes),
  ///  - або край масиву.
  ///
  /// Повертає «рядок + скільки байтів спожито».
  static _WideStringResult _readWideStringUntilSeparatorOrEnd(List<int> bytes, int startPos) {
    final sb = StringBuffer();
    int pos = startPos;

    while (pos + 1 < bytes.length) {
      if (_isEndMarker(bytes, pos)) {
        // Зупиняємося
        break;
      }
      if (_isSeparator(bytes, pos)) {
        // Зупиняємося
        break;
      }
      // Читаємо 2 байти як wide-char
      final lo = bytes[pos];
      final hi = bytes[pos + 1];
      final codeUnit = (hi << 8) | lo;
      sb.writeCharCode(codeUnit);
      pos += 2;
    }

    return _WideStringResult(sb.toString(), pos - startPos);
  }
}

/// Проміжна структура: [text] і [consumedBytes].
class _WideStringResult {
  final String text;
  final int consumedBytes;
  _WideStringResult(this.text, this.consumedBytes);
}
