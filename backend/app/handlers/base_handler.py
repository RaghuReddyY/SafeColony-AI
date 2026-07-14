from abc import ABC, abstractmethod

from app.database.session import SessionLocal


class BaseHandler(ABC):

    def __init__(self):

        self.db = None

    def __call__(self, event):

        self.db = SessionLocal()

        try:

            self.handle(event)

            self.db.commit()

        except Exception:

            self.db.rollback()

            raise

        finally:

            self.db.close()

    @abstractmethod
    def handle(self, event):

        pass