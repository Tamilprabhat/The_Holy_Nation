import sqlite3
import os

# Create assets directory if not exists
os.makedirs('assets', exist_ok=True)
db_path = 'assets/holy_nation.db'

if os.path.exists(db_path):
    os.remove(db_path)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Create tables
cursor.execute('''
CREATE TABLE IF NOT EXISTS books (
    id INTEGER PRIMARY KEY,
    name TEXT,
    testament TEXT,
    chapters_count INTEGER
)
''')

cursor.execute('''
CREATE TABLE IF NOT EXISTS verses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    book_id INTEGER,
    chapter INTEGER,
    verse INTEGER,
    text TEXT,
    FOREIGN KEY(book_id) REFERENCES books(id)
)
''')

# Sample Books
books_data = [
    (1, 'ஆதியாகமம் (Genesis)', 'Old', 50),
    (2, 'யாத்திராகமம் (Exodus)', 'Old', 40),
    (19, 'சங்கீதம் (Psalms)', 'Old', 150),
    (40, 'மத்தேயு (Matthew)', 'New', 28),
    (43, 'யோவான் (John)', 'New', 21),
    (66, 'வெளிப்படுத்தின விசேஷம் (Revelation)', 'New', 22),
]

cursor.executemany('INSERT INTO books VALUES (?, ?, ?, ?)', books_data)

# Sample Verses
verses_data = [
    (1, 1, 1, 'ஆதியிலே தேவன் வானத்தையும் பூமியையும் சிருஷ்டித்தார்.'),
    (1, 1, 2, 'பூமியானது ஒழுங்கின்மையும் வெறுமையுமாய் இருந்தது; ஆழத்தின்மேல் இருள் இருந்தது; தேவ ஆவியானவர் ஜலத்தின்மேல் அசைவாடிக்கொண்டிருந்தார்.'),
    (1, 1, 3, 'தேவன் வெளிச்சம் உண்டாகக்கடவது என்றார், வெளிச்சம் உண்டாயிற்று.'),
    (43, 3, 16, 'தேவன், தம்முடைய ஒரேபேறான குமாரனை விசுவாசிக்கிறவன் எவனோ அவன் கெட்டுப்போகாமல் நித்தியஜீவனை அடையும்படிக்கு, அவரைத் தந்தருளி, இவ்வளவாய் உலகத்தில் அன்புகூர்ந்தார்.'),
    (19, 23, 1, 'கர்த்தர் என் மேய்ப்பராயிருக்கிறார்; நான் தாழ்ச்சியடையேன்.'),
]

cursor.executemany('INSERT INTO verses (book_id, chapter, verse, text) VALUES (?, ?, ?, ?)', verses_data)

conn.commit()
conn.close()

print("Successfully generated holy_nation.db inside assets folder!")
