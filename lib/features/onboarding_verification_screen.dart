import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/local/database_helper.dart';

class OnboardingVerificationScreen extends StatefulWidget {
  final VoidCallback onVerificationCompleted;

  const OnboardingVerificationScreen({
    super.key,
    required this.onVerificationCompleted,
  });

  @override
  State createState() => _OnboardingVerificationScreenState();
}

class _OnboardingVerificationScreenState extends State {
  OnboardingVerificationScreen get _w =>
      widget as OnboardingVerificationScreen;

  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1: Mandatory Live Front-Camera Selfie
  String? _verifiedSelfiePath;

  // Step 2: Real Name, New Name & Church / Seeker Status
  final TextEditingController _realNameCtrl = TextEditingController();
  final TextEditingController _newNameCtrl = TextEditingController();
  final TextEditingController _customChurchCtrl = TextEditingController();

  String _selectedChurchType = 'பெந்தெகொஸ்தே சபை (Pentecostal / AG / TPM)';
  final List _churchOptions = [
    'பெந்தெகொஸ்தே சபை (Pentecostal / AG / TPM)',
    'தென்னிந்திய திருச்சபை (CSI)',
    'பாப்டிஸ்ட் சபை (Baptist)',
    'எவாஞ்சலிக்கல் / சுயாதீன சபை (Evangelical / Independent)',
    'லூத்தரன் / மெதடிஸ்ட் சபை (Lutheran / Methodist)',
    'எந்த சபைக்கும் செல்லவில்லை (Not attending any church)',
    'புதிய ஆத்மா — இயேசுவை அறிந்துகொள்ள விரும்புகிறேன் (New Soul / Seeker)',
  ];

  // Step 3: Spiritual Preferences for Friend Matching
  String _favoriteBook = 'சங்கீதம் (Psalms)';
  String _favoriteCategory = 'ஜெபம் & பரிந்துபேசுதல் (Prayer)';
  final TextEditingController _favoriteVerseCtrl = TextEditingController();
  final TextEditingController _favoriteSongCtrl = TextEditingController();

  final List _popularBooks = [
    'ஆதியாகமம் (Genesis)',
    'சங்கீதம் (Psalms)',
    'நீதிமொழிகள் (Proverbs)',
    'ஏசாயா (Isaiah)',
    'மத்தேயு (Matthew)',
    'யோவான் (John)',
    'அப்போஸ்தலர் (Acts)',
    'ரோமர் (Romans)',
    'எபேசியர் (Ephesians)',
    'வெளிப்படுத்தின விசேஷம் (Revelation)',
  ];

  final List _spiritualCategories = [
    'ஜெபம் & பரிந்துபேசுதல் (Prayer)',
    'பாடல் & ஆராதனை (Worship & Music)',
    'வேத ஆராய்ச்சி (Bible Study)',
    'வாலிபர் ஐக்கியம் (Youth Fellowship)',
    'சுவிசேஷ ஊழியம் (Evangelism)',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _realNameCtrl.dispose();
    _newNameCtrl.dispose();
    _customChurchCtrl.dispose();
    _favoriteVerseCtrl.dispose();
    _favoriteSongCtrl.dispose();
    super.dispose();
  }

