import 'package:findus_app/models/worker_model.dart';

class CompletedWorkJob {
  final String workerKey;   // worker.id বা phone বা name যেটা দিয়ে মেলাবে
  final String name;
  final String role;
  // চাইলে address/price ইত্যাদি রাখো

  CompletedWorkJob({
    required this.workerKey,
    required this.name,
    required this.role,
  });
}

class CompletedWorkService {
  // ডেমো ডাটা – আস্তে আস্তে এখানে সত্যিকারের completed jobs রাখবে
  static final List<CompletedWorkJob> _completedJobs = [
    CompletedWorkJob(
      workerKey: 'borhan_driver_id', // এখানে আসলে worker.id/phone ব্যবহার করবে
      name: 'Borhan Uddin',
      role: 'FARMER',
    ),
    CompletedWorkJob(
      workerKey: 'joynal_rickshaw_id',
      name: 'Joynal',
      role: 'RICKSHAW',
    ),
  ];

  /// কারো completed job সংখ্যা (profile এ দেখানোর জন্য)
  static Future<int> getCompletedCountForWorker(String workerKey) async {
    if (workerKey.isEmpty) return 0;
    return _completedJobs.where((j) => j.workerKey == workerKey).length;
  }

  /// CompletedWorkTab এই job list থেকেই UI বানাবে
  static List<CompletedWorkJob> getAllCompletedJobs() {
    return List.unmodifiable(_completedJobs);
  }

  /// ভবিষ্যতে কোনো job complete হলে এখানে add করবে
  static void addCompletedJobForWorker(Worker worker) {
    _completedJobs.add(
      CompletedWorkJob(
        workerKey: worker.id.isNotEmpty ? worker.id : worker.name,
        name: worker.name,
        role: worker.role,
      ),
    );
  }
}