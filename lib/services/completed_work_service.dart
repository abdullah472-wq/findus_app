// lib/services/completed_work_service.dart
//
// ✅ Fixed for new Worker model (no worker.role)
// - worker.id -> still works if you kept getter id => uid, but better to use worker.uid
// - role now should be a display label (service type) OR derive from userRole
//   Since Worker model no longer stores service type, we store a safe label here.

import 'package:findus_app/models/worker_model.dart';

class CompletedWorkJob {
  final String workerKey; // worker.uid (recommended) or fallback
  final String name;

  /// Display label (e.g. ELECTRICIAN / DRIVER). This is NOT userRole (finder/maker).
  final String roleLabel;

  CompletedWorkJob({
    required this.workerKey,
    required this.name,
    required this.roleLabel,
  });
}

class CompletedWorkService {
  static final List<CompletedWorkJob> _completedJobs = [
    CompletedWorkJob(
      workerKey: 'borhan_driver_id',
      name: 'Borhan Uddin',
      roleLabel: 'FARMER',
    ),
    CompletedWorkJob(
      workerKey: 'joynal_rickshaw_id',
      name: 'Joynal',
      roleLabel: 'RICKSHAW',
    ),
  ];

  static Future<int> getCompletedCountForWorker(String workerKey) async {
    if (workerKey.trim().isEmpty) return 0;
    return _completedJobs.where((j) => j.workerKey == workerKey).length;
  }

  static List<CompletedWorkJob> getAllCompletedJobs() {
    return List.unmodifiable(_completedJobs);
  }

  /// ✅ Add completed job for a worker
  /// Since Worker model doesn't have serviceType/role label anymore,
  /// we accept an optional roleLabel. If not provided, we derive from userRole.
  static void addCompletedJobForWorker(
      Worker worker, {
        String? roleLabel,
      }) {
    final key = worker.uid.trim().isNotEmpty ? worker.uid.trim() : worker.name.trim();

    final derivedLabel = (worker.userRole.toLowerCase().trim() == 'finder')
        ? 'WORKER'
        : 'SUPPORTER';

    _completedJobs.add(
      CompletedWorkJob(
        workerKey: key,
        name: worker.name,
        roleLabel: (roleLabel ?? derivedLabel).toUpperCase(),
      ),
    );
  }
}