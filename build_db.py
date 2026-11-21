import os
import sys
import json
import sqlite3
import subprocess

BOOKS_META = [
    (1, "ஆதியாகமம்", "Genesis", 50),
    (2, "யாத்திராகமம்", "Exodus", 40),
    (3, "லேவியராகமம்", "Leviticus", 27),
    (4, "எண்ணாகமம்", "Numbers", 36),
    (5, "உபாகமம்", "Deuteronomy", 34),
    (6, "யோசுவா", "Joshua", 24),
    (7, "நியாயாதிபதிகள்", "Judges", 21),
    (8, "ரூத்", "Ruth", 4),
    (9, "1 சாமுவேல்", "1 Samuel", 31),
    (10, "2 சாமுவேல்", "2 Samuel", 24),
    (11, "1 இராஜாக்கள்", "1 Kings", 22),
    (12, "2 இராஜாக்கள்", "2 Kings", 25),
    (13, "1 நாளாகமம்", "1 Chronicles", 29),
    (14, "2 நாளாகமம்", "2 Chronicles", 36),
    (15, "எஸ்றா", "Ezra", 10),
    (16, "நெகேமியா", "Nehemiah", 13),
    (17, "எஸ்தர்", "Esther", 10),
    (18, "யோபு", "Job", 42),
    (19, "சங்கீதம்", "Psalms", 150),
    (20, "நீதிமொழிகள்", "Proverbs", 31),
    (21, "பிரசங்கி", "Ecclesiastes", 12),
    (22, "உன்னதப்பாட்டு", "Song of Solomon", 8),
    (23, "ஏசாயா", "Isaiah", 66),
    (24, "எரேமியா", "Jeremiah", 52),
    (25, "புலம்பல்", "Lamentations", 5),
    (26, "எசேக்கியேல்", "Ezekiel", 48),
    (27, "தானியேல்", "Daniel", 12),
    (28, "ஓசியா", "Hosea", 14),
    (29, "யோவேல்", "Joel", 3),
    (30, "ஆமோஸ்", "Amos", 9),
    (31, "ஒபதியா", "Obadiah", 1),
    (32, "யோனா", "Jonah", 4),
    (33, "மீகா", "Micah", 7),
    (34, "நாகூம்", "Nahum", 3),
    (35, "ஆபகூக்", "Habakkuk", 3),
    (36, "செப்பனியா", "Zephaniah", 3),
    (37, "ஆகாய்", "Haggai", 2),
    (38, "சகரியா", "Zechariah", 14),
    (39, "மல்கியா", "Malachi", 4),
    (40, "மத்தேயு", "Matthew", 28),
    (41, "மாற்கு", "Mark", 16),
    (42, "லூக்கா", "Luke", 24),
    (43, "யோவான்", "John", 21),
    (44, "அப்போஸ்தலர்", "Acts", 28),
    (45, "ரோமர்", "Romans", 16),
    (46, "1 கொரிந்தியர்", "1 Corinthians", 16),
    (47, "2 கொரிந்தியர்", "2 Corinthians", 13),
    (48, "கலாத்தியர்", "Galatians", 6),
    (49, "எபேசியர்", "Ephesians", 6),
    (50, "பிலிப்பியர்", "Philippians", 4),
    (51, "கொலோசெயர்", "Colossians", 4),
    (52, "1 தெசலோனிக்கேயர்", "1 Thessalonians", 5),
    (53, "2 தெசலோனிக்கேயர்", "2 Thessalonians", 3),
    (54, "1 தீமோத்தேயு", "1 Timothy", 6),
    (55, "2 தீமோத்தேயு", "2 Timothy", 4),
    (56, "தீத்து", "Titus", 3),
    (57, "பிலேமோன்", "Philemon", 1),
    (58, "எபிரெயர்", "Hebrews", 13),
    (59, "யாக்கோபு", "James", 5),
    (60, "1 பேதுரு", "1 Peter", 5),
    (61, "2 பேதுரு", "2 Peter", 3),
    (62, "1 யோவான்", "1 John", 5),
    (63, "2 யோவான்", "2 John", 1),
    (64, "3 யோவான்", "3 John", 1),
    (65, "யூதா", "Jude", 1),
    (66, "வெளிப்படுத்தின விசேஷம்", "Revelation", 22),
]

