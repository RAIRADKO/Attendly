import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class OtpService {
  // Generate secret key yang lebih simple dan konsisten
  static String generateSecretKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(20, (i) => random.nextInt(256)); // 20 bytes = 160 bits (standar TOTP)
    return base64Encode(bytes);
  }

  // Generate OTP dengan algoritma TOTP standar
  static String generateOTP(String secretKey, {int period = 30}) {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final counter = now ~/ period;
      
      print('[OTP DEBUG] Generating OTP at timestamp: $now, counter: $counter');
      
      // Decode secret key
      final key = base64Decode(secretKey);
      
      // Convert counter to 8-byte big-endian array
      final counterBytes = _intToBytes(counter);
      
      // Generate HMAC-SHA1
      final hmac = Hmac(sha1, key);
      final digest = hmac.convert(counterBytes);
      final hash = digest.bytes;
      
      // Dynamic truncation (RFC 6238)
      final offset = hash[19] & 0x0f;
      final binary = ((hash[offset] & 0x7f) << 24) |
                     ((hash[offset + 1] & 0xff) << 16) |
                     ((hash[offset + 2] & 0xff) << 8) |
                     (hash[offset + 3] & 0xff);
      
      final otp = (binary % 1000000).toString().padLeft(6, '0');
      
      print('[OTP DEBUG] Generated OTP: $otp');
      return otp;
    } catch (e) {
      print('[OTP ERROR] Failed to generate OTP: $e');
      return '000000'; // Fallback untuk debugging
    }
  }

  // Convert integer to 8-byte big-endian array
  static List<int> _intToBytes(int value) {
    final buffer = Uint8List(8);
    final byteData = ByteData.view(buffer.buffer);
    byteData.setUint64(0, value, Endian.big);
    return buffer.toList();
  }

  // Validasi OTP dengan toleransi time window
  static bool validateOTP(String secretKey, String inputOtp) {
    try {
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final period = 30;
      final currentCounter = currentTime ~/ period;

      print('[OTP VALIDATION] Input: $inputOtp at timestamp: $currentTime');

      // Check current window and ±2 windows (total 5 windows = ±1 minute tolerance)
      final validWindows = [
        currentCounter - 2,
        currentCounter - 1,
        currentCounter,
        currentCounter + 1,
        currentCounter + 2,
      ];

      for (final counter in validWindows) {
        // Generate OTP untuk counter tertentu
        final testTime = counter * period * 1000;
        final expectedOtp = _generateOTPForCounter(secretKey, counter);
        
        print('[OTP VALIDATION] Testing counter $counter (${counter * period}s): $expectedOtp');
        
        if (expectedOtp == inputOtp) {
          print('[OTP VALIDATION] ✓ Match found at counter $counter');
          return true;
        }
      }

      print('[OTP VALIDATION] ✗ No match found in any window');
      return false;
    } catch (e) {
      print('[OTP VALIDATION ERROR] $e');
      return false;
    }
  }

  // Helper untuk generate OTP pada counter spesifik
  static String _generateOTPForCounter(String secretKey, int counter) {
    try {
      final key = base64Decode(secretKey);
      final counterBytes = _intToBytes(counter);
      
      final hmac = Hmac(sha1, key);
      final digest = hmac.convert(counterBytes);
      final hash = digest.bytes;
      
      final offset = hash[19] & 0x0f;
      final binary = ((hash[offset] & 0x7f) << 24) |
                     ((hash[offset + 1] & 0xff) << 16) |
                     ((hash[offset + 2] & 0xff) << 8) |
                     (hash[offset + 3] & 0xff);
      
      return (binary % 1000000).toString().padLeft(6, '0');
    } catch (e) {
      print('[OTP ERROR] Failed to generate OTP for counter $counter: $e');
      return '000000';
    }
  }

  // Test function untuk debugging
  static void testOTP(String secretKey) {
    print('\n=== OTP TEST ===');
    print('Secret Key: ${secretKey.substring(0, 10)}...');
    print('Current Time: ${DateTime.now()}');
    
    final otp = generateOTP(secretKey);
    print('Current OTP: $otp');
    
    print('\nTesting validation:');
    final isValid = validateOTP(secretKey, otp);
    print('Self-validation: ${isValid ? "PASS" : "FAIL"}');
    
    print('\nNext 3 OTPs (30s intervals):');
    for (int i = 1; i <= 3; i++) {
      final futureCounter = (DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ 30) + i;
      final futureOtp = _generateOTPForCounter(secretKey, futureCounter);
      print('  +${i * 30}s: $futureOtp');
    }
    print('================\n');
  }
}