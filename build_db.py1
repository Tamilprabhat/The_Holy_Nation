import urllib.request
import json
import sqlite3
import os

os.makedirs('assets', exist_ok=True)

print("Downloading Tamil & English Bibles...")
# தமிழ் மற்றும் ஆங்கில பைபிள் தரவுகளைப் பெறுதல்
req_ta = urllib.request.Request("https://raw.githubusercontent.com/godlytalias/Bible-Database/master/Tamil/bible.json")
with urllib.request.urlopen(req_ta) as response:
    ta_data = json.loads(response.read().decode('utf-8'))

req_en = urllib.request.Request("https://raw.githubusercontent.com/godlytalias/Bible-Database/master/English%20(KJV)/bible.json")
with urllib.request.urlopen(req_en) as response:
    en_data = json.loads(response.read().decode('utf-8'))

# SQLite Database உருவாக்குதல்
conn = sqlite3.connect('assets/holy_nation.db')
c = conn.cursor()

c.execute('''CREATE TABLE IF NOT EXISTS books (
                id INTEGER PRIMARY KEY,
                testament TEXT NOT NULL,
                name_ta TEXT NOT NULL,
                name_en TEXT NOT NULL)''')

c.execute('''CREATE TABLE IF NOT EXISTS verses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                book_id INTEGER NOT NULL,
                chapter INTEGER NOT NULL,
                verse INTEGER NOT NULL,
                text_ta TEXT NOT NULL,
                text_en TEXT NOT NULL,
                FOREIGN KEY (book_id) REFERENCES books (id))''')

book_id = 1
for ta_book, en_book in zip(ta_data, en_data):
    testament = 'OT' if book_id <= 39 else 'NT'
    c.execute('INSERT INTO books (id, testament, name_ta, name_en) VALUES (?, ?, ?, ?)', 
              (book_id, testament, ta_book['name'], en_book['name']))
    
    for ta_chapter, en_chapter in zip(ta_book['data'], en_book['data']):
        chapter_num = int(ta_chapter['chapter'])
        for v_num_str, text_ta in ta_chapter['verses'].items():
            verse_num = int(v_num_str)
            text_en = en_chapter['verses'].get(v_num_str, "")
            c.execute('INSERT INTO verses (book_id, chapter, verse, text_ta, text_en) VALUES (?, ?, ?, ?, ?)',
                      (book_id, chapter_num, verse_num, text_ta, text_en))
    book_id += 1

conn.commit()
conn.close()
print("Database holy_nation.db successfully built!")
