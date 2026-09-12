from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from fastapi.staticfiles import StaticFiles
from PIL import Image, ImageOps, UnidentifiedImageError
from io import BytesIO
from uuid import uuid4
from pathlib import Path
from database import (
    init_db,
    insert_product,
    list_products,
    get_product,
    update_product as save_product_update,
    set_product_photo,
    UPLOAD_DIRECTORY,
)


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

app.mount("/uploads", StaticFiles(directory=UPLOAD_DIRECTORY), name="ugirploads")


class ProductCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    material: str = Field(min_length=1, max_length=100)
    price_paise: int = Field(ge=0)
    quantity: int = Field(ge=0)
    photo_path: str | None = None


class PricingInput(BaseModel):
    material_cost: float = Field(ge=0)
    labour_cost: float = Field(ge=0)
    packaging_cost: float = Field(ge=0)
    overhead_cost: float = Field(ge=0)


@app.get("/")
def home():
    return {"Message": "Hello"}


@app.get("/products")
def get_products():
    return list_products()


@app.get("/products/{product_id}")
def get_product_by_id(product_id: int):
    product = get_product(product_id)
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return product


@app.post("/products", status_code=201)
def add_product(product: ProductCreate):
    return insert_product(product.model_dump())


@app.put("/products/{product_id}")
def update_product(product_id: int, product: ProductCreate):
    updated = save_product_update(product_id, product.model_dump())
    if updated is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return updated


@app.post("/products/{product_id}/photo")
async def upload_product_photo(product_id: int, file: UploadFile = File(...)):
    product = get_product(product_id)
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")

    if not file.filename:
        raise HTTPException(status_code=400, detail="File name is required")

    contents = await file.read()
    if len(contents) > 8 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Photo is too large")

    try:
        image = Image.open(BytesIO(contents))
        image = ImageOps.exif_transpose(image)
        image = image.convert("RGB")
    except (UnidentifiedImageError, OSError):
        raise HTTPException(status_code=400, detail="Uploaded file is not a valid image")

    old_path = product.get("photo_path")
    if old_path:
        old_file = UPLOAD_DIRECTORY / Path(old_path).name
        if old_file.exists():
            old_file.unlink()

    file_id = str(uuid4())
    filename = f"{file_id}.jpg"
    destination = UPLOAD_DIRECTORY / filename
    image = image.convert("RGB")
    image.save(destination, format="JPEG", quality=85)

    photo_path = f"/uploads/{filename}"
    updated = set_product_photo(product_id, photo_path)
    if updated is None:
        raise HTTPException(status_code=404, detail="Product not found")

    return {"photo_path": photo_path}


@app.post("/pricing/suggest")
def suggest_price(pricing: PricingInput):
    direct_cost = (
        pricing.material_cost
        + pricing.labour_cost
        + pricing.packaging_cost
        + pricing.overhead_cost
    )
    suggested_price = direct_cost * 1.35
    explanation = (
        f"Direct manufacturing and handling costs total ₹{direct_cost:.2f}. "
        f"The quick MVP pricing rule adds a 35% artisan margin, "
        f"producing a suggested retail price of ₹{suggested_price:.2f}."
    )
    return {
        "suggested_price": round(suggested_price, 2),
        "explanation": explanation,
        "breakdown": {
            "materials": pricing.material_cost,
            "labour": pricing.labour_cost,
            "packaging": pricing.packaging_cost,
            "overhead": pricing.overhead_cost,
            "direct_cost": direct_cost,
            "margin_percent": 35,
        },
    }
