import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_service.dart';
import '../../data/services/mock_api_service.dart';

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return MockApiService();
  // In production, replace with: return RealApiService();
});

// Network status provider (mock implementation)
final networkStatusProvider = StateProvider<bool>((ref) => true);

// API loading state provider
final apiLoadingProvider = StateProvider<bool>((ref) => false);

// API error provider
final apiErrorProvider = StateProvider<String?>((ref) => null);
