import os
import sys
import json
import sqlite3
import subprocess
import urllib.request

# 1. முழுமையான 66 புத்தகங்களின் பட்டியல் மற்றும் அதிகாரங்களின் எண்ணிக்கை
BOOKS_DATA = [
    (1, "ஆதியாகமம்", "Genesis", "Old Testament", 50),
    (2, "யாத்திராகமம்", "Exodus", "Old Testament", 40),
    (3, "லேவியராகமம்", "Leviticus", "Old Testament", 27),
    (4, "எண்ணாகமம்", "Numbers", "Old Testament", 36),
    (5, "உபாகமம்", "Deuteronomy", "Old Testament", 34),
    (6, "யோசுவா", "Joshua", "Old Testament", 24),
    (7, "நியாயாதிபதிகள்", "Judges", "Old Testament", 21),
    (8, "ரூத்", "Ruth", "Old Testament", 4),
    (9, "1 சாமுவேல்", "1 Samuel", "Old Testament", 31),
    (10, "2 சாமுவேல்", "2 Samuel", "Old Testament", 24),
    (11, "1 ராஜாக்கள்", "1 Kings", "Old Testament", 22),
    (12, "2 ராஜாக்கள்", "2 Kings", "Old Testament", 25),
    (13, "1 நாளாகமம்", "1 Chronicles", "Old Testament", 29),
    (14, "2 நாளாகமம்", "2 Chronicles", "Old Testament", 36),
    (15, "எஸ்றா", "Ezra", "Old Testament", 10),
    (16, "நெகேமியா", "Nehemiah", "Old Testament", 13),
    (17, "எஸ்தர்", "Esther", "Old Testament", 10),
    (18, "யோபு", "Job", "Old Testament", 42),
    (19, "சங்கீதம்", "Psalms", "Old Testament", 150),
    (20, "நீதிமொழிகள்", "Proverbs", "Old Testament", 31),
    (21, "பிரசங்கி", "Ecclesiastes", "Old Testament", 12),
    (22, "உன்னதப்பாட்டு", "Song of Solomon", "Old Testament", 8),
    (23, "ஏசாயா", "Isaiah", "Old Testament", 66),
    (24, "எரேமியா", "Jeremiah", "Old Testament", 52),
    (25, "புலம்பல்", "Lamentations", "Old Testament", 5),
    (26, "எசேக்கியேல்", "Ezekiel", "Old Testament", 48),
    (27, "தானியேல்", "Daniel", "Old Testament", 12),
    (28, "ஓசியா", "Hosea", "Old Testament", 14),
    (29, "யோவேல்", "Joel", "Old Testament", 3),
    (30, "ஆமோஸ்", "Amos", "Old Testament", 9),
    (31, "ஒபதியா", "Obadiah", "Old Testament", 1),
    (32, "யோனா", "Jonah", "Old Testament", 4),
    (33, "மீகா", "Micah", "Old Testament", 7),
    (34, "நாகூம்", "Nahum", "Old Testament", 3),
    (35, "ஆபகூக்", "Habakkuk", "Old Testament", 3),
    (36, "செப்பனியா", "Zephaniah", "Old Testament", 3),
    (37, "ஆகாய்", "Haggai", "Old Testament", 2),
    (38, "சகரியா", "Zechariah", "Old Testament", 14),
    (39, "மல்கியா", "Malachi", "Old Testament", 4),
    (40, "மத்தேயு", "Matthew", "New Testament", 28),
    (41, "மாற்கு", "Mark", "New Testament", 16),
    (42, "லூக்கா", "Luke", "New Testament", 24),
    (43, "யோவான்", "John", "New Testament", 21),
    (44, "அப்போஸ்தலர்", "Acts", "New Testament", 28),
    (45, "ரோமர்", "Romans", "New Testament", 16),
    (46, "1 கொரிந்தியர்", "1 Corinthians", "New Testament", 16),
    (47, "2 கொரிந்தியர்", "2 Corinthians", "New Testament", 13),
    (48, "கலாத்தியர்", "Galatians", "New Testament", 6),
    (49, "எபேசியர்", "Ephesians", "New Testament", 6),
    (50, "பிலிப்பியர்", "Philippians", "New Testament", 4),
    (51, "கொலோசெயர்", "Colossians", "New Testament", 4),
    (52, "1 தெசலோனிக்கேயர்", "1 Thessalonians", "New Testament", 5),
    (53, "2 தெசலோனிக்கேயர்", "2 Thessalonians", "New Testament", 3),
    (54, "1 தீமோத்தேயு", "1 Timothy", "New Testament", 6),
    (55, "2 தீமோத்தேயு", "2 Timothy", "New Testament", 4),
    (56, "தீத்து", "Titus", "New Testament", 3),
    (57, "பிலேமோன்", "Philemon", "New Testament", 1),
    (58, "எபிரெயர்", "Hebrews", "New Testament", 13),
    (59, "யாக்கோபு", "James", "New Testament", 5),
    (60, "1 பேதுரு", "1 Peter", "New Testament", 5),
    (61, "2 பேதுரு", "2 Peter", "New Testament", 3),
    (62, "1 யோவான்", "1 John", "New Testament", 5),
    (63, "2 யோவான்", "2 John", "New Testament", 1),
    (64, "3 யோவான்", "3 John", "New Testament", 1),
    (65, "யூதா", "Jude", "New Testament", 1),
    (66, "வெளிப்படுத்தின விசேஷம்", "Revelation", "New Testament", 22)
]

