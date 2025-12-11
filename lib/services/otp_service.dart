import 'dart:math';

/// OTP Service yang Disederhanakan dengan Rotasi 30 Detik
/// Menggunakan seed dari secret key + time counter untuk generate OTP
class OtpService {
  static const int _otpLength = 6;
  static const int _period = 30; // 30 detik per window
  
  /// Generate secret key - random string for seeding
  static String generateSecretKey() {
    final random = Random.secure();
    // Generate 16 digit random number as secret
    final secret = List.generate(16, (_) => random.nextInt(10)).join();
    print('[OTP] Generated secret key: $secret');
    return secret;
  }

  /// Generate OTP berdasarkan waktu (rotasi tiap 30 detik)
  static String generateOTP(String secretKey, {int period = _period}) {
    try {
      if (secretKey.isEmpty) {
        throw Exception('Secret key kosong');
      }

      // Hitung counter berdasarkan waktu
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final counter = now ~/ period;

      // Generate OTP dari kombinasi secret + counter
      final otp = _generateFromSeed(secretKey, counter);
      
      print('[OTP] Generated: $otp (counter: $counter, time: $now)');
      return otp;
    } catch (e) {
      print('[OTP ERROR] Failed to generate: $e');
      // Fallback: generate random OTP jika error
      return _generateRandom();
    }
  }

  /// Generate OTP dari seed (secret + counter)
  static String _generateFromSeed(String secret, int counter) {
    // Combine secret dengan counter untuk create deterministic seed
    int seed = 0;
    for (int i = 0; i < secret.length; i++) {
      seed = (seed * 31 + secret.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    seed = (seed * 31 + counter) & 0x7FFFFFFF;
    
    // Generate 6 digit OTP dari seed
    final random = Random(seed);
    final otp = List.generate(_otpLength, (_) => random.nextInt(10)).join();
    return otp;
  }

  /// Generate random OTP (fallback)
  static String _generateRandom() {
    final random = Random.secure();
    return List.generate(_otpLength, (_) => random.nextInt(10)).join();
  }

  /// Validasi OTP dengan toleransi time window (±1 window = ±30 detik)
  static bool validateOTP(String secretKey, String inputOtp, {int period = _period}) {
    try {
      // Normalisasi input
      final normalizedOtp = inputOtp.trim().replaceAll(RegExp(r'[^0-9]'), '');
      
      if (normalizedOtp.length != _otpLength) {
        print('[OTP VALIDATION] Invalid length: ${normalizedOtp.length}');
        return false;
      }
      
      if (secretKey.isEmpty) {
        print('[OTP VALIDATION ERROR] Secret key kosong');
        return false;
      }

      // Hitung counter saat ini
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final currentCounter = now ~/ period;

      print('[OTP VALIDATION] Input: $normalizedOtp, Counter: $currentCounter');

      // Cek window: -1, 0, +1 (total 1.5 menit toleransi)
      for (int offset = -1; offset <= 1; offset++) {
        final testCounter = currentCounter + offset;
        final expectedOtp = _generateFromSeed(secretKey, testCounter);
        
        print('[OTP VALIDATION] Window $offset: $expectedOtp');
        
        if (expectedOtp == normalizedOtp) {
          print('[OTP VALIDATION] ✓ Match at window $offset');
          return true;
        }
      }
      
      print('[OTP VALIDATION] ✗ No match');
      return false;
    } catch (e) {
      print('[OTP VALIDATION ERROR] $e');
      return false;
    }
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

  /// Test OTP (untuk debugging)
  static void testOTP(String secretKey) {
    print('\n=== OTP TEST ===');
    print('Secret Key: $secretKey');
    print('Current Time: ${DateTime.now()}');
    
    final counter = getCurrentCounter();
    print('Current Counter: $counter');
    
    final otp = generateOTP(secretKey);
    print('Current OTP: $otp');
    
    final isValid = validateOTP(secretKey, otp);
    print('Self-validation: ${isValid ? "✓ PASS" : "✗ FAIL"}');
    
    print('Time remaining: ${getTimeRemaining()}s');
    print('================\n');
  }
}