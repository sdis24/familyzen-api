from typing import Generator

class _NoopDB:
    def add(self, *a, **k): pass
    def commit(self): pass
    def rollback(self): pass
    def close(self): pass

def get_db() -> Generator["_NoopDB", None, None]:
    db = _NoopDB()
    try:
        yield db
    finally:
        db.close()

class _User:
    def __init__(self):
        self.id = 1
        self.fcm_token = None

def get_current_user() -> _User:
    return _User()