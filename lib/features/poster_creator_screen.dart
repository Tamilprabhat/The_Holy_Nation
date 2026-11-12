import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  File? _pickedImageFile;
  double _overlayDarkness = 0.45;
  int _selectedPresetIndex = 0;

  // பலதரப்பட்ட வண்ணங்கள் & AI ஆவிக்குரிய தீம்கள்
  final List _presets = [
    {
      'name': 'வான மகிமை',
      'primary': 0xFF1E2A4A,
      'secondary': 0xFF3949AB,
      'icon': Icons.wb_sunny_outlined,
    },
    {
      'name': 'அமைதி நதி',
      'primary': 0xFF133B3A,
      'secondary': 0xFF00796B,
      'icon': Icons.water_outlined,
    },
    {
      'name': 'சிலுவை ஒளி',
      'primary': 0xFF3B1D36,
      'secondary': 0xFF8E24AA,
      'icon': Icons.auto_awesome,
    },
    {
      'name': 'பொன் காலை',
      'primary': 0xFF4A2C11,
      'secondary': 0xFFE65100,
      'icon': Icons.landscape_outlined,
    },
    {
      'name': 'இரவு நட்சத்திரம்',
      'primary': 0xFF141824,
      'secondary': 0xFF283593,
      'icon': Icons.nights_stay_outlined,
    },
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

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() {
        _pickedImageFile = File(picked.path);
      });
    }
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
      imagePath: _pickedImageFile?.path,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isPromise = widget.category == 'promise';
    final preset = _presets[_selectedPresetIndex];

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
            // நேரடி போஸ்டர் முன்னோட்டம் (Instagram / Facebook Style Card)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 220),
                decoration: BoxDecoration(
                  gradient: _pickedImageFile == null
                      ? LinearGradient(
                          colors: [
                            Color(preset['primary']),
                            Color(preset['secondary']),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  image: _pickedImageFile != null
                      ? DecorationImage(
                          image: FileImage(_pickedImageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _pickedImageFile != null
                        ? Colors.black.withValues(alpha: _overlayDarkness)
                        : Colors.transparent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isPromise
                              ? 'இன்றைய வாக்குத்தத்தம்'
                              : 'இன்றைய விசுவாச அறிக்கை',
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _textController.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.55,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.initialRef,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '— ${_nameController.text} • THE HOLY NATION',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // கேலரி புகைப்படம் தேர்வு பொத்தான்
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25293A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.indigoAccent),
                      ),
                    ),
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_rounded,
                        color: Colors.amberAccent),
                    label: Text(
                      _pickedImageFile == null
                          ? 'கேலரியிலிருந்து புகைப்படம் சேர்'
                          : 'வேறொரு புகைப்படம் மாற்று',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (_pickedImageFile != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                    ),
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () => setState(() => _pickedImageFile = null),
                  ),
                ],
              ],
            ),

            if (_pickedImageFile != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'எழுத்து தெளிவு (Dark Overlay):',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Expanded(
                    child: Slider(
                      value: _overlayDarkness,
                      min: 0.1,
                      max: 0.8,
                      activeColor: Colors.indigoAccent,
                      onChanged: (val) =>
                          setState(() => _overlayDarkness = val),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),
            const Text(
              'அல்லது ஆவிக்குரிய வண்ண தீம்கள் (Themes):',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _presets.length,
                itemBuilder: (context, index) {
                  final item = _presets[index];
                  final bool isSelected =
                      _pickedImageFile == null && _selectedPresetIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _pickedImageFile = null;
                        _selectedPresetIndex = index;
                        _selectedColor = item['primary'];
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(item['primary']),
                            Color(item['secondary']),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? Colors.amberAccent
                              : Colors.white24,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(item['icon'], size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            item['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),
            const Text(
              'உங்கள் பெயர்:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 6),
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

            const SizedBox(height: 14),
            const Text(
              'வசனம் (தேவைப்பட்டால் திருத்தலாம்):',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 6),
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

            const SizedBox(height: 22),
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
