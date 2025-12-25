import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// একটি কন্টাক্ট মডেল
class EmergencyContact {
  final String name;
  final String address;
  final String phone;
  final String type; // Government / Private / NGO / Personal

  EmergencyContact({
    required this.name,
    required this.address,
    required this.phone,
    required this.type,
  });
}

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  // ক্যাটেগরি অনুযায়ী কন্টাক্ট লিস্ট
  final Map<String, List<EmergencyContact>> _contacts = {
    "HOSPITAL": [
      EmergencyContact(
        name: "Radium Diagnostic Center",
        address: "Kapasia bazar",
        phone: "01700000000",
        type: "Private",
      ),
      EmergencyContact(
        name: "Zubaida Memorial Hospital",
        address: "Kapasia bazar",
        phone: "01800000000",
        type: "Private",
      ),
    ],
    "FIRE SERVICE": [],
    "POLICE": [],
    "ELECTRICITY": [],
  };

  // ফোন কল ফাংশন
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint("Could not launch dialer: $e");
    }
  }

  void _openAddContactSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    String selectedCategory = "HOSPITAL";
    String selectedType = "Government";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Add Emergency Contact",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Name
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Phone
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Phone",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Address
                      TextField(
                        controller: addressController,
                        decoration: InputDecoration(
                          labelText: "Address",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Category + Type (দুইটা dropdown)
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedCategory,
                              items: const [
                                DropdownMenuItem(
                                  value: "HOSPITAL",
                                  child: Text("Hospital"),
                                ),
                                DropdownMenuItem(
                                  value: "FIRE SERVICE",
                                  child: Text("Fire Service"),
                                ),
                                DropdownMenuItem(
                                  value: "POLICE",
                                  child: Text("Police"),
                                ),
                                DropdownMenuItem(
                                  value: "ELECTRICITY",
                                  child: Text("Electricity"),
                                ),
                              ],
                              onChanged: (val) {
                                if (val == null) return;
                                setModalState(() => selectedCategory = val);
                              },
                              decoration: InputDecoration(
                                labelText: "Category",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedType,
                              items: const [
                                DropdownMenuItem(
                                  value: "Government",
                                  child: Text("Government"),
                                ),
                                DropdownMenuItem(
                                  value: "Private",
                                  child: Text("Private"),
                                ),
                                DropdownMenuItem(
                                  value: "NGO",
                                  child: Text("NGO"),
                                ),
                                DropdownMenuItem(
                                  value: "Personal",
                                  child: Text("Personal"),
                                ),
                              ],
                              onChanged: (val) {
                                if (val == null) return;
                                setModalState(() => selectedType = val);
                              },
                              decoration: InputDecoration(
                                labelText: "Type",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("CANCEL"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              final phone = phoneController.text.trim();
                              final addr = addressController.text.trim();

                              if (name.isEmpty || phone.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Name & Phone are required.",
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              final contact = EmergencyContact(
                                name: name,
                                address: addr.isEmpty ? "Not specified" : addr,
                                phone: phone,
                                type: selectedType,
                              );

                              setState(() {
                                _contacts[selectedCategory] ??= [];
                                _contacts[selectedCategory]!.add(contact);
                              });

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "SAVE",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title: const Text(
          "EMERGENCY HELP",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ১. লাল ব্যাকগ্রাউন্ডের বেল আইকন
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 30, top: 10),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    size: 60,
                    color: Colors.yellow,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "EMERGENCY ALERT",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const Text(
                  "Get help immediately",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ২. ৯৯৯ কল বাটন
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => _makePhoneCall("999"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  shadowColor: Colors.redAccent.withOpacity(0.5),
                ),
                icon: const Icon(Icons.phone_in_talk, size: 28),
                label: const Text(
                  "CALL 999 NOW",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ৩. ইমার্জেন্সি লিস্ট
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                _buildEmergencyTile(
                  "HOSPITAL",
                  Colors.white,
                  FontAwesomeIcons.hospital,
                  isExpanded: true,
                  iconColor: Colors.red,
                ),
                const SizedBox(height: 10),
                _buildEmergencyTile(
                  "FIRE SERVICE",
                  Colors.white,
                  FontAwesomeIcons.fire,
                  iconColor: Colors.orange,
                ),
                const SizedBox(height: 10),
                _buildEmergencyTile(
                  "POLICE",
                  Colors.white,
                  FontAwesomeIcons.personMilitaryToPerson,
                  iconColor: Colors.blue,
                ),
                const SizedBox(height: 10),
                _buildEmergencyTile(
                  "ELECTRICITY",
                  Colors.white,
                  FontAwesomeIcons.bolt,
                  iconColor: Colors.amber,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),

      // ফ্লোটিং বাটন
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddContactSheet,
        label: const Text("Add Contact"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget _buildEmergencyTile(
      String title,
      Color bgColor,
      IconData icon, {
        bool isExpanded = false,
        required Color iconColor,
      }) {
    final list = _contacts[title] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        shape: Border.all(color: Colors.transparent),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        children: [
          const Divider(),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                "No contacts added yet.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          else
            ...list.map(_buildContactRow).toList(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildContactRow(EmergencyContact contact) {
    return ListTile(
      title: Text(
        contact.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        "${contact.address} • ${contact.type}",
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: GestureDetector(
        onTap: () => _makePhoneCall(contact.phone),
        child: const CircleAvatar(
          backgroundColor: Colors.green,
          radius: 18,
          child: Icon(Icons.phone, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}