import os
import sys
import json
import sqlite3
import subprocess

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
    (33, "மீகா", "Micah", "Old Testament
