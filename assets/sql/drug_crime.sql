CREATE TABLE IF NOT EXISTS drug_crime (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    date TEXT NOT NULL,
    total INTEGER,
    opiate INTEGER,
    cannabis INTEGER,
    meth_crystalline INTEGER,
    ats INTEGER,
    psychotropic_pill INTEGER,
    others INTEGER
);

CREATE INDEX IF NOT EXISTS idx_drug_crime_state_date ON drug_crime(state_id, date);