LANG_CONFIGS = [
    ("ta", ["tamil"]),
    ("en", ["kjv", "english"]),
    ("hi", ["hindi"]),
    ("ml", ["malayalam"]),
    ("te", ["telugu"]),
    ("kn", ["kannada"]),
    ("bn", ["bengali"]),
    ("mr", ["marathi"]),
    ("gu", ["gujarati"]),
    ("pa", ["punjabi"]),
]


def to_books_list(data):
    if isinstance(data, list):
        return data
    if not isinstance(data, dict):
        return []
    for k in ["Book", "book", "books", "Books", "bible", "BIBLE"]:
        if k in data and isinstance(data[k], (list, dict)):
            return to_books_list(data[k])
    books = []
    try:
        keys = sorted(data.keys(), key=lambda x: int(x) if str(x).isdigit() else str(x))
    except Exception:
        keys = list(data.keys())
    for k in keys:
        if str(k).lower() in ["version", "language", "format", "title", "description", "creator"]:
            continue
        v = data[k]
        if isinstance(v, dict):
            if "name" not in v:
                v["name"] = k
            books.append(v)
        elif isinstance(v, list):
            books.append({"name": k, "chapters": v})
        else:
            books.append(v)
    return books


def to_chapters_list(book):
    if isinstance(book, list):
        return book
    if not isinstance(book, dict):
        return []
    for k in ["Chapter", "chapter", "chapters", "Chapters", "CHAPTER"]:
        if k in book and isinstance(book[k], (list, dict)):
            return to_chapters_list(book[k])
    chaps = []
    try:
        keys = sorted(book.keys(), key=lambda x: int(x) if str(x).isdigit() else str(x))
    except Exception:
        keys = list(book.keys())
    for k in keys:
        if str(k).lower() in ["name", "testament", "book_no", "book", "bookid"]:
            continue
        v = book[k]
        if isinstance(v, dict):
            if "chapter" not in v and "verses" not in v and "Verse" not in v:
                chaps.append({"chapter": k, "verses": v})
            else:
                if "chapter" not in v:
                    v["chapter"] = k
                chaps.append(v)
        elif isinstance(v, list):
            chaps.append({"chapter": k, "verses": v})
        else:
            chaps.append(v)
    return chaps


def to_verses_list(chap):
    if isinstance(chap, list):
        return chap
    if not isinstance(chap, dict):
        return []
    for k in ["Verse", "verse", "verses", "Verses", "VERSE"]:
        if k in chap and isinstance(chap[k], (list, dict)):
            return to_verses_list(chap[k])
    v_list = []
    try:
        keys = sorted(chap.keys(), key=lambda x: int(x) if str(x).isdigit() else str(x))
    except Exception:
        keys = list(chap.keys())
    for k in keys:
        if str(k).lower() in ["chapter", "name", "num", "chapterno"]:
            continue
        v = chap[k]
        if isinstance(v, dict):
            v_list.append(v)
        elif isinstance(v, str):
            v_list.append({"text": v})
        else:
            v_list.append(v)
    return v_list


def extract_verse_text(v_item):
    if isinstance(v_item, dict):
        v_text = (
            v_item.get("Verse")
            or v_item.get("text")
            or v_item.get("verse")
            or ""
        )
        return str(v_text).strip()
    elif isinstance(v_item, str):
        return v_item.strip()
    else:
        return str(v_item).strip()


def parse_bible_dict(file_path):
    if not file_path or not os.path.exists(file_path):
        return {}
    with open(file_path, "r", encoding="utf-8-sig") as f:
        data = json.load(f)
    v_dict = {}
    books = to_books_list(data)
    for b_idx, book in enumerate(books, 1):
        chaps = to_chapters_list(book)
        for c_idx, chap in enumerate(chaps, 1):
            verses = to_verses_list(chap)
            for v_idx, v_item in enumerate(verses, 1):
                text = extract_verse_text(v_item)
                if text:
                    v_dict[(b_idx, c_idx, v_idx)] = text
    return v_dict


def build_database():
    source_dir = "bible_source"
    if not os.path.exists(source_dir):
        print("Cloning complete Bible dataset...")
        subprocess.run(
            ["git", "clone", "--depth", "1", "https://github.com/godlytalias/Bible-Database.git", source_dir],
            check=True
        )

    lang_paths = {code: None for code, _ in LANG_CONFIGS}

    for root, dirs, files in os.walk(source_dir):
        for f in sorted(files):
            if f.endswith(".json"):
                full_path = os.path.join(root, f)
                lower_path = full_path.lower()
                for code, keywords in LANG_CONFIGS:
                    if lang_paths[code] is None and any(kw in lower_path for kw in keywords):
                        lang_paths[code] = full_path

    lang_dicts = {}
    for code, _ in LANG_CONFIGS:
        p = lang_paths[code]
        print(f"Parsing [{code}] from: {p}")
        parsed = parse_bible_dict(p)
        print(f"Total [{code}] verses parsed: {len(parsed)}")
        lang_dicts[code] = parsed

    if len(lang_dicts.get("ta", {})) == 0 and len(lang_dicts.get("en", {})) == 0:
        print("ERROR: No verses were parsed from JSON files.")
        sys.exit(1)

    os.makedirs("assets", exist_ok=True)
    db_path = os.path.join("assets", "holy_nation.db")
    if os.path.exists(db_path):
        os.remove(db_path)

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    cur.execute("""
    CREATE TABLE books (
        id INTEGER PRIMARY KEY,
        name_ta TEXT NOT NULL,
        name_en TEXT NOT NULL,
        testament TEXT NOT NULL,
        chapters_count INTEGER NOT NULL
    );
    """)

    cur.execute("""
    CREATE TABLE verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        text_ta TEXT NOT NULL,
        text_en TEXT NOT NULL,
        text_hi TEXT NOT NULL,
        text_ml TEXT NOT NULL,
        text_te TEXT NOT NULL,
        text_kn TEXT NOT NULL,
        text_bn TEXT NOT NULL,
        text_mr TEXT NOT NULL,
        text_gu TEXT NOT NULL,
        text_pa TEXT NOT NULL
    );
    """)

    cur.execute("CREATE INDEX idx_verses_book_chap ON verses (book_id, chapter);")

    books_rows = []
    for b_id, name_ta, name_en, ch_count in BOOKS_META:
        testament = "Old Testament" if b_id <= 39 else "New Testament"
        books_rows.append((b_id, name_ta, name_en, testament, ch_count))
    cur.executemany("INSERT INTO books VALUES (?, ?, ?, ?, ?)", books_rows)

    all_keys = sorted(set(list(lang_dicts["ta"].keys()) + list(lang_dicts["en"].keys())))
    verses_rows = []
    for (b_id, ch, v) in all_keys:
        verses_rows.append((
            b_id,
            ch,
            v,
            lang_dicts["ta"].get((b_id, ch, v), ""),
            lang_dicts["en"].get((b_id, ch, v), ""),
            lang_dicts["hi"].get((b_id, ch, v), ""),
            lang_dicts["ml"].get((b_id, ch, v), ""),
            lang_dicts["te"].get((b_id, ch, v), ""),
            lang_dicts["kn"].get((b_id, ch, v), ""),
            lang_dicts["bn"].get((b_id, ch, v), ""),
            lang_dicts["mr"].get((b_id, ch, v), ""),
            lang_dicts["gu"].get((b_id, ch, v), ""),
            lang_dicts["pa"].get((b_id, ch, v), ""),
        ))

    cur.executemany(
        """INSERT INTO verses (
            book_id, chapter, verse,
            text_ta, text_en, text_hi, text_ml, text_te,
            text_kn, text_bn, text_mr, text_gu, text_pa
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        verses_rows
    )

    conn.commit()
    print(f"Success! {len(books_rows)} books and {len(verses_rows)} multilingual verses inserted into holy_nation.db.")
    conn.close()


if __name__ == "__main__":
    build_database()
