import pandas as pd
from db_connection import get_engine

engine = get_engine()
df = pd.read_sql("SELECT COUNT(*) FROM kaggle.olist_orders", engine)
print(df)