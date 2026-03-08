from django.test import TestCase
from django.contrib.auth.models import User
from rest_framework.test import APITestCase
from rest_framework import status
from .models import Product, UserProfile


class ProductModelTest(TestCase):
    """Tests pour le modèle Product"""

    def setUp(self):
        self.product = Product.objects.create(
            name="Clavier mécanique",
            description="Clavier RGB switches Cherry MX",
            price=89.99,
            stock=15,
        )

    def test_product_creation(self):
        self.assertEqual(self.product.name, "Clavier mécanique")
        self.assertEqual(self.product.price, 89.99)
        self.assertEqual(self.product.stock, 15)

    def test_product_str(self):
        self.assertEqual(str(self.product), "Clavier mécanique")


class UserProfileModelTest(TestCase):
    """Tests pour le modèle UserProfile"""

    def setUp(self):
        self.user = User.objects.create_user(
            username="testuser", email="test@example.com", password="testpass123"
        )
        self.profile = UserProfile.objects.create(
            user=self.user, bio="Bio test", phone="0600000000"
        )

    def test_profile_creation(self):
        self.assertEqual(self.profile.user.username, "testuser")
        self.assertEqual(self.profile.bio, "Bio test")

    def test_profile_str(self):
        self.assertEqual(str(self.profile), "Profil de testuser")


class ProductAPITest(APITestCase):
    """Tests pour l'API Product"""

    def setUp(self):
        self.product = Product.objects.create(
            name="Souris", description="Souris gaming", price=49.99, stock=10
        )

    def test_list_products(self):
        response = self.client.get("/api/products/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_create_product(self):
        data = {
            "name": "Écran",
            "description": "Écran 27 pouces",
            "price": 299.99,
            "stock": 5,
        }
        response = self.client.post("/api/products/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Product.objects.count(), 2)

    def test_create_product_negative_price(self):
        data = {
            "name": "Invalide",
            "description": "Test",
            "price": -10,
            "stock": 1,
        }
        response = self.client.post("/api/products/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_product_in_stock(self):
        Product.objects.create(
            name="Épuisé", description="Plus en stock", price=10, stock=0
        )
        response = self.client.get("/api/products/in_stock/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)


class UserAPITest(APITestCase):
    """Tests pour l'API User"""

    def setUp(self):
        self.user = User.objects.create_user(
            username="alice", email="alice@example.com", password="pass1234"
        )

    def test_list_users(self):
        response = self.client.get("/api/users/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_user_detail(self):
        response = self.client.get(f"/api/users/{self.user.id}/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["username"], "alice")
