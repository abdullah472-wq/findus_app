// lib/screens/tabs/dashboard/utils/dashboard_constants.dart
class DashboardConstants {
  static const String pendingStatus = 'pending';
  static const String ongoingStatus = 'ongoing';
  static const String completedStatus = 'completed';
  static const String rejectedStatus = 'rejected';

  static const List<String> jobStatuses = [
    pendingStatus,
    ongoingStatus,
    completedStatus,
    rejectedStatus,
  ];
}