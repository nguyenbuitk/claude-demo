import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from flask import Flask, render_template, request, redirect, url_for
from tasks import Task
from storage import load_tasks, save_tasks

app = Flask(__name__)


def get_next_id(tasks):
    if not tasks:
        return 1
    return max((t.id for t in tasks if t.id is not None), default=0) + 1


@app.route("/")
def index():
    show_done = request.args.get("show_done", "1") == "1"
    tasks = load_tasks()
    if not show_done:
        tasks = [t for t in tasks if not t.done]
    return render_template("index.html", tasks=tasks, show_done=show_done)


@app.route("/add", methods=["POST"])
def add():
    title = request.form.get("title", "").strip()
    if title:
        tasks = load_tasks()
        task = Task(
            title=title,
            description=request.form.get("description", "").strip(),
            priority=request.form.get("priority", "medium"),
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
    return redirect(request.referrer or url_for("index"))


@app.route("/delete/<int:task_id>", methods=["POST"])
def delete(task_id):
    tasks = load_tasks()
    tasks = [t for t in tasks if t.id != task_id]
    save_tasks(tasks)
    return redirect(request.referrer or url_for("index"))


@app.route("/edit/<int:task_id>", methods=["GET", "POST"])
def edit(task_id):
    tasks = load_tasks()
    task = next((t for t in tasks if t.id == task_id), None)
    if task is None:
        return redirect(url_for("index"))
    if request.method == "POST":
        title = request.form.get("title", "").strip()
        if title:
            task.title = title
            task.description = request.form.get("description", "").strip()
            task.priority = request.form.get("priority", "medium")
            save_tasks(tasks)
        return redirect(url_for("index"))
    show_done = request.args.get("show_done", "1") == "1"
    all_tasks = tasks if show_done else [t for t in tasks if not t.done]
    return render_template("index.html", tasks=all_tasks, show_done=show_done, editing=task)


if __name__ == "__main__":
    app.run(debug=True, port=5000)
