CREATE TABLE IF NOT EXISTS state_finance(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    state_id INTEGER NOT NULL REFERENCES state(id),
    date TEXT NOT NULL,
    finance_type TEXT NOT NULL, -- 'revenue' or 'expenditure'
    category TEXT,
    amount_rm_mil REAL NOT NULL,
);

CREATE INDEX IF NOT EXISTS idx_finance_region_date ON state_finance(state_id, date);