import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Pastikan nama package sesuai dengan pubspec.yaml Anda
import 'package:Attendly/main.dart'; 

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // [FIX] Menghapus kata kunci 'const' sebelum MyApp()
    // karena MyApp tidak memiliki const constructor.
    await tester.pumpWidget(MyApp());

    // --- CATATAN ---
    // Kode di bawah ini adalah default test untuk aplikasi Counter bawaan Flutter.
    // Karena aplikasi Anda adalah 'Presensi Mahasiswa' (bukan Counter),
    // kode ini akan menyebabkan error "Widget not found" jika dijalankan.
    // Saya menonaktifkannya (comment) agar test Anda menjadi hijau (lulus)
    // saat mengecek apakah aplikasi bisa dijalankan (smoke test).
    
    /*
    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    */
  });
}