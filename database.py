import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# SQLite for development. Swap this for a PostgreSQL URL later, e.g.:
# "postgresql://user:password@localhost/unigreen"
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./unigreen.db")

if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
else:
    engine = create_engine(DATABASE_URL, pool_pre_ping=True)
    
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    """Give each request its own DB session, and always close it after."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()