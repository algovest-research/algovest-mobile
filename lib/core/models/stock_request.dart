class StockRequest {
  final String ticker;
  final String status; // pending | processing | ready | failed
  final DateTime? requestedAt;

  const StockRequest({
    required this.ticker,
    required this.status,
    this.requestedAt,
  });

  bool get isReady => status == 'ready';

  /// Ticker without the exchange suffix, e.g. "RELIANCE.NS" -> "RELIANCE".
  String get symbol => ticker.replaceAll('.NS', '');

  factory StockRequest.fromJson(Map<String, dynamic> j) => StockRequest(
        ticker: j['ticker'] as String,
        status: j['status'] as String,
        requestedAt: j['requestedAt'] != null
            ? DateTime.tryParse(j['requestedAt'] as String)
            : null,
      );
}
