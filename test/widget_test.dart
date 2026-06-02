// Unit tests for the core JSON models. Kept dependency-free (no network/assets)
// so they're fast and reliable in CI.

import 'package:flutter_test/flutter_test.dart';
import 'package:algovest/core/models/report.dart';
import 'package:algovest/core/models/stock_request.dart';

void main() {
  group('Report.fromJson', () {
    test('parses camelCase fields, rclass and agent votes', () {
      final r = Report.fromJson({
        'id': 'TCS.NS_1',
        'ticker': 'TCS.NS',
        'companyName': 'Tata Consultancy Services',
        'date': '2 Jun 2026',
        'isoDate': '2026-06-02T15:07:30',
        'rating': 'HOLD',
        'rclass': 'hold',
        'arrow': '—',
        'summary': 'Maintain position.',
        'agentVotes': {'buy': 5, 'hold': 5, 'sell': 2},
        'expectedReturn': null,
      });

      expect(r.ticker, 'TCS.NS');
      expect(r.companyName, 'Tata Consultancy Services');
      expect(r.rclass, RatingClass.hold);
      expect(r.agentVotes.buy, 5);
      expect(r.expectedReturn, isNull);
    });

    test('parses trade outlook fields for buys', () {
      final r = Report.fromJson({
        'id': 'WIPRO.NS_1',
        'ticker': 'WIPRO.NS',
        'companyName': 'Wipro',
        'date': '2 Jun 2026',
        'isoDate': '2026-06-02T15:07:30',
        'rating': 'BUY',
        'rclass': 'buy',
        'arrow': '▲',
        'summary': 'Favourable risk/reward.',
        'agentVotes': {'buy': 8, 'hold': 2, 'sell': 2},
        'expectedReturn': 13.4,
        'expectedReturnAnnualized': 39.8,
        'priceTarget': 238.0,
        'entryPrice': 209.84,
        'timeHorizon': '3–6 months',
      });

      expect(r.rclass, RatingClass.buy);
      expect(r.expectedReturn, 13.4);
      expect(r.priceTarget, 238.0);
      expect(r.timeHorizon, '3–6 months');
    });
  });

  group('StockRequest.fromJson', () {
    test('parses status, strips the .NS suffix, and reads readiness', () {
      final s = StockRequest.fromJson({
        'ticker': 'HDFCBANK.NS',
        'status': 'ready',
        'requestedAt': '2026-06-02T13:13:57.531928',
      });

      expect(s.ticker, 'HDFCBANK.NS');
      expect(s.symbol, 'HDFCBANK');
      expect(s.isReady, isTrue);
      expect(s.requestedAt, isNotNull);
    });
  });
}
