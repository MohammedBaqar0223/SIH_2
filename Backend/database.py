import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parent / "products.db"
UPLOAD_DIRECTORY = Path(__file__).parent / "uploads"
UPLOAD_DIRECTORY.mkdir(parents=True, exist_ok=True)

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
                quantity INTEGER NOT NULL,
                photo_path TEXT
            )
            """
        )

        columns = [row[1] for row in connection.execute("PRAGMA table_info(products)")]
        if "photo_path" not in columns:
            connection.execute("ALTER TABLE products ADD COLUMN photo_path TEXT")

        existing = connection.execute(
            "SELECT COUNT(*) AS count FROM products"
        ).fetchone()
        if existing["count"] == 0:
            connection.execute(
                """
                INSERT INTO products (name, material, price_paise, quantity, photo_path)
                VALUES (:name, :material, :price_paise, :quantity, NULL)
                """,
                SEED_PRODUCT,
            )


def list_products() -> list[dict]:
    with get_connection() as connection:
        rows = connection.execute(
            """
            SELECT id, name, material, price_paise, quantity, photo_path
            FROM products
            ORDER BY id
            """
        ).fetchall()
        return [dict(row) for row in rows]


def get_product(product_id: int) -> dict | None:
    with get_connection() as connection:
        row = connection.execute(
            """
            SELECT id, name, material, price_paise, quantity, photo_path
            FROM products
            WHERE id = ?
            """,
            (product_id,),
        ).fetchone()
        if row is None:
            return None
        return dict(row)


def insert_product(product: dict) -> dict:
    with get_connection() as connection:
        cursor = connection.execute(
            """
            INSERT INTO products (name, material, price_paise, quantity, photo_path)
            VALUES (:name, :material, :price_paise, :quantity, :photo_path)
            """,
            product,
        )
        row = connection.execute(
            """
            SELECT id, name, material, price_paise, quantity, photo_path
            FROM products
            WHERE id = ?
            """,
            (cursor.lastrowid,),
        ).fetchone()
        return dict(row)


def update_product(product_id: int, product: dict) -> dict | None:
    with get_connection() as connection:
        cursor = connection.execute(
            """
            UPDATE products
            SET name = :name,
                material = :material,
                price_paise = :price_paise,
                quantity = :quantity,
                photo_path = COALESCE(:photo_path, photo_path)
            WHERE id = :id
            """,
            {**product, "id": product_id},
        )
        if cursor.rowcount == 0:
            return None

        row = connection.execute(
            """
            SELECT id, name, material, price_paise, quantity, photo_path
            FROM products
            WHERE id = ?
            """,
            (product_id,),
        ).fetchone()
        return dict(row)


def set_product_photo(product_id: int, photo_path: str | None) -> dict | None:
    with get_connection() as connection:
        cursor = connection.execute(
            """
            UPDATE products
            SET photo_path = ?
            WHERE id = ?
            """,
            (photo_path, product_id),
        )
        if cursor.rowcount == 0:
            return None
        return get_product(product_id)

