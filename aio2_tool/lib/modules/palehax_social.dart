import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Basit Kullanıcı Modeli
class OnlineUser {
  final String name;
  final String status;
  final bool isOnline;
  final String avatarUrl; // Gerçekte URL olur, burada renk kodu kullanacağız

  OnlineUser(this.name, this.status, this.isOnline, this.avatarUrl);
}

class SocialHubView extends StatefulWidget {
  const SocialHubView({super.key});

  @override
  State<SocialHubView> createState() => _SocialHubViewState();
}

class _SocialHubViewState extends State<SocialHubView> {
  // Rastgele Oyuncular (Simülasyon)
  final List<OnlineUser> _users = [
    OnlineUser("HaxKing_99", "Maçta...", true, "A"),
    OnlineUser("ProStriker", "Kadro kuruyor", true, "B"),
    OnlineUser("DefansBakanı", "AFK", true, "C"),
    OnlineUser("PaleHaxAdmin", "Online", true, "D"),
    OnlineUser("GoalMachine", "Maç Arıyor", true, "E"),
    OnlineUser("NoobMaster", "Çevrimdışı", false, "F"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
            "ONLINE OYUNCULAR (${_users.where((u) => u.isOnline).length})",
            style:
                GoogleFonts.orbitron(color: Colors.greenAccent, fontSize: 16)),
        actions: [
          IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {})
        ],
      ),
      body: Stack(children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.15,
            child: Image.asset('assets/pale2.jpg', fit: BoxFit.cover),
          ),
        ),
        ListView.builder(
          itemCount: _users.length,
          itemBuilder: (c, i) {
            final user = _users[i];
            return ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors
                        .primaries[user.name.length % Colors.primaries.length],
                    child: Text(user.name[0],
                        style: const TextStyle(color: Colors.white)),
                  ),
                  if (user.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2)),
                      ),
                    )
                ],
              ),
              title: Text(user.name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(user.status,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 12)),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 10)),
                onPressed: () => _openChat(context, user),
                child: const Text("CHAT",
                    style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            );
          },
        ),
      ]),
    );
  }

  void _openChat(BuildContext context, OnlineUser user) {
    TextEditingController msgCtrl = TextEditingController();
    List<String> messages = ["Sistem: ${user.name} ile sohbet başladı."];

    showDialog(
        context: context,
        builder: (c) => StatefulBuilder(builder: (context, setModalState) {
              return Dialog(
                backgroundColor: const Color(0xFF1E1E24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Container(
                  width: 400,
                  height: 500,
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      // Header
                      Row(children: [
                        CircleAvatar(child: Text(user.name[0])),
                        const SizedBox(width: 10),
                        Text(user.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context))
                      ]),
                      const Divider(color: Colors.white24),

                      // Mesajlar
                      Expanded(
                        child: ListView.builder(
                          itemCount: messages.length,
                          itemBuilder: (c, i) => Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: i == 0
                                    ? Colors.yellow.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(messages[i],
                                style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),

                      // Input
                      Row(children: [
                        Expanded(
                            child: TextField(
                          controller: msgCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                              hintText: "Mesaj yaz...",
                              hintStyle: TextStyle(color: Colors.white30),
                              border: InputBorder.none),
                        )),
                        IconButton(
                          icon:
                              const Icon(Icons.send, color: Colors.cyanAccent),
                          onPressed: () {
                            if (msgCtrl.text.isNotEmpty) {
                              setModalState(() {
                                messages.add("Sen: ${msgCtrl.text}");
                                msgCtrl.clear();
                                // Bot Cevabı Simülasyonu
                                Future.delayed(const Duration(seconds: 1), () {
                                  if (context.mounted) {
                                    setModalState(() => messages.add(
                                        "${user.name}: Şu an maçtayım sonra konuşalım!"));
                                  }
                                });
                              });
                            }
                          },
                        )
                      ])
                    ],
                  ),
                ),
              );
            }));
  }
}
