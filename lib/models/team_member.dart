class TeamMember {
  final String id;        // userId (server থেকে)
  final String name;
  final String phone;
  final String role;      // owner / manager / staff
  final bool isPending;   // invite accepted হয়েছে কিনা

  // 🔹 স্ট্যাটিসটিক্স (ড্যাশবোর্ডে দেখানোর জন্য)
  final int jobsCompleted;
  final int jobsInProgress;
  final double totalEarnings; // আজ পর্যন্ত মোট আয়
  final double rating;        // গড় রেটিং (৫ এর মধ্যে)

  const TeamMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.isPending,
    required this.jobsCompleted,
    required this.jobsInProgress,
    required this.totalEarnings,
    required this.rating,
  });
}