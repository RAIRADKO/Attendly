import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class OtpService {
  static String generateSecretKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  static String generateOTP(String secretKey, {int period = 30}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final counter = now ~/ period;
    
    final key = utf8.encode(secretKey);
    final counterBytes = _intToBytes(counter);
    
    final hmac = Hmac(sha1, key);
    final digest = hmac.convert(counterBytes);
    final hash = digest.bytes;
    
    final offset = hash[19] & 0xf;
    final binary = ((hash[offset] & 0x7f) << 24) |
                   ((hash[offset + 1] & 0xff) << 16) |
                   ((hash[offset + 2] & 0xff) << 8) |
                   (hash[offset + 3] & 0xff);
    
    final otp = (binary % pow(10, 6)).toString().padLeft(6, '0');
    return otp.substring(otp.length - 6);
  }

  // PERBAIKAN: Menambahkan padding agar menjadi 8 bytes (64-bit integer)
  static List<int> _intToBytes(int value) {
    var bytes = <int>[];
    // Masukkan 4 byte nol di depan untuk melengkapi 8 byte (big-endian 64-bit)
    bytes.addAll([0, 0, 0, 0]); 
    
    bytes.add((value >> 24) & 0xFF);
    bytes.add((value >> 16) & 0xFF);
    bytes.add((value >> 8) & 0xFF);
    bytes.add(value & 0xFF);
    return bytes;
  }
}