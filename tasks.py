from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional


# Core data model for the application.
# id is None until the task is persisted via save_tasks().
@dataclass
class Task:
    title: str
    description: str = ""
    done: bool = False
    priority: str = "medium"  # valid values: "low", "medium", "high"
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())
    id: Optional[int] = None

    def complete(self):
        # Marks the task as done (one-way; there is no undo/reopen).
        self.done = True

    def __str__(self):
        # CLI-friendly representation used in tests: "[x] (high) Buy milk"
        status = "x" if self.done else " "
        return f"[{status}] ({self.priority}) {self.title}"
