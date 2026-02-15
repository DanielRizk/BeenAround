import time
from collections import deque
from typing import Deque, Dict, Any
from fastapi import Request

MAX_LOGS = 200

request_logs: Deque[Dict[str, Any]] = deque(maxlen=MAX_LOGS)

stats = {
    "total": 0,
    "2xx": 0,
    "4xx": 0,
    "5xx": 0,
    "avg_ms": 0.0,
}


async def monitoring_middleware(request: Request, call_next):

    if request.url.path in ("/monitor/stats", "/monitor/requests", "/admin"):
        return await call_next(request)

    start = time.perf_counter()
    response = await call_next(request)
    ms = (time.perf_counter() - start) * 1000.0

    stats["total"] += 1
    if 200 <= response.status_code < 300:
        stats["2xx"] += 1
    elif 400 <= response.status_code < 500:
        stats["4xx"] += 1
    elif 500 <= response.status_code < 600:
        stats["5xx"] += 1

    # simple moving average
    n = stats["total"]
    stats["avg_ms"] = ((stats["avg_ms"] * (n - 1)) + ms) / n

    # do NOT log sensitive routes fully
    path = request.url.path
    safe_path = path if not path.startswith("/auth") else "/auth/*"

    request_logs.appendleft({
        "method": request.method,
        "path": safe_path,
        "status": response.status_code,
        "ms": round(ms, 2),
    })

    return response
