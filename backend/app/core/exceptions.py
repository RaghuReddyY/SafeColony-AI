from fastapi import Request, FastAPI, status
from fastapi.responses import JSONResponse

from app.core.logger import logger


class AppException(Exception):
    def __init__(self, message: str, status_code: int):
        self.message = message
        self.status_code = status_code
        super().__init__(message)


class NotFoundException(AppException):
    def __init__(self, resource: str):
        super().__init__(
            f"{resource} not found",
            status.HTTP_404_NOT_FOUND,
        )


class ConflictException(AppException):
    def __init__(self, message: str):
        super().__init__(
            message,
            status.HTTP_409_CONFLICT,
        )


class BadRequestException(AppException):
    def __init__(self, message: str):
        super().__init__(
            message,
            status.HTTP_400_BAD_REQUEST,
        )

class ForbiddenException(AppException):
    def __init__(self, message: str):
        super().__init__(
            message,
            status.HTTP_403_FORBIDDEN,
        )

def register_exception_handlers(app: FastAPI):

    @app.exception_handler(AppException)
    async def app_exception_handler(
        request: Request,
        exc: AppException,
    ):
        logger.warning(
            "%s %s -> %s",
            request.method,
            request.url.path,
            exc.message,
        )

        return JSONResponse(
            status_code=exc.status_code,
            content={
                "success": False,
                "message": exc.message,
            },
        )

    @app.exception_handler(Exception)
    async def global_exception_handler(
        request: Request,
        exc: Exception,
    ):
        logger.exception(
            "Unhandled exception while processing %s %s",
            request.method,
            request.url.path,
        )

        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "message": "Internal server error",
            },
        )