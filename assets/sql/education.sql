CREATE TABLE IF NOT EXISTS education (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    district TEXT,
    date TEXT NOT NULL,
    stage TEXT,
    sex TEXT,
    teachers_count INTEGER,
    literacy_proportion REAL
);

CREATE INDEX IF NOT EXISTS idx_education_state_date ON education(state_id, date);
