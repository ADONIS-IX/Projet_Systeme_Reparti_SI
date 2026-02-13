from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.contrib.auth.models import User
from .models import Product, UserProfile
from .serializers import UserSerializer, UserProfileSerializer, ProductSerializer

class UserViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour gérer les utilisateurs
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer
    
    @action(detail=True, methods=['get'])
    def profile(self, request, pk=None):
        """
        Endpoint personnalisé pour récupérer le profil d'un utilisateur
        """
        user = self.get_object()
        try:
            profile = user.profile
            serializer = UserProfileSerializer(profile)
            return Response(serializer.data)
        except UserProfile.DoesNotExist:
            return Response(
                {"error": "Profil non trouvé"}, 
                status=status.HTTP_404_NOT_FOUND
            )

class ProductViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour gérer les produits
    CRUD complet : Create, Read, Update, Delete
    """
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    
    @action(detail=False, methods=['get'])
    def in_stock(self, request):
        """
        Endpoint personnalisé pour récupérer uniquement les produits en stock
        """
        products = Product.objects.filter(stock__gt=0)
        serializer = self.get_serializer(products, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def add_stock(self, request, pk=None):
        """
        Endpoint pour ajouter du stock à un produit
        """
        product = self.get_object()
        quantity = request.data.get('quantity', 0)
        
        try:
            quantity = int(quantity)
            if quantity <= 0:
                return Response(
                    {"error": "La quantité doit être positive"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            product.stock += quantity
            product.save()
            
            serializer = self.get_serializer(product)
            return Response(serializer.data)
        
        except ValueError:
            return Response(
                {"error": "Quantité invalide"},
                status=status.HTTP_400_BAD_REQUEST
            )

class UserProfileViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour gérer les profils utilisateurs
    """
    queryset = UserProfile.objects.all()
    serializer_class = UserProfileSerializer