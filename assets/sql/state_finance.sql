CREATE TABLE IF NOT EXISTS state_finance(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    region_id INTEGER NOT NULL,
    date TEXT NOT NULL,
    finance_type TEXT NOT NULL, -- 'revenue' or 'expenditure'
    category TEXT,
    amount_rm_mil REAL NOT NULL,
    FOREIGN KEY(region_id) REFERENCES regions(region_id)
);

CREATE INDEX IF NOT EXISTS idx_finance_region_date ON state_finance(region_id, date);