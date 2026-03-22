import sys
import os
# Ensure the project root is on the path when running web.py directly.
sys.path.insert(0, os.path.dirname(__file__))

from flask import Flask, render_template, request, redirect, url_for
from tasks import Task
from storage import load_tasks, save_tasks
from datetime import date

app = Flask(__name__)


def parse_tags(raw):
    """Split comma-separated string into a deduped, sorted list of lowercase tags."""
    return sorted({t.strip().lower() for t in raw.split(",") if t.strip()})


def get_next_id(tasks):
    # IDs are assigned by incrementing the current maximum.
    # Gaps are intentional — deleted task IDs are never reused.
    if not tasks:
        return 1
    return max((t.id for t in tasks if t.id is not None), default=0) + 1


@app.route("/")
def index():
    show_done = request.args.get("show_done", "1") == "1"
    active_tag = request.args.get("tag", "")
    tasks = load_tasks()
    # Collect all unique tags before any filtering, for the filter chips.
    all_tags = sorted({tag for t in tasks for tag in t.tags})
    if not show_done:
        tasks = [t for t in tasks if not t.done]
    if active_tag:
        tasks = [t for t in tasks if active_tag in t.tags]
    draggable_enabled = show_done and not active_tag
    today = date.today().isoformat()
    return render_template(
        "index.html",
        tasks=tasks,
        show_done=show_done,
        active_tag=active_tag,
        all_tags=all_tags,
        draggable_enabled=draggable_enabled,
        today=today,
    )


@app.route("/add", methods=["POST"])
def add():
    title = request.form.get("title", "").strip()
    # Silently ignore submissions with an empty title.
    if title:
        tasks = load_tasks()
        due_date = request.form.get("due_date", "").strip() or None
        tags = parse_tags(request.form.get("tags", ""))
        task = Task(
            title=title,
            description=request.form.get("description", "").strip(),
            priority=request.form.get("priority", "medium"),
            due_date=due_date,
            tags=tags,
            id=get_next_id(tasks),
        )
        tasks.append(task)
        save_tasks(tasks)
    return redirect(url_for("index"))


@app.route("/done/<int:task_id>", methods=["POST"])
def done(task_id):
    tasks = load_tasks()
    for task in tasks:
        if task.id == task_id:
            task.complete()
            break
    save_tasks(tasks)
    # Redirect back to the page the user came from (preserves show_done state).
    return redirect(request.referrer or url_for("index"))


@app.route("/delete/<int:task_id>", methods=["POST"])
def delete(task_id):
    tasks = load_tasks()
    # Rebuild the list without the deleted task; save_tasks overwrites the file.
    tasks = [t for t in tasks if t.id != task_id]
    save_tasks(tasks)
    return redirect(request.referrer or url_for("index"))


@app.route("/edit/<int:task_id>", methods=["GET", "POST"])
def edit(task_id):
    tasks = load_tasks()
    task = next((t for t in tasks if t.id == task_id), None)
    if task is None:
        # Task not found (e.g. deleted in another tab); fall back to index.
        return redirect(url_for("index"))
    if request.method == "POST":
        title = request.form.get("title", "").strip()
        if title:
            task.title = title
            task.description = request.form.get("description", "").strip()
            task.priority = request.form.get("priority", "medium")
            task.due_date = request.form.get("due_date", "").strip() or None
            task.tags = parse_tags(request.form.get("tags", ""))
            save_tasks(tasks)
        return redirect(url_for("index"))
    show_done = request.args.get("show_done", "1") == "1"
    active_tag = request.args.get("tag", "")
    all_tags = sorted({tag for t in tasks for tag in t.tags})
    today = date.today().isoformat()
    all_tasks = tasks if show_done else [t for t in tasks if not t.done]
    return render_template(
        "index.html",
        tasks=all_tasks,
        show_done=show_done,
        editing=task,
        active_tag=active_tag,
        all_tags=all_tags,
        draggable_enabled=False,
        today=today,
    )


@app.route("/reorder", methods=["POST"])
def reorder():
    data = request.get_json()
    if not data or "order" not in data:
        return "Bad request", 400
    order = data["order"]
    tasks = load_tasks()
    task_map = {t.id: t for t in tasks}
    reordered = [task_map[i] for i in order if i in task_map]
    referenced = set(order)
    for t in tasks:
        if t.id not in referenced:
            reordered.append(t)
    save_tasks(reordered)
    return "", 204


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
