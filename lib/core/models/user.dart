class Subscription {
  final String status; // 'none' | 'active' | 'expired'
  final DateTime? expiresAt;

  const Subscription({required this.status, this.expiresAt});

  bool get isActive => status == 'active';

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
    status: j['status'] as String,
    expiresAt: j['expires_at'] != null ? DateTime.parse(j['expires_at'] as String) : null,
  );
}

class User {
  final String id;
  final String? email;
  final String? phone;
  final String? name;
  final Subscription subscription;
  final int dailyUsage;
  final int dailyLimit;

  const User({
    required this.id,
    this.email,
    this.phone,
    this.name,
    required this.subscription,
    required this.dailyUsage,
    required this.dailyLimit,
  });

  bool get isPremium => subscription.isActive;
  bool get isGuest => id == 'guest';
  int get requestsRemaining => isPremium ? 999999 : (dailyLimit - dailyUsage).clamp(0, dailyLimit);
  String? get firstName => name?.split(' ').firstOrNull;

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'] as String,
    email: j['email'] as String?,
    phone: j['phone'] as String?,
    name: j['name'] as String?,
    subscription: Subscription.fromJson(j['subscription'] as Map<String, dynamic>),
    dailyUsage: j['daily_usage'] as int,
    dailyLimit: j['daily_limit'] as int,
  );
}