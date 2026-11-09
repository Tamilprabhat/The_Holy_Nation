import os
import sys
import json
import sqlite3
import subprocess
import urllib.request

def build_database():
    source_dir = "bible_source"
    if not os.path.exists(source_dir):
        print("Cloning complete Bible dataset...")
        try:
            subprocess.run(
                ["git", "clone", "--depth", "1", "https://github.com/godlytalias/Bible-Database.git", source_dir],
                check=True
            )
        except Exception as e:
            print(f"Git clone error: {e}. Downloading directly...")
            os.makedirs(os.path.join(source_dir, "Tamil"), exist_ok=True)
            os.makedirs(os.path.join(source_dir, "English (KJV)"), exist_ok=True)
            urllib.request.urlretrieve(
                "https://raw.githubusercontent.com/godlytalias/Bible-Database/master/Tamil/bible.json",
                os.path.join(source_dir, "Tamil", "bible.json")
            )
            urllib.request.urlretrieve(
                "https://raw.githubusercontent.com/godlytalias/Bible-Database/master/English%20(KJV)/bible.json",
                os.path.join(source_dir, "English (KJV)", "bible.json")
            )

    tamil_path = os.path.join(source_dir, "Tamil", "bible.json")
    english_path = os.path.join(source_dir, "English (KJV)", "bible.json")

    with open(tamil_path, "r", encoding="utf-8") as f:
        ta_data = json.load(f)
    with open(english_path, "r", encoding="utf-8") as f:
        en_data = json.load(f)

    ta_books = ta_data.get("books", ta_data) if isinstance(ta_data, dict) else ta_data
    en_books = en_data.get("books", en_data) if isinstance(en_data, dict) else en_data

    os.makedirs("assets", exist_ok=True)
    db_path = os.path.join("assets", "holy_nation.db")
    if os.path.exists(db_path):
        os.remove(db_path)

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    cur.execute('''
    CREATE TABLE books (
        id INTEGER PRIMARY KEY,
        name_ta TEXT NOT NULL,
        name_en TEXT NOT NULL,
        testament TEXT NOT NULL,
        chapters_count INTEGER NOT NULL
    );
    ''')

    cur.execute('''
    CREATE TABLE verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        text_ta TEXT NOT NULL,
        text_en TEXT NOT NULL
    );
    ''')

    cur.execute('CREATE INDEX idx_verses_book_chapter ON verses (book_id, chapter);')

    books_rows = []
    verses_rows = []

    total_books = len(ta_books)
    for b_idx in range(total_books):
        book_id = b_idx + 1
        b_ta = ta_books[b_idx]
        b_en = en_books[b_idx] if b_idx < len(en_books) else {}

        name_ta = str(b_ta.get("name", "")).strip() or f"புத்தகம் {book_id}"
        name_en = str(b_en.get("name", "")).strip() or f"Book {book_id}"
        testament = "Old Testament" if book_id <= 39 else "New Testament"

        ta_chaps = b_ta.get("chapters", []) if isinstance(b_ta, dict) else []
        en_chaps = b_en.get("chapters", []) if isinstance(b_en, dict) else []

        ch_count = max(len(ta_chaps), len(en_chaps))
        books_rows.append((book_id, name_ta, name_en, testament, ch_count))

        for c_idx in range(ch_count):
            chap_num = c_idx + 1
            ta_c = ta_chaps[c_idx] if c_idx < len(ta_chaps) else {}
            en_c = en_chaps[c_idx] if c_idx < len(en_chaps) else {}

            ta_v_list = ta_c.get("verses", []) if isinstance(ta_c, dict) else []
            en_v_list = en_c.get("verses", []) if isinstance(en_c, dict) else []

            v_count = max(len(ta_v_list), len(en_v_list))
            for v_idx in range(v_count):
                verse_num = v_idx + 1

                ta_item = ta_v_list[v_idx] if v_idx < len(ta_v_list) else ""
                if isinstance(ta_item, dict):
                    verse_num = int(ta_item.get("verse", verse_num))
                    ta_text = ta_item.get("text", "")
                else:
                    ta_text = str(ta_item)

                en_item = en_v_list[v_idx] if v_idx < len(en_v_list) else ""
                if isinstance(en_item, dict):
                    en_text = en_item.get("text", "")
                else:
                    en_text = str(en_item)

                verses_rows.append((book_id, chap_num, verse_num, str(ta_text).strip(), str(en_text).strip()))

    cur.executemany("INSERT INTO books VALUES (?, ?, ?, ?, ?)", books_rows)
    cur.executemany("INSERT INTO verses (book_id, chapter, verse, text_ta, text_en) VALUES (?, ?, ?, ?, ?)", verses_rows)

    conn.commit()
    print(f"Done! Inserted {len(books_rows)} books and {len(verses_rows)} verses.")
    conn.close()

if __name__ == "__main__":
    build_database()
