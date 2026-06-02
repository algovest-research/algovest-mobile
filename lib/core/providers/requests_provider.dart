import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_request.dart';
import '../services/api_service.dart';
import '../constants/api.dart';

class RequestsNotifier extends StateNotifier<AsyncValue<List<StockRequest>>> {
  RequestsNotifier() : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    try {
      final res = await ApiService.instance
          .get<Map<String, dynamic>>(ApiConstants.myRequests);
      final list = (res.data!['requests'] as List<dynamic>)
          .map((e) => StockRequest.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Submits a request for [ticker] (e.g. "RELIANCE.NS").
  /// Returns null on success, or a human-readable error message on failure.
  Future<String?> submit(String ticker) async {
    try {
      await ApiService.instance
          .post<Map<String, dynamic>>(ApiConstants.myRequests, data: {'ticker': ticker});
      await fetch();
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) return data['detail'] as String;
      if (e.response?.statusCode == 401) return 'Please sign in to request analysis.';
      return 'Could not submit request. Please try again.';
    } catch (_) {
      return 'Could not submit request. Please try again.';
    }
  }
}

final requestsProvider =
    StateNotifierProvider<RequestsNotifier, AsyncValue<List<StockRequest>>>(
        (ref) => RequestsNotifier());
