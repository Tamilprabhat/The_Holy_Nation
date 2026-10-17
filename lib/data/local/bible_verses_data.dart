class BibleVersesData {
  // மாதிரி தரவு: ஒவ்வொரு புத்தகத்திற்கும் 2 அதிகாரங்கள், ஒவ்வொரு அதிகாரத்திற்கும் 5 வசனங்கள்
  static List<Map<String, dynamic>> generateMockVerses() {
    List<Map<String, dynamic>> verses = [];
    int verseId = 1;

    for (int bookId = 1; bookId <= 66; bookId++) {
      for (int chapter = 1; chapter <= 2; chapter++) { // 2 அதிகாரங்கள்
        for (int verse = 1; verse <= 5; verse++) { // 5 வசனங்கள்
          verses.add({
            'id': verseId++,
            'book_id': bookId,
            'chapter': chapter,
            'verse': verse,
            'text_ta': 'இது புத்தகம் $bookId, அதிகாரம் $chapter, வசனம் $verse க்கான மாதிரித் தமிழ் வசனம். தேவனுடைய வார்த்தை என்றென்றைக்கும் நிலைத்திருக்கும்.',
            'text_en': 'This is a sample English verse for Book $bookId, Chapter $chapter, Verse $verse. The word of God stands forever.',
          });
        }
      }
    }
    return verses;
  }
}
