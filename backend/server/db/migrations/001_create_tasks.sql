-- Create tasks table
CREATE TABLE IF NOT EXISTS tasks (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  subject_id TEXT,
  type TEXT,
  priority TEXT NOT NULL,
  deadline TEXT,
  status TEXT DEFAULT 'todo',
  start_date TEXT,
  duration DOUBLE PRECISION DEFAULT 1.0
);
