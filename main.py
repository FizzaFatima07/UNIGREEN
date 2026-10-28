from fastapi import FastAPI, Request, Depends, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session

from database import Base, engine, get_db
from models import User, UserRole
from auth import (
    hash_password,
    verify_password,
    create_access_token,
    decode_access_token,
)

# Create the database tables if they don't exist yet.
Base.metadata.create_all(bind=engine)

app = FastAPI(title="UniGreen")

app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

COOKIE_NAME = "unigreen_session"


def get_current_user(request: Request, db: Session = Depends(get_db)) -> User | None:
    """Look at the session cookie and return the logged-in user, or None."""
    token = request.cookies.get(COOKIE_NAME)
    if not token:
        return None
    payload = decode_access_token(token)
    if not payload:
        return None
    return db.query(User).filter(User.id == int(payload["sub"])).first()


# --- Public pages ---

@app.get("/", response_class=HTMLResponse)
def welcome(request: Request):
    return templates.TemplateResponse(request, "welcome.html", {"title": "UniGreen"})


# --- Signup ---

@app.get("/signup", response_class=HTMLResponse)
def signup_form(request: Request):
    return templates.TemplateResponse(request, "signup.html", {})


@app.post("/signup")
def signup_submit(
    request: Request,
    full_name: str = Form(...),
    email: str = Form(...),
    password: str = Form(...),
    db: Session = Depends(get_db),
):
    existing = db.query(User).filter(User.email == email).first()
    if existing:
        return templates.TemplateResponse(
            request,
            "signup.html",
            {"error": "An account with this email already exists."},
            status_code=400,
        )

    user = User(
        full_name=full_name,
        email=email,
        password_hash=hash_password(password),
        role=UserRole.student,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token(user.id, user.role.value)
    response = RedirectResponse(url="/dashboard", status_code=303)
    response.set_cookie(COOKIE_NAME, token, httponly=True, max_age=60 * 60 * 24)
    return response


# --- Login ---

@app.get("/login", response_class=HTMLResponse)
def login_form(request: Request):
    return templates.TemplateResponse(request, "login.html", {})


@app.post("/login")
def login_submit(
    request: Request,
    email: str = Form(...),
    password: str = Form(...),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.email == email).first()
    if not user or not verify_password(password, user.password_hash):
        return templates.TemplateResponse(
            request,
            "login.html",
            {"error": "Incorrect email or password."},
            status_code=401,
        )

    token = create_access_token(user.id, user.role.value)
    response = RedirectResponse(url="/dashboard", status_code=303)
    response.set_cookie(COOKIE_NAME, token, httponly=True, max_age=60 * 60 * 24)
    return response


# --- Logout ---

@app.get("/logout")
def logout():
    response = RedirectResponse(url="/")
    response.delete_cookie(COOKIE_NAME)
    return response


# --- Dashboard (protected) ---

@app.get("/dashboard", response_class=HTMLResponse)
def dashboard(request: Request, db: Session = Depends(get_db)):
    user = get_current_user(request, db)
    if not user:
        return RedirectResponse(url="/login")
    return templates.TemplateResponse(request, "dashboard.html", {"user": user})

