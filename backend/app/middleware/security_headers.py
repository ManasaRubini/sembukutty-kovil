from starlette.middleware.base import BaseHTTPMiddleware
from fastapi import Request, Response
from fastapi.responses import JSONResponse
from fastapi.exceptions import HTTPException
import logging

logger = logging.getLogger("temple_app_security")


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response: Response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        if request.url.scheme == "https":
            response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        return response


async def production_exception_handler(request: Request, exc: Exception):
    """
    Sanitizes production HTTP 500 exceptions so internal stack traces, DB credentials,
    and system paths are never leaked to external users.

    IMPORTANT: HTTPExceptions (401, 403, 404, 422, etc.) are re-raised so FastAPI handles
    them correctly — only genuine unhandled 500 errors are sanitized here.
    """
    # Re-raise HTTPExceptions so FastAPI processes them with correct status codes
    if isinstance(exc, HTTPException):
        raise exc

    logger.error(f"Unhandled Internal Error on {request.url.path}: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "detail": "An internal server error occurred. Please contact system administrator.",
            "error_code": "INTERNAL_SERVER_ERROR",
        },
    )
