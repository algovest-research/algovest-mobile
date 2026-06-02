import 'report.dart';

class SectionSummary {
  final String verdict;
  final List<String> bullets;
  final String? decision; // 'Bullish' | 'Bearish' | 'Neutral'

  const SectionSummary({
    required this.verdict,
    required this.bullets,
    this.decision,
  });

  factory SectionSummary.fromJson(Map<String, dynamic> j) => SectionSummary(
    verdict: j['verdict'] as String? ?? '',
    bullets: (j['bullets'] as List<dynamic>?)?.cast<String>() ?? [],
    decision: j['decision'] as String?,
  );
}

class ReportSection {
  final String id;
  final String label;
  final SectionSummary? summary;

  const ReportSection({required this.id, required this.label, this.summary});

  factory ReportSection.fromJson(Map<String, dynamic> j) => ReportSection(
    id: j['id'] as String,
    label: j['label'] as String,
    summary: j['summary'] != null
        ? SectionSummary.fromJson(j['summary'] as Map<String, dynamic>)
        : null,
  );
}

class ReportDetail extends Report {
  final List<ReportSection> sections;

  const ReportDetail({
    required super.id,
    required super.ticker,
    required super.companyName,
    required super.date,
    required super.isoDate,
    required super.rating,
    required super.rclass,
    required super.arrow,
    required super.summary,
    required super.agentVotes,
    super.expectedReturn,
    super.expectedReturnAnnualized,
    super.priceTarget,
    super.entryPrice,
    super.timeHorizon,
    required this.sections,
  });

  factory ReportDetail.fromJson(Map<String, dynamic> j) => ReportDetail(
    id: j['id'] as String,
    ticker: j['ticker'] as String,
    companyName: j['companyName'] as String,
    date: j['date'] as String,
    isoDate: j['isoDate'] as String,
    rating: j['rating'] as String,
    rclass: Report.parseRclass(j['rclass'] as String),
    arrow: j['arrow'] as String,
    summary: j['summary'] as String,
    agentVotes: AgentVotes.fromJson(j['agentVotes'] as Map<String, dynamic>),
    expectedReturn: (j['expectedReturn'] as num?)?.toDouble(),
    expectedReturnAnnualized: (j['expectedReturnAnnualized'] as num?)?.toDouble(),
    priceTarget: (j['priceTarget'] as num?)?.toDouble(),
    entryPrice: (j['entryPrice'] as num?)?.toDouble(),
    timeHorizon: j['timeHorizon'] as String?,
    sections: (j['sections'] as List<dynamic>?)
            ?.map((s) => ReportSection.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [],
  );
}