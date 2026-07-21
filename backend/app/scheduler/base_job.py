from abc import ABC, abstractmethod


class BaseJob(ABC):

    @abstractmethod
    def name(self) -> str:
        pass

    @abstractmethod
    def interval_minutes(self) -> int:
        pass

    @abstractmethod
    def run(self) -> None:
        pass