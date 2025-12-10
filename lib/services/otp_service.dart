import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class OtpService {
  static const int _otpLength = 6;
  static const int _period = 30; // 30 detik per window
  
  /// Generate secret key yang konsisten
  static String generateSecretKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256)); // 32 bytes untuk keamanan lebih
    return base64Url.encode(bytes);
  }

  /// Generate OTP berdasarkan TOTP (Time-based One-Time Password)
  /// Menggunakan waktu Unix sebagai counter
  static String generateOTP(String secretKey, {int period = _period}) {
    try {
      // Decode secret key
      List<int> key;
      try {
        key = base64Url.decode(secretKey);
      } catch (e) {
        // Fallback ke base64 biasa jika base64Url gagal
        key = base64.decode(secretKey);
      }
      
      // Hitung counter berdasarkan waktu
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final counter = now ~/ period;
      
      print('[OTP] Generating at timestamp: $now, counter: $counter, period: $period');
      
      // Generate OTP
      final otp = _generateTOTP(key, counter);
      
      print('[OTP] Generated: $otp');
      return otp;
    } catch (e) {
      print('[OTP ERROR] Failed to generate: $e');
      return '000000'; // Fallback untuk debugging
    }
  }

  /// Validasi OTP dengan toleransi time window
  /// Memeriksa window saat ini, sebelumnya, dan sesudahnya (±1 menit toleransi)
  static bool validateOTP(String secretKey, String inputOtp, {int period = _period}) {
    try {
      // Decode secret key
      List<int> key;
      try {
        key = base64Url.decode(secretKey);
      } catch (e) {
        key = base64.decode(secretKey);
      }
      
      // Hitung counter saat ini
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final currentCounter = now ~/ period;
      
      print('[OTP VALIDATION] Input: $inputOtp at timestamp: $now');
      print('[OTP VALIDATION] Current counter: $currentCounter');
      
      // Cek beberapa window: -2, -1, 0, +1, +2 (total 2.5 menit toleransi)
      for (int offset = -2; offset <= 2; offset++) {
        final testCounter = currentCounter + offset;
        final expectedOtp = _generateTOTP(key, testCounter);
        
        final timeOffset = offset * period;
        print('[OTP VALIDATION] Testing counter $testCounter (offset ${timeOffset}s): $expectedOtp');
        
        if (expectedOtp == inputOtp) {
          print('[OTP VALIDATION] ✓ Match found at offset $offset ($timeOffset seconds)');
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

  /// Generate TOTP untuk counter tertentu
  static String _generateTOTP(List<int> key, int counter) {
    // Convert counter ke bytes (big-endian, 8 bytes)
    final counterBytes = _intToBytes(counter);
    
    // HMAC-SHA1
    final hmac = Hmac(sha1, key);
    final hash = hmac.convert(counterBytes).bytes;
    
    // Dynamic truncation (RFC 6238)
    final offset = hash[hash.length - 1] & 0x0f;
    
    final binary = ((hash[offset] & 0x7f) << 24) |
                   ((hash[offset + 1] & 0xff) << 16) |
                   ((hash[offset + 2] & 0xff) << 8) |
                   (hash[offset + 3] & 0xff);
    
    // Generate OTP dengan panjang yang ditentukan
    final otp = (binary % pow(10, _otpLength)).toString().padLeft(_otpLength, '0');
    
    return otp;
  }

  /// Convert integer ke 8-byte big-endian array
  static List<int> _intToBytes(int value) {
    final buffer = Uint8List(8);
    final byteData = ByteData.view(buffer.buffer);
    byteData.setUint64(0, value, Endian.big);
    return buffer.toList();
  }

  /// Test function untuk debugging
  static void testOTP(String secretKey) {
    print('\n=== OTP TEST ===');
    print('Secret Key: ${secretKey.substring(0, min(20, secretKey.length))}...');
    print('Current Time: ${DateTime.now()}');
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final currentCounter = now ~/ _period;
    print('Current Counter: $currentCounter');
    
    // Generate OTP saat ini
    final currentOtp = generateOTP(secretKey);
    print('Current OTP: $currentOtp');
    
    // Test validasi
    print('\n--- Testing Validation ---');
    final isValid = validateOTP(secretKey, currentOtp);
    print('Self-validation: ${isValid ? "✓ PASS" : "✗ FAIL"}');
    
    // Tampilkan OTP untuk beberapa window ke depan
    print('\n--- Next OTP Codes ---');
    for (int i = 1; i <= 3; i++) {
      final futureCounter = currentCounter + i;
      List<int> key;
      try {
        key = base64Url.decode(secretKey);
      } catch (e) {
        key = base64.decode(secretKey);
      }
      final futureOtp = _generateTOTP(key, futureCounter);
      final seconds = i * _period;
      print('  +${seconds}s (counter $futureCounter): $futureOtp');
    }
    
    // Tampilkan waktu tersisa di window saat ini
    final secondsInPeriod = now % _period;
    final timeRemaining = _period - secondsInPeriod;
    print('\n--- Current Window Info ---');
    print('Seconds elapsed in current window: $secondsInPeriod/$_period');
    print('Time until next OTP: ${timeRemaining}s');
    
    print('================\n');
  }

  /// Get waktu tersisa sebelum OTP berubah (dalam detik)
  static int getTimeRemaining({int period = _period}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final secondsInPeriod = now % period;
    return period - secondsInPeriod;
  }

  /// Get current counter value (untuk debugging)
  static int getCurrentCounter({int period = _period}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now ~/ period;
  }
}