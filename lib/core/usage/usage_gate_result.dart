import 'usage_status.dart';

class UsageGateResult {
  const UsageGateResult._({required this.isAllowed, required this.status});

  factory UsageGateResult.allowed(UsageStatus status) {
    return UsageGateResult._(isAllowed: true, status: status);
  }

  factory UsageGateResult.blocked(UsageStatus status) {
    return UsageGateResult._(isAllowed: false, status: status);
  }

  final bool isAllowed;
  final UsageStatus status;
}