  Future _captureLiveSelfie() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 75,
    );
    if (photo != null && mounted) {
      setState(() {
        _verifiedSelfiePath = photo.path;
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_verifiedSelfiePath == null || _verifiedSelfiePath!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'பாதுகாப்பு சரிபார்ப்பிற்காக உங்கள் நேரடி செல்ஃபி படத்தை முதலில் எடுக்கவும்.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_realNameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('உங்கள் இயற்பெயரை உள்ளிடவும்.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      setState(() => _currentStep = 2);
    }
  }

  Future _completeRegistration() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final db = await DatabaseHelper.instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        id INTEGER PRIMARY KEY,
        user_name TEXT NOT NULL,
        new_name TEXT NOT NULL DEFAULT '',
        church_city TEXT NOT NULL,
        church_type TEXT NOT NULL DEFAULT '',
        life_verse TEXT NOT NULL,
        favorite_book TEXT NOT NULL DEFAULT '',
        favorite_song TEXT NOT NULL DEFAULT '',
        spiritual_category TEXT NOT NULL DEFAULT '',
        avatar_path TEXT,
        verification_selfie_path TEXT,
        is_verified INTEGER NOT NULL DEFAULT 0,
        daily_reminder INTEGER NOT NULL DEFAULT 1,
        prayer_reminder INTEGER NOT NULL DEFAULT 1
      )
    ''');

    final alterCols = [
      "ALTER TABLE user_profile ADD COLUMN new_name TEXT NOT NULL DEFAULT ''",
      "ALTER TABLE user_profile ADD COLUMN church_type TEXT NOT NULL DEFAULT ''",
      "ALTER TABLE user_profile ADD COLUMN favorite_book TEXT NOT NULL DEFAULT ''",
      "ALTER TABLE user_profile ADD COLUMN favorite_song TEXT NOT NULL DEFAULT ''",
      "ALTER TABLE user_profile ADD COLUMN spiritual_category TEXT NOT NULL DEFAULT ''",
      "ALTER TABLE user_profile ADD COLUMN verification_selfie_path TEXT",
      "ALTER TABLE user_profile ADD COLUMN is_verified INTEGER NOT NULL DEFAULT 0",
    ];
    for (final sql in alterCols) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }

    final realName = _realNameCtrl.text.trim();
    final newName = _newNameCtrl.text.trim().isEmpty
        ? 'கர்த்தருடைய பிள்ளை'
        : _newNameCtrl.text.trim();
    final churchDetail = _customChurchCtrl.text.trim().isEmpty
        ? _selectedChurchType
        : '${_customChurchCtrl.text.trim()} ($_selectedChurchType)';
    final lifeVerse = _favoriteVerseCtrl.text.trim().isEmpty
        ? 'கர்த்தர் என் மேய்ப்பராயிருக்கிறார்; நான் தாழ்ச்சியடையேன். — சங்கீதம் 23:1'
        : _favoriteVerseCtrl.text.trim();
    final favSong = _favoriteSongCtrl.text.trim().isEmpty
        ? 'என் இயேசுவே என் ஆத்தும நேசரே'
        : _favoriteSongCtrl.text.trim();

    final existing = await db.query('user_profile', where: 'id = 1');
    final rowData = {
      'id': 1,
      'user_name': realName,
      'new_name': newName,
      'church_city': churchDetail,
      'church_type': _selectedChurchType,
      'life_verse': lifeVerse,
      'favorite_book': _favoriteBook,
      'favorite_song': favSong,
      'spiritual_category': _favoriteCategory,
      'verification_selfie_path': _verifiedSelfiePath,
      'is_verified': 1,
      'daily_reminder': 1,
      'prayer_reminder': 1,
    };

    if (existing.isEmpty) {
      await db.insert('user_profile', rowData);
    } else {
      await db.update('user_profile', rowData, where: 'id = 1');
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    _w.onVerificationCompleted();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0F1115);
    const Color cardDark = Color(0xFF181A24);
    const Color goldAccent = Color(0xFFE4AF37);

    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              color: cardDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: goldAccent, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'THE HOLY NATION • உறுப்பினர் சரிபார்ப்பு',
                        style: TextStyle(
                          color: goldAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildStepBar(0, '1. செல்ஃபி பாதுகாப்பு'),
                      const SizedBox(width: 6),
                      _buildStepBar(1, '2. புதிய நாமம் & சபை'),
                      const SizedBox(width: 6),
                      _buildStepBar(2, '3. ஆவிக்குரிய விருப்பம்'),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Selfie(cardDark, goldAccent),
                  _buildStep2NewNameAndChurch(cardDark, goldAccent),
                  _buildStep3Interests(cardDark, goldAccent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBar(int index, String label) {
    final bool active = _currentStep >= index;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFE4AF37) : Colors.white12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? Colors.white : Colors.white38,
              fontSize: 10.5,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Selfie(Color cardDark, Color goldAccent) {
    final bool hasSelfie = _verifiedSelfiePath != null &&
        _verifiedSelfiePath!.isNotEmpty &&
        File(_verifiedSelfiePath!).existsSync();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: goldAccent.withValues(alpha: 0.4)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_rounded, color: Color(0xFFE4AF37)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'பாதுகாப்பு எச்சரிக்கை & விழிப்புணர்வு:\nஇந்த ஆவிக்குரிய சமூகத்தைத் தவறான நபர்களிடமிருந்து பாதுகாக்க, உங்கள் முகத்தை நேரடி செல்ஃபி கேமராவில் படம் பிடிப்பது கட்டாயமாகும். இந்தப் படம் உங்கள் அடையாளப் பாதுகாப்பிற்காக மறைமுகமாக மட்டுமே சேமிக்கப்படும்; பொது சுயவிவரத்தில் (Public Profile) உங்கள் விருப்பமான படத்தை வைத்துக்கொள்ளலாம்.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardDark,
              border: Border.all(
                color: hasSelfie ? Colors.tealAccent : goldAccent,
                width: 3,
              ),
              image: hasSelfie
                  ? DecorationImage(
                      image: FileImage(File(_verifiedSelfiePath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasSelfie
                ? null
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.face_retouching_natural,
                          size: 64, color: Color(0xFFE4AF37)),
                      SizedBox(height: 8),
                      Text(
                        'நேரடி செல்ஃபி தேவை',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: cardDark,
              foregroundColor: goldAccent,
              side: BorderSide(color: goldAccent),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: const Icon(Icons.camera_front_rounded),
            label: Text(
              hasSelfie
                  ? 'மீண்டும் செல்ஃபி எடு (Retake)'
                  : 'செல்ஃபி கேமராவைத் திற (Take Live Selfie)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _captureLiveSelfie,
          ),
          if (hasSelfie) ...[
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.tealAccent, size: 18),
                SizedBox(width: 6),
                Text(
                  'முகச் சரிபார்ப்பு வெற்றிகரமாகப் பதியப்பட்டது (Private ID)',
                  style: TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: goldAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _nextStep,
              child: const Text(
                'அடுத்த படி (Next) →',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2NewNameAndChurch(Color cardDark, Color goldAccent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse Box for New Name
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2238),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: goldAccent.withValues(alpha: 0.4)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📖 கர்த்தர் அழைக்கும் புதிய நாமம் (ஏசாயா 62:2 / வெளி 2:17)',
                  style: TextStyle(
                    color: Color(0xFFE4AF37),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '"கர்த்தருடைய வாயினால் சொல்லப்படும் புதிய நாமத்தினால் அழைக்கப்படுவாய்." கிறிஸ்துவுக்குள் நாம் புது சிருஷ்டியாக மாறும்போது, தேவன் நமக்குத் தரும் ஆவிக்குரிய அடையாளமே இந்தப் புதிய நாமம்.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'உங்கள் இயற்பெயர் (Real Name) *',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _realNameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'உங்கள் பெயரை உள்ளிடவும்',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'நீங்கள் தேர்ந்தெடுக்கும் புதிய நாமம் (Chosen New Name)',
            style: TextStyle(
                color: Color(0xFFE4AF37), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _newNameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'உதா: கிருபையின் மகன் / விசுவாச வீரன் / சமாதானப் புத்திரி',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
              filled: true,
              fillColor: cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'நீங்கள் பின்பற்றும் சபை / நிலை (Church / Spiritual Status)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton(
                value: _selectedChurchType,
                isExpanded: true,
                dropdownColor: cardDark,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                items: [
                  for (final ch in _churchOptions)
                    DropdownMenuItem(
                      value: ch,
                      child: Text(ch),
                    ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedChurchType = val.toString());
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _customChurchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'உங்கள் சபையின் பெயர் & ஊர் (விருப்பம்)',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              filled: true,
              fillColor: cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                  setState(() => _currentStep = 0);
                },
                child: const Text('← பின்செல்'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _nextStep,
                  child: const Text(
                    'அடுத்த படி (Next) →',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Interests(Color cardDark, Color goldAccent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ஒத்த விருப்பமுள்ள நண்பர்களை இணைக்க கீழே உள்ளவற்றைத் தேர்ந்தெடுக்கவும்:',
            style: TextStyle(
              color: Colors.tealAccent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'விருப்பமான வேதாகம புத்தகம் (Favorite Bible Book)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton(
                value: _favoriteBook,
                isExpanded: true,
                dropdownColor: cardDark,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                items: [
                  for (final b in _popularBooks)
                    DropdownMenuItem(value: b, child: Text(b)),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _favoriteBook = val.toString());
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'விருப்பமான ஆவிக்குரிய பிரிவு (Spiritual Interest)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton(
                value: _favoriteCategory,
                isExpanded: true,
                dropdownColor: cardDark,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                items: [
                  for (final c in _spiritualCategories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _favoriteCategory = val.toString());
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'விருப்பமான வேத வசனம் (Favorite Verse)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _favoriteVerseCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'உதா: பிலிப்பியர் 4:13 / சங்கீதம் 23:1',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'விருப்பமான கிறிஸ்தவப் பாடல் (Favorite Worship Song)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _favoriteSongCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'உதா: உம்மைப் போல யாருமில்லை / என் இயேசுவே',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                  setState(() => _currentStep = 1);
                },
                child: const Text('← பின்செல்'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isSaving
                        ? 'சேமிக்கிறது...'
                        : 'செயலிக்குள் நுழை (Enter App)',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: _isSaving ? null : _completeRegistration,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
