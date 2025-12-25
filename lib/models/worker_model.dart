class Worker {
  final String id;        // 🔹 এখনো final থাকবে
  final String name;
  final String role;
  final String image;
  final String message;
  final int medals;
  final bool isVerified;
  final double rating;
  final String location;
  final String price;

  Worker({
    this.id = "",         // 🔹 required না, default '' (empty string)
    required this.name,
    required this.role,
    required this.image,
    this.message = "",
    this.medals = 0,
    this.isVerified = false,
    this.rating = 0.0,
    this.location = "Bangladesh",
    this.price = "Negotiable",
  });

  String get imagePath => image;
}