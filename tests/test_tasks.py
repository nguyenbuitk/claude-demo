import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from tasks import Task

# this is several test
def test_task_creation():
    task = Task(title="Buy groceries", priority="high")
    assert task.title == "Buy groceries"
    assert task.done == False
    assert task.priority == "high"


def test_task_complete():
    task = Task(title="Write tests")
    task.complete()
    assert task.done == True


def test_task_str_incomplete():
    task = Task(title="Fix bug", priority="low")
    assert str(task) == "[ ] (low) Fix bug"


def test_task_str_complete():
    task = Task(title="Fix bug", priority="low")
    task.complete()
    assert str(task) == "[x] (low) Fix bug"
