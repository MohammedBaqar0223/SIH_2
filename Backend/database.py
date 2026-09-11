import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parent / "products.db"

SEED_PRODUCT = {
    "name": "Handmade Bamboo Basket",
    "material": "Bamboo",
    "price_paise": 35000,
    "quantity": 5,
}


def get_connection() -> sqlite3.Connection:
    connection = sqlite3.connect(DB_PATH)
    connection.row_factory = sqlite3.Row
    return connection


def init_db() -> None:
    with get_connection() as connection:
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                material TEXT NOT NULL,
                price_paise INTEGER NOT NULL,
                quantity INTEGER NOT NULL
            )
            """
        )
        existing = connection.execute(
            "SELECT COUNT(*) AS count FROM products"
        ).fetchone()
        if existing["count"] == 0:
            connection.execute(
                """
                INSERT INTO products (name, material, price_paise, quantity)
                VALUES (:name, :material, :price_paise, :quantity)
                """,
                SEED_PRODUCT,
            )


def list_products() -> list[dict]:
    with get_connection() as connection:
        rows = connection.execute(
            """
            SELECT id, name, material, price_paise, quantity
            FROM products
            ORDER BY id
            """
        ).fetchall()
        return [dict(row) for row in rows]


def insert_product(product: dict) -> dict:
    with get_connection() as connection:
        cursor = connection.execute(
            """
            INSERT INTO products (name, material, price_paise, quantity)
            VALUES (:name, :material, :price_paise, :quantity)
            """,
            product,
        )
        row = connection.execute(
            """
            SELECT id, name, material, price_paise, quantity
            FROM products
            WHERE id = ?
            """,
            (cursor.lastrowid,),
        ).fetchone()
        return dict(row)
