import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';

class PosterCreatorScreen extends StatefulWidget {
  final String category; // 'promise' or 'confession'
  final String initialRef;
  final String initialText;

  const PosterCreatorScreen({
    super.key,
    required this.category,
    required this.initialRef,
    required this.initialText,
  });

  @override
  State<PosterCreatorScreen> createState() => _PosterCreatorScreenState();
}

class _PosterCreatorScreenState extends State<PosterCreatorScreen> {
  late TextEditingController _textController;
  final TextEditingController _nameController =
      TextEditingController(text: 'விசுவாசி (Believer)');

  int _selectedColor = 0xFF1E2A4A;

  final List _bgOptions = [
    0xFF1E2A4A, // ஆழமான நீலம்
    0xFF1B363D, // அமைதிப் பச்சை
    0xFF2B2144, // ராஜரீக ஊதா
    0xFF3A243B, // மென்மையான மெரூன்
    0xFF252836, // கிளாசிக் டார்க்
    0xFF1F332B, // ஆலிவ் பச்சை
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _textController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _publishPoster() async {
    final text = _textController.text.trim();
    final author = _nameController.text.trim().isEmpty
        ? 'விசுவாசி'
        : _nameController.text.trim();
    if (text.isEmpty) return;

    await DatabaseHelper.instance.addUserPoster(
      category: widget.category,
      refTitle: widget.initialRef,
      verseText: text,
      authorName: author,
      bgColor: _selectedColor,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isPromise = widget.category == 'promise';
    return Scaffold(
      backgroundColor: const Color(0xFF12141D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181A24),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isPromise
              ? 'வாக்குத்தத்த போஸ்டர் உருவாக்கு'
              : 'விசுவாச அறிக்கை போஸ்டர்',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // நேரடி முன்னோட்டம் (Live Poster Preview)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(_selectedColor),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPromise ? 'இன்றைய வாக்குத்தத்தம்' : 'இன்றைய விசுவாச அறிக்கை',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _textController.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.initialRef,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '— ${_nameController.text}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'பின்னணி வண்ணம் தேர்வு செய்க:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: _bgOptions.map((colorVal) {
                final bool selected = _selectedColor == colorVal;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorVal),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Color(colorVal),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.amberAccent : Colors.white24,
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            const Text(
              'உங்கள் பெயர்:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E1E2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'வசனம்:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, height: 1.4),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E1E2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _publishPoster,
                icon: const Icon(Icons.publish_rounded),
                label: const Text(
                  'போஸ்டரைப் பதிவிடு (Publish)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
