import json
import os
from tasks import Task

DATA_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tasks.json")


def load_tasks():
    if not os.path.exists(DATA_FILE):
        return []
    with open(DATA_FILE, "r") as f:
        data = json.load(f)
    tasks = []
    for item in data:
        task = Task(**item)
        tasks.append(task)
    return tasks


def save_tasks(tasks):
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
