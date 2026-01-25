// lib/screens/emergency_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

class EmergencyContact {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String type;
  final String category;
  final double lat;
  final double lng;
  final bool isVerified;
  final bool isPersonal;

  EmergencyContact({
    required this.id, required this.name, required this.address,
    required this.phone, required this.type, required this.category,
    required this.lat, required this.lng,
    this.isVerified = false, this.isPersonal = false,
  });

  factory EmergencyContact.fromFirestore(DocumentSnapshot doc, {bool personal = false}) {
    final data = doc.data() as Map<String, dynamic>;
    return EmergencyContact(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      type: data['type'] ?? 'General',
      category: data['category'] ?? 'HOSPITAL',
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      isVerified: data['isVerified'] ?? false,
      isPersonal: personal,
    );
  }
}

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  Position? _currentPosition;
  final ll.Distance _distanceCalc = const ll.Distance();
  String _selectedCategory = "HOSPITAL";
  String _searchQuery = "";
  bool _isLoading = true;
  List<EmergencyContact> _combinedContacts = [];

  final List<String> _categories = ["HOSPITAL", "FIRE SERVICE", "POLICE", "AMBULANCE", "ELECTRICITY"];

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _fetchContacts();
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _currentPosition = position);
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Future<void> _fetchContacts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      final publicSnap = await FirebaseFirestore.instance
          .collection('emergency_directory')
          .where('category', isEqualTo: _selectedCategory)
          .get();

      List<EmergencyContact> publicList = publicSnap.docs.map((doc) => EmergencyContact.fromFirestore(doc)).toList();

      List<EmergencyContact> personalList = [];
      if (uid != null) {
        final personalSnap = await FirebaseFirestore.instance
            .collection('users').doc(uid).collection('personal_emergency')
            .where('category', isEqualTo: _selectedCategory)
            .get();
        personalList = personalSnap.docs.map((doc) => EmergencyContact.fromFirestore(doc, personal: true)).toList();
      }

      if (mounted) {
        setState(() {
          _combinedContacts = [...publicList, ...personalList];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ডার্ক মোড চেক
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      title: "EMERGENCY HELP",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      actions: [
        TextButton.icon(
          onPressed: _openAddContactSheet,
          icon: Icon(Icons.add_circle_outline, size: 20, color: textColor),
          label: Text(
              "ADD NEW",
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)
          ),
        ),
        const SizedBox(width: 8),
      ],
      body: Column(
        children: [
          _buildTopHeader(isDark),
          _buildSOSButton(),
          const SizedBox(height: 10),
          _buildSearchAndFilters(isDark),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchContacts,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
                  : _buildContactListLogic(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.redAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: const Column(
        children: [
          Icon(Icons.health_and_safety, size: 50, color: Colors.redAccent),
          Text("Emergency Directory", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isDark) {
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            style: TextStyle(color: textColor),
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search name or location...",
              hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade600),
              prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey : null),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : textColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() => _selectedCategory = cat);
                    _fetchContacts();
                  },
                  selectedColor: Colors.redAccent,
                  backgroundColor: cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactListLogic(bool isDark) {
    var filtered = _combinedContacts.where((c) => c.name.toLowerCase().contains(_searchQuery) || c.address.toLowerCase().contains(_searchQuery)).toList();

    if (_currentPosition != null) {
      filtered.sort((a, b) => _calculateDistance(a.lat, a.lng).compareTo(_calculateDistance(b.lat, b.lng)));
    }

    if (filtered.isEmpty) return Center(child: Text("No contacts found.", style: TextStyle(color: isDark ? Colors.grey : Colors.black54)));

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildContactCard(filtered[index], isDark),
    );
  }

  Widget _buildContactCard(EmergencyContact contact, bool isDark) {
    double dist = _calculateDistance(contact.lat, contact.lng);
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (contact.isPersonal ? Colors.blue : Colors.redAccent).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(_getCategoryIcon(contact.category), color: contact.isPersonal ? Colors.blue : Colors.redAccent),
        ),
        title: Row(
          children: [
            Expanded(child: Text(contact.name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
            if (contact.isVerified) const Icon(Icons.verified, color: Colors.blue, size: 16),
            if (contact.isPersonal) const Text(" (MY)", style: TextStyle(fontSize: 10, color: Colors.blue)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.address, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 5),
            Row(
              children: [
                if (_currentPosition != null && contact.lat != 0) ...[
                  const Icon(Icons.location_on, size: 12, color: Colors.green),
                  Text(" ${dist.toStringAsFixed(1)} km", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
                const Spacer(),
                Text(contact.type, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
        trailing: CircleAvatar(
          backgroundColor: Colors.green,
          child: IconButton(icon: const Icon(Icons.phone, color: Colors.white), onPressed: () => _makePhoneCall(contact.phone)),
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => _makePhoneCall("999"),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.red.shade900, Colors.redAccent]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 30),
              SizedBox(width: 15),
              Text("CALL 999 NOW", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateDistance(double targetLat, double targetLng) {
    if (_currentPosition == null || targetLat == 0) return 0.0;
    return _distanceCalc.as(ll.LengthUnit.Kilometer, ll.LatLng(_currentPosition!.latitude, _currentPosition!.longitude), ll.LatLng(targetLat, targetLng));
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case "HOSPITAL": return FontAwesomeIcons.houseMedical;
      case "FIRE SERVICE": return FontAwesomeIcons.fireExtinguisher;
      case "POLICE": return FontAwesomeIcons.buildingShield;
      case "AMBULANCE": return FontAwesomeIcons.truckMedical;
      default: return Icons.emergency;
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    HapticFeedback.heavyImpact();
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  void _openAddContactSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    String category = _selectedCategory;
    bool requestPublic = false;

    // ✅ ডার্ক মোড চেক
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20, right: 20, top: 20
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: const BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(10)))),
                ),
                const SizedBox(height: 20),
                const Text("Add Emergency Contact", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                const SizedBox(height: 20),

                _buildField(nameController, "Name", Icons.business, isDark),
                _buildField(phoneController, "Phone", Icons.phone, isDark, isPhone: true),
                _buildField(addressController, "Address", Icons.location_on, isDark),

                const SizedBox(height: 10),
                Text("Select Category", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                DropdownButton<String>(
                  value: category,
                  isExpanded: true,
                  dropdownColor: bgColor,
                  style: TextStyle(color: textColor),
                  items: _categories.map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (val) => setModalState(() => category = val!),
                ),

                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("Request Public Directory", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                  subtitle: const Text("Admin approval required", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  value: requestPublic,
                  activeThumbColor: Colors.redAccent,
                  onChanged: (val) => setModalState(() => requestPublic = val),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and Phone required!")));
                      return;
                    }
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) return;

                    final data = {
                      'name': nameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'address': addressController.text.trim(),
                      'category': category,
                      'lat': _currentPosition?.latitude ?? 0.0,
                      'lng': _currentPosition?.longitude ?? 0.0,
                      'submittedBy': uid,
                      'createdAt': FieldValue.serverTimestamp(),
                      'isVerified': false,
                    };

                    try {
                      if (requestPublic) {
                        await FirebaseFirestore.instance.collection('emergency_requests').add({...data, 'status': 'pending'});
                      } else {
                        await FirebaseFirestore.instance.collection('users').doc(uid).collection('personal_emergency').add(data);
                      }
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      _fetchContacts();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved Successfully!"), backgroundColor: Colors.green));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("SAVE CONTACT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, bool isDark, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade700),
          prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.grey : null),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}