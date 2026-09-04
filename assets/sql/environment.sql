CREATE TABLE IF NOT EXISTS environment (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    date TEXT NOT NULL,
    forest_reserve_area REAL
);

CREATE INDEX IF NOT EXISTS idx_environment_state_date ON environment(state_id, date);
