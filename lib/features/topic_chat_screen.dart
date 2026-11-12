import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';

class TopicChatScreen extends StatefulWidget {
  final String topicKey;

  const TopicChatScreen({super.key, required this.topicKey});

  @override
  State<TopicChatScreen> createState() => _TopicChatScreenState();
}

class _TopicChatScreenState extends State<TopicChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _verseRefController = TextEditingController();
  List _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _verseRefController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final data =
        await DatabaseHelper.instance.getTopicMessages(widget.topicKey);
    if (mounted) {
      setState(() {
        _messages = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    await DatabaseHelper.instance.addTopicMessage(
      topicKey: widget.topicKey,
      authorName: 'விசுவாசி (You)',
      messageText: text,
      verseRef: _verseRefController.text.trim(),
    );

    _msgController.clear();
    _verseRefController.clear();
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181A24),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.topicKey,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Community Discussion (அதிக Praise God வரிசையில்)',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Colors.indigoAccent),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final bool liked = (msg['is_liked'] ?? 0) == 1;
                      final String ref = (msg['verse_ref'] ?? '').toString();

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1D28),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: index == 0
                                ? Colors.amberAccent.withValues(alpha: 0.4)
                                : Colors.white10,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '#${index + 1} • ${msg['author_name']}',
                                  style: const TextStyle(
                                    color: Colors.indigoAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (ref.isNotEmpty)
                                  Text(
                                    ref,
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              msg['message_text'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () async {
                                  await DatabaseHelper.instance
                                      .toggleTopicMessageLike(
                                    msg['id'],
                                    msg['likes_count'] ?? 0,
                                    msg['is_liked'] ?? 0,
                                  );
                                  _loadMessages();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: liked
                                        ? Colors.indigoAccent
                                            .withValues(alpha: 0.3)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        liked
                                            ? Icons.thumb_up
                                            : Icons.thumb_up_outlined,
                                        size: 14,
                                        color: liked
                                            ? Colors.amberAccent
                                            : Colors.white70,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Praise God (${msg['likes_count']})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // புதிய கருத்து பதிவிடும் பெட்டி
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF181A24),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _verseRefController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'வசன ஆதாரம் (விருப்பமிருந்தால் - உதா: 1 கொரிந்தியர் 13:4)',
                    hintStyle:
                        const TextStyle(color: Colors.white38, fontSize: 12),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFF12141D),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'உங்கள் ஆவிக்குரிய கருத்தைப் பதிவிடுங்கள்...',
                          hintStyle: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          filled: true,
                          fillColor: const Color(0xFF12141D),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.indigoAccent,
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
