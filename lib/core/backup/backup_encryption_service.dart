import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class BackupEncryptionService {
  Uint8List encrypt(Uint8List data, String userId) {
    final keyBytes = _deriveKey(userId);
    final key = Key(Uint8List.fromList(keyBytes));
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encryptBytes(data, iv: iv);

    return Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
  }

  Uint8List decrypt(Uint8List data, String userId) {
    if (data.length < 17) {
      throw const FormatException('Encrypted backup is invalid.');
    }

    final keyBytes = _deriveKey(userId);
    final key = Key(Uint8List.fromList(keyBytes));
    final iv = IV(data.sublist(0, 16));
    final encrypted = Encrypted(data.sublist(16));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final bytes = encrypter.decryptBytes(encrypted, iv: iv);
    return Uint8List.fromList(bytes);
  }

  List<int> _deriveKey(String userId) {
    return sha256.convert(utf8.encode('pocketpilot_$userId')).bytes;
  }
}
