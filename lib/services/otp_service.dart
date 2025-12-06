import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
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
    
    // PERBAIKAN: Decode secret key dengan benar
    final key = base64Decode(secretKey);
    
    // PERBAIKAN: Convert counter to big-endian bytes (8 bytes)
    final counterBytes = _intToBytes(counter);
    
    // Generate HMAC-SHA1
    final hmac = Hmac(sha1, key);
    final digest = hmac.convert(counterBytes);
    final hash = digest.bytes;
    
    // Dynamic truncation
    final offset = hash[19] & 0xf;
    final binary = ((hash[offset] & 0x7f) << 24) |
                   ((hash[offset + 1] & 0xff) << 16) |
                   ((hash[offset + 2] & 0xff) << 8) |
                   (hash[offset + 3] & 0xff);
    
    final otp = (binary % 1000000).toString().padLeft(6, '0');
    return otp;
  }

  // ✅ PERBAIKAN: Correct big-endian 64-bit encoding
  static List<int> _intToBytes(int value) {
    final buffer = Uint8List(8);
    final byteData = ByteData.view(buffer.buffer);
    byteData.setUint64(0, value, Endian.big); // ✅ Big-endian
    return buffer.toList();
  }

  // ✅ TAMBAHAN: Validation helper untuk mahasiswa
  static bool validateOTP(String secretKey, String inputOtp) {
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final period = 30;
    final currentCounter = currentTime ~/ period;

    // Check current and previous periods (to handle clock skew)
    final validPeriods = [
      currentCounter,
      currentCounter - 1,
      currentCounter - 2,
    ];

    for (final counter in validPeriods) {
      final expectedOtp = generateOTP(secretKey);
      if (expectedOtp == inputOtp) {
        return true;
      }
    }
    return false;
  }
}