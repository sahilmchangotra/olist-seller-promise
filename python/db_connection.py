from sqlalchemy import create_engine

def get_engine():
    engine = create_engine(
        "postgresql+psycopg2://postgres:1467@localhost:5432/olist_db"
    )
    return engine