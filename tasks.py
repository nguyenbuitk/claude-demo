from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional


@dataclass
class Task:
    title: str
    description: str = ""
    done: bool = False
    priority: str = "medium"  # low, medium, high
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())
    id: Optional[int] = None

    def complete(self):
        self.done = True

    def __str__(self):
        status = "x" if self.done else " "
        return f"[{status}] ({self.priority}) {self.title}"
