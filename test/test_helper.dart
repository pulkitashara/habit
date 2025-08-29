import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habit_builder/data/datasources/local/hive_service.dart';

class TestHelper {
  static Future<void> setupTest() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock path_provider
    const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
    pathProviderChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getApplicationDocumentsDirectory':
          return '/mocked/app/documents';
        case 'getTemporaryDirectory':
          return '/mocked/temp';
        default:
          return null;
      }
    });

    // Initialize Hive properly
    await Hive.initFlutter();

    // Open all required boxes BEFORE any HiveService calls
    try {
      if (!Hive.isBoxOpen('users')) {
        await Hive.openBox('users');
      }
      if (!Hive.isBoxOpen('habits')) {
        await Hive.openBox('habits');
      }
      if (!Hive.isBoxOpen('habitProgress')) {
        await Hive.openBox('habitProgress');
      }
    } catch (e) {
      print('Error opening Hive boxes in test: $e');
    }
  }

  static Future<void> cleanupTest() async {
    const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
    pathProviderChannel.setMockMethodCallHandler(null);

    try {
      await Hive.deleteFromDisk();
    } catch (e) {
      print('Error cleaning up Hive in test: $e');
    }
  }
}
