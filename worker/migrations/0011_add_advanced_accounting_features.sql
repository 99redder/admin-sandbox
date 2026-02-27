-- Bank feed imports + reconciliation
CREATE TABLE IF NOT EXISTS bank_statement_imports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_name TEXT,
  source_type TEXT,
  account_label TEXT,
  statement_start_date TEXT,
  statement_end_date TEXT,
  uploaded_at TEXT NOT NULL DEFAULT (datetime('now')),
  uploaded_by TEXT,
  csv_filename TEXT
);

CREATE TABLE IF NOT EXISTS bank_statement_lines (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  import_id INTEGER NOT NULL,
  line_hash TEXT NOT NULL,
  posted_date TEXT NOT NULL,
  description TEXT,
  amount_cents INTEGER NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  duplicate_flag INTEGER NOT NULL DEFAULT 0,
  matched_type TEXT,
  matched_id INTEGER,
  matched_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (import_id) REFERENCES bank_statement_imports(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_bank_lines_import ON bank_statement_lines(import_id);
CREATE INDEX IF NOT EXISTS idx_bank_lines_hash ON bank_statement_lines(line_hash);
CREATE INDEX IF NOT EXISTS idx_bank_lines_date ON bank_statement_lines(posted_date);

-- Invoices / AR
CREATE TABLE IF NOT EXISTS invoices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_number TEXT NOT NULL UNIQUE,
  customer_name TEXT NOT NULL,
  customer_email TEXT,
  customer_company TEXT,
  issue_date TEXT NOT NULL,
  due_date TEXT NOT NULL,
  paid_date TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','sent','partial','paid','void')),
  subtotal_cents INTEGER NOT NULL DEFAULT 0,
  tax_cents INTEGER NOT NULL DEFAULT 0,
  total_cents INTEGER NOT NULL DEFAULT 0,
  amount_paid_cents INTEGER NOT NULL DEFAULT 0,
  balance_due_cents INTEGER NOT NULL DEFAULT 0,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS invoice_line_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_id INTEGER NOT NULL,
  item_description TEXT NOT NULL,
  quantity REAL NOT NULL DEFAULT 1,
  unit_amount_cents INTEGER NOT NULL DEFAULT 0,
  line_total_cents INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_invoice ON invoice_line_items(invoice_id);

-- Recurring templates + merchant rules
CREATE TABLE IF NOT EXISTS recurring_templates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  txn_type TEXT NOT NULL CHECK (txn_type IN ('expense','income')),
  frequency TEXT NOT NULL CHECK (frequency IN ('weekly','monthly','quarterly','yearly')),
  day_of_month INTEGER,
  interval_count INTEGER NOT NULL DEFAULT 1,
  amount_cents INTEGER NOT NULL,
  category TEXT NOT NULL,
  source_or_vendor TEXT,
  paid_via TEXT,
  notes TEXT,
  next_run_date TEXT NOT NULL,
  active INTEGER NOT NULL DEFAULT 1,
  last_run_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS merchant_rules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  match_pattern TEXT NOT NULL,
  match_mode TEXT NOT NULL DEFAULT 'contains' CHECK (match_mode IN ('contains','starts_with','exact')),
  apply_category TEXT NOT NULL,
  apply_txn_type TEXT NOT NULL DEFAULT 'expense' CHECK (apply_txn_type IN ('expense','income')),
  apply_paid_via TEXT,
  active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Close checklist + lock periods
CREATE TABLE IF NOT EXISTS close_checklist_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  item_key TEXT NOT NULL,
  item_label TEXT NOT NULL,
  completed INTEGER NOT NULL DEFAULT 0,
  completed_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(year, month, item_key)
);

CREATE TABLE IF NOT EXISTS locked_periods (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  start_date TEXT NOT NULL,
  end_date TEXT NOT NULL,
  reason TEXT,
  locked_by TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_locked_periods_range ON locked_periods(start_date, end_date);
