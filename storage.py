import json
import os
from tasks import Task

DATA_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tasks.json")

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME")
DB_USERNAME = os.getenv("DB_USERNAME")
DB_PASSWORD = os.getenv("DB_PASSWORD")

USE_POSTGRES = bool(DB_HOST)


def _get_conn():
    import psycopg2
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USERNAME,
        password=DB_PASSWORD,
    )


def init_db():
    if not USE_POSTGRES:
        return
    with _get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS tasks (
                    id INTEGER PRIMARY KEY,
                    title TEXT NOT NULL,
                    description TEXT DEFAULT '',
                    done BOOLEAN DEFAULT FALSE,
                    priority TEXT DEFAULT 'medium',
                    created_at TEXT NOT NULL,
                    due_date TEXT,
                    tags TEXT DEFAULT '[]'
                )
            """)


def load_tasks():
    if USE_POSTGRES:
        return _pg_load_tasks()
    if not os.path.exists(DATA_FILE):
        return []
    with open(DATA_FILE, "r") as f:
        data = json.load(f)
    return [Task(**item) for item in data]


def save_tasks(tasks):
    if USE_POSTGRES:
        _pg_save_tasks(tasks)
        return
    data = []
    for task in tasks:
        data.append({
            "id": task.id,
            "title": task.title,
            "description": task.description,
            "done": task.done,
            "priority": task.priority,
            "created_at": task.created_at,
            "due_date": task.due_date,
            "tags": task.tags,
        })
    with open(DATA_FILE, "w") as f:
        json.dump(data, f, indent=2)


def _pg_load_tasks():
    with _get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, title, description, done, priority, created_at, due_date, tags"
                " FROM tasks ORDER BY id"
            )
            rows = cur.fetchall()
    return [
        Task(
            id=row[0],
            title=row[1],
            description=row[2],
            done=row[3],
            priority=row[4],
            created_at=row[5],
            due_date=row[6],
            tags=json.loads(row[7]),
        )
        for row in rows
    ]


def _pg_save_tasks(tasks):
    with _get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM tasks")
            for task in tasks:
                cur.execute(
                    """
                    INSERT INTO tasks (id, title, description, done, priority, created_at, due_date, tags)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        task.id,
                        task.title,
                        task.description,
                        task.done,
                        task.priority,
                        task.created_at,
                        task.due_date,
                        json.dumps(task.tags),
                    ),
                )