def load_bible_data():
    source_dir = "bible_source"
    if not os.path.exists(source_dir):
        print("Cloning complete Bible dataset from repository...")
        try:
            subprocess.run(["git", "clone", "--depth", "1", "https://github.com/godlytalias/Bible-Database.git", source_dir], check=True)
        except Exception as e:
            print(f"Git clone error: {e}. Trying direct download...")
            os.makedirs(os.path.join(source_dir, "Tamil"), exist_ok=True)
            os.makedirs(os.path.join(source_dir, "English (KJV)"), exist_ok=True)
            urllib.request.urlretrieve("https://raw.githubusercontent.com/godlytalias/Bible-Database/master/Tamil/bible.json", os.path.join(source_dir, "Tamil", "bible.json"))
            urllib.request.urlretrieve("https://raw.githubusercontent.com/godlytalias/Bible-Database/master/English%20(KJV)/bible.json", os.path.join(source_dir, "English (KJV)", "bible.json"))

    tamil_path = os.path.join(source_dir, "Tamil", "bible.json")
    english_path = os.path.join(source_dir, "English (KJV)", "bible.json")

    def parse_file(path):
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        books = data["books"] if isinstance(data, dict) and "books" in data else data
        verse_dict = {}
        for b_idx, book in enumerate(books, 1):
            chapters = book.get("chapters", []) if isinstance(book, dict) else []
            for c_idx, chap in enumerate(chapters, 1):
                ch_num = int(chap.get("chapter", c_idx)) if isinstance(chap, dict) else c_idx
                verses = chap.get("verses", []) if isinstance(chap, dict) else []
                for v_idx, v in enumerate(verses, 1):
                    if isinstance(v, dict):
                        v_num = int(v.get("verse", v_idx))
                        v_text = v.get("text", "")
                    else:
                        v_num = v_idx
                        v_text = str(v)
                    verse_dict[(b_idx, ch_num, v_num)] = v_text.strip()
        return verse_dict

    print("Parsing Tamil and English verses...")
    tamil_verses = parse_file(tamil_path)
    english_verses = parse_file(english_path)
    return tamil_verses, english_verses

def create_database():
    os.makedirs("assets", exist_ok=True)
    db_path = os.path.join("assets", "holy_nation.db")
    if os.path.exists(db_path):
        os.remove(db_path)

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Books Table
    cursor.execute('''
    CREATE TABLE books (
        id INTEGER PRIMARY KEY,
        name_ta TEXT NOT NULL,
        name_en TEXT NOT NULL,
        testament TEXT NOT NULL,
        chapters_count INTEGER NOT NULL
    );
    ''')

    # Verses Table
    cursor.execute('''
    CREATE TABLE verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        text_ta TEXT NOT NULL,
        text_en TEXT NOT NULL
    );
    ''')

    # Fast Query Index
    cursor.execute('CREATE INDEX idx_verses_book_chapter ON verses (book_id, chapter);')

    # 1. 66 புத்தகங்களைச் சேர்த்தல்
    cursor.executemany(
        "INSERT INTO books (id, name_ta, name_en, testament, chapters_count) VALUES (?, ?, ?, ?, ?)",
        BOOKS_DATA
    )
    print(f"66 Books inserted successfully.")

    # 2. 31,102 வசனங்களைச் சேர்த்தல்
    tamil_verses, english_verses = load_bible_data()
    all_keys = sorted(set(list(tamil_verses.keys()) + list(english_verses.keys())))

    verses_rows = []
    for (b_id, ch, v) in all_keys:
        ta_text = tamil_verses.get((b_id, ch, v), "")
        en_text = english_verses.get((b_id, ch, v), "")
        verses_rows.append((b_id, ch, v, ta_text, en_text))

    cursor.executemany(
        "INSERT INTO verses (book_id, chapter, verse, text_ta, text_en) VALUES (?, ?, ?, ?, ?)",
        verses_rows
    )
    conn.commit()
    print(f"Success! {len(verses_rows)} bilingual verses inserted into holy_nation.db.")
    conn.close()

if __name__ == "__main__":
    create_database()
