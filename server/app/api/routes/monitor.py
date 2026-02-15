from fastapi import APIRouter, Depends, Form, Request, HTTPException
from fastapi.responses import HTMLResponse, RedirectResponse
from sqlalchemy.orm import Session
from sqlalchemy import text

from ...auth import verify_password
from ...models import User
from ...db import get_db
from ...monitoring import stats, request_logs

router = APIRouter()


# -----------------------------
# Simple session-based admin auth
# -----------------------------

def _safe_next(next_url: str | None) -> str:
    if not next_url:
        return "/monitor"
    # only allow local paths
    if not next_url.startswith("/") or next_url.startswith("//"):
        return "/monitor"
    # prevent redirecting back to login/logout endlessly
    if next_url.startswith("/internal/login") or next_url.startswith("/internal/logout"):
        return "/monitor"
    return next_url

def _is_admin_session(request: Request) -> bool:
    return bool(request.session.get("admin_logged_in"))


def get_admin_user_from_session(
    request: Request,
    db: Session = Depends(get_db),
) -> User:
    """Dependency: ensure a valid admin session and return the admin user."""
    if not _is_admin_session(request):
        next_url = request.url.path
        if request.url.query:
            next_url += f"?{request.url.query}"
        raise HTTPException(status_code=303, headers={"Location": f"/internal/login?next={next_url}"})

    user_id = request.session.get("admin_user_id")
    if not user_id:
        request.session.clear()
        raise HTTPException(status_code=303, headers={"Location": "/internal/login"})

    user = db.query(User).filter(User.id == user_id, User.is_deleted == False).first()  # noqa: E712
    if not user or not user.is_admin:
        request.session.clear()
        raise HTTPException(status_code=303, headers={"Location": "/internal/login"})

    return user


@router.get("/internal/login", include_in_schema=False)
def admin_login_page(request: Request, next: str = "/monitor") -> HTMLResponse:
    if _is_admin_session(request):
        return RedirectResponse(url=next, status_code=303)

    return HTMLResponse(
        f"""
        <html>
          <head>
            <title>Admin Login</title>
            <meta name="viewport" content="width=device-width, initial-scale=1" />
          </head>
          <body style="font-family: Arial; padding: 24px; max-width: 520px; margin: 0 auto;">
            <h2>Admin Login</h2>
            <p style="color:#555; line-height:1.4;">
              Sign in with the seeded admin account (from <code>ADMIN_EMAIL</code> / <code>ADMIN_PASSWORD</code>).
            </p>
            <form method="post" action="/internal/login">
              <input type="hidden" name="next" value="{next}" />
              <div style="margin: 12px 0;">
                <label>Email</label><br/>
                <input name="email" type="email" required style="width:100%; padding:10px; font-size: 16px;" />
              </div>
              <div style="margin: 12px 0;">
                <label>Password</label><br/>
                <input name="password" type="password" required style="width:100%; padding:10px; font-size: 16px;" />
              </div>
              <button type="submit" style="padding: 10px 14px; font-size: 16px; cursor: pointer;">
                Login
              </button>
            </form>
          </body>
        </html>
        """
    )


@router.post("/internal/login", include_in_schema=False)
def admin_login_submit(
    request: Request,
    db: Session = Depends(get_db),
    email: str = Form(...),
    password: str = Form(...),
    next: str = Form("/monitor"),
):
    user = db.query(User).filter(User.email == email, User.is_deleted == False).first()  # noqa: E712
    if not user or not user.is_admin or not verify_password(password, user.password_hash):
        return HTMLResponse(
            """
            <html><body style="font-family: Arial; padding: 24px;">
              <h3>Login failed</h3>
              <p>Invalid credentials.</p>
              <p><a href="/internal/login">Try again</a></p>
            </body></html>
            """,
            status_code=401,
        )

    request.session["admin_logged_in"] = True
    request.session["admin_user_id"] = str(user.id)
    return RedirectResponse(url=_safe_next(next), status_code=303)


@router.get("/internal/logout", include_in_schema=False)
def admin_logout(request: Request):
    request.session.clear()
    return RedirectResponse(url="/internal/login", status_code=303)


@router.get("/monitor", response_class=HTMLResponse)
def monitor_page(user: User = Depends(get_admin_user_from_session)):
    return f"""
    <html>
    <head>
      <title>Monitor</title>
      <meta name="viewport" content="width=device-width, initial-scale=1" />
    </head>
    <body style="font-family: Arial; padding: 16px;">
      <div style="display:flex; align-items:center; justify-content:space-between;">
        <h2 style="margin:0;">Backend Monitor</h2>
        <div>
          <span style="color:#555; margin-right:12px;">{user.email}</span>
          <a href="/internal/logout">Logout</a>
        </div>
      </div>
      <div id="stats" style="margin-top: 16px;"></div>
      <h3>Last Requests</h3>
      <pre id="logs" style="background:#f6f6f6; padding: 12px; overflow:auto;"></pre>
      <script>
        async function refresh(){{
          const s = await fetch('/monitor/stats').then(r=>r.json());
          const l = await fetch('/monitor/requests').then(r=>r.json());
          document.getElementById('stats').innerText = JSON.stringify(s, null, 2);
          document.getElementById('logs').innerText = JSON.stringify(l, null, 2);
        }}
        refresh();
        setInterval(refresh, 2000);
      </script>
    </body>
    </html>
    """


@router.get("/monitor/stats")
def monitor_stats(db: Session = Depends(get_db), user: User = Depends(get_admin_user_from_session)):
    ok = True
    try:
        db.execute(text("SELECT 1"))
    except Exception:
        ok = False
    return {"api": stats, "db_ok": ok}


@router.get("/monitor/requests")
def monitor_requests(user: User = Depends(get_admin_user_from_session)):
    return list(request_logs)