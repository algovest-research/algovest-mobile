class ApiConstants {
  ApiConstants._();

  static const baseUrl = 'https://api.beta.algovest.online';

  // Auth
  static const sendOtp    = '/api/v1/auth/send-otp';
  static const verifyOtp  = '/api/v1/auth/verify-otp';
  static const me         = '/api/v1/auth/me';
  static const logout     = '/api/v1/auth/logout';

  // Reports
  static const reports    = '/api/v1/reports';

  // User
  static const myRequests    = '/api/v1/users/me/requests';
  static const myViewedToday = '/api/v1/users/me/viewed-today';
  static const earlyBirdStats = '/api/v1/users/early-bird-stats';
  static const claimEarlyBird = '/api/v1/users/me/claim-early-bird';
  static const consumeView    = '/api/v1/users/me/consume-view';
}