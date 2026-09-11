import importlib
from io import BytesIO
import pytest
from fastapi.testclient import TestClient
from PIL import Image

@pytest.fixture
def client(tmp_path, monkeypatch):
    monkeypatch.setenv('ARTISAN_DATA_DIR', str(tmp_path))
    import main
    importlib.reload(main)
    with TestClient(main.app) as client:
        yield client

def payload(**changes):
    return dict(title='Bamboo basket', category='Basket', quantity=5, price_paise=31200, **changes)

def test_create_edit_and_persist(client):
    created = client.post('/products', json=payload())
    assert created.status_code == 201
    product = created.json()
    product_id = product['id']
    assert client.get('/products').json()[0]['price_paise'] == 31200
    edited = payload(description_hindi='हाथ से बनी टोकरी')
    edited['quantity'] = 2
    assert client.put(f'/products/{product_id}', json=edited).status_code == 200
    # A separate app startup and database connection still sees saved data.
    with TestClient(client.app) as restarted:
        result = restarted.get(f'/products/{product_id}').json()
        assert result['quantity'] == 2
        assert result['description_hindi'] == 'हाथ से बनी टोकरी'


def test_validation_and_missing(client):
    bad = payload(); bad['quantity'] = -1
    assert client.post('/products', json=bad).status_code == 422
    bad = payload(); bad['title'] = '   '
    assert client.post('/products', json=bad).status_code == 422
    assert client.get('/products/missing').status_code == 404
    assert client.put('/products/missing', json=payload()).status_code == 404


def test_photo_validation_replacement_and_persistence(client):
    product_id = client.post('/products', json=payload()).json()['id']
    endpoint = f'/products/{product_id}/photo'
    assert client.post(endpoint, files={'file': ('bad.jpg', b'not an image')}).status_code == 400
    assert client.post(endpoint, files={'file': ('big.jpg', b'x' * (8*1024*1024+1))}).status_code == 413
    data = BytesIO(); Image.new('RGB', (32, 32), 'red').save(data, 'PNG')
    first = client.post(endpoint, files={'file': ('basket.png', data.getvalue())})
    assert first.status_code == 200
    old_path = first.json()['photo_path']
    assert client.get(old_path).headers['content-type'] == 'image/jpeg'
    second = client.post(endpoint, files={'file': ('basket.png', data.getvalue())})
    assert client.get(old_path).status_code == 404
    assert client.get(second.json()['photo_path']).status_code == 200
    assert client.get(f'/products/{product_id}').json()['photo_path'] == second.json()['photo_path']
