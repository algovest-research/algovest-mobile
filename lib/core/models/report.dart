class AgentVotes {
  final int buy;
  final int hold;
  final int sell;

  const AgentVotes({required this.buy, required this.hold, required this.sell});

  factory AgentVotes.fromJson(Map<String, dynamic> j) => AgentVotes(
    buy: j['buy'] as int,
    hold: j['hold'] as int,
    sell: j['sell'] as int,
  );
}

enum RatingClass { buy, hold, sell }

class Report {
  final String id;
  final String ticker;
  final String companyName;
  final String date;
  final String isoDate;
  final String rating;
  final RatingClass rclass;
  final String arrow;
  final String summary;
  final AgentVotes agentVotes;

  // Trade outlook — present for most actionable (e.g. buy) reports, null otherwise.
  final double? expectedReturn;            // % over the time horizon, e.g. 13.4
  final double? expectedReturnAnnualized;  // % annualized, e.g. 39.8
  final double? priceTarget;
  final double? entryPrice;
  final String? timeHorizon;               // e.g. "3–6 months"

  const Report({
    required this.id,
    required this.ticker,
    required this.companyName,
    required this.date,
    required this.isoDate,
    required this.rating,
    required this.rclass,
    required this.arrow,
    required this.summary,
    required this.agentVotes,
    this.expectedReturn,
    this.expectedReturnAnnualized,
    this.priceTarget,
    this.entryPrice,
    this.timeHorizon,
  });

  factory Report.fromJson(Map<String, dynamic> j) => Report(
    id: j['id'] as String,
    ticker: j['ticker'] as String,
    companyName: j['companyName'] as String,
    date: j['date'] as String,
    isoDate: j['isoDate'] as String,
    rating: j['rating'] as String,
    rclass: parseRclass(j['rclass'] as String),
    arrow: j['arrow'] as String,
    summary: j['summary'] as String,
    agentVotes: AgentVotes.fromJson(j['agentVotes'] as Map<String, dynamic>),
    expectedReturn: (j['expectedReturn'] as num?)?.toDouble(),
    expectedReturnAnnualized: (j['expectedReturnAnnualized'] as num?)?.toDouble(),
    priceTarget: (j['priceTarget'] as num?)?.toDouble(),
    entryPrice: (j['entryPrice'] as num?)?.toDouble(),
    timeHorizon: j['timeHorizon'] as String?,
  );

  static RatingClass parseRclass(String s) => switch (s) {
    'buy'  => RatingClass.buy,
    'sell' => RatingClass.sell,
    _      => RatingClass.hold,
  };
}