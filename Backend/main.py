from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from database import init_db, insert_product, list_products


@asynccontextmanager
async def lifespan(_app: FastAPI):
    init_db()
    yield


app = FastAPI(lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Content-Type"],
)


class ProductCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    material: str = Field(min_length=1, max_length=100)
    price_paise: int = Field(ge=0)
    quantity: int = Field(ge=0)


@app.get("/")
def home():
    return {"Message": "Hello"}


@app.get("/products")
def get_products():
    return list_products()


@app.post("/products", status_code=201)
def add_product(product: ProductCreate):
    return insert_product(product.model_dump())
