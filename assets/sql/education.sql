CREATE TABLE IF NOT EXISTS education (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    date TEXT NOT NULL,
    district TEXT,
    stage TEXT,
    sex TEXT,
    teachers_count INTEGER,
    literacy_proportion REAL,
    UNIQUE(date, state_id, district, stage, sex)
);
