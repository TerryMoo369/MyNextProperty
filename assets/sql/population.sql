CREATE TABLE IF NOT EXISTS population (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    date TEXT NOT NULL,
    sex TEXT,
    age TEXT,
    ethnicity TEXT,
    population_000 REAL,
    UNIQUE(date, state_id, sex, age, ethnicity)
);
