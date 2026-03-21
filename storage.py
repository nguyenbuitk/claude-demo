import json
import os
from tasks import Task

# Always resolve the data file relative to this module, not the cwd,
# so the app works regardless of where it is launched from.
DATA_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tasks.json")


def load_tasks():
    # Return an empty list if the file doesn't exist yet (first run).
    if not os.path.exists(DATA_FILE):
        return []
    with open(DATA_FILE, "r") as f:
        data = json.load(f)
    # Reconstruct Task objects from the raw dicts stored in JSON.
    tasks = []
    for item in data:
        task = Task(**item)
        tasks.append(task)
    return tasks


def save_tasks(tasks):
    # Serialize only the fields we care about (avoids surprises if the
    # dataclass grows new fields that aren't JSON-serializable).
    data = []
    for task in tasks:
        data.append({
            "id": task.id,
            "title": task.title,
            "description": task.description,
            "done": task.done,
            "priority": task.priority,
            "created_at": task.created_at,
        })
    with open(DATA_FILE, "w") as f:
        json.dump(data, f, indent=2)
