CREATE TABLE IF NOT EXISTS drug_crime (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    date TEXT NOT NULL UNIQUE,
    total INTEGER,
    opiate INTEGER,
    cannabis INTEGER,
    meth_crystalline INTEGER,
    ats INTEGER,
    psychotropic_pill INTEGER,
    others INTEGER
);
