#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

echo "Déploiement Kubernetes"
echo "========================="

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Vérifier que Minikube est démarré
echo -e "${YELLOW}Vérification de Minikube...${NC}"
if ! minikube status &> /dev/null; then
    echo -e "${RED}Erreur: Minikube n'est pas démarré${NC}"
    echo "Démarrez Minikube avec: minikube start --driver=docker"
    exit 1
fi
echo -e "${GREEN}✓ Minikube est actif${NC}"

# Configurer Docker pour Minikube
echo -e "${YELLOW}Configuration de Docker pour Minikube...${NC}"
eval $(minikube docker-env)
echo -e "${GREEN}✓ Docker configuré${NC}"

# Construire les images
echo -e "${YELLOW}Construction des images Docker...${NC}"
if [ -d "./backend" ] && [ -d "./frontend" ]; then
docker build -t backend:latest ./backend
docker build -t frontend:latest ./frontend
echo -e "${GREEN}✓ Images construites${NC}"
else
    echo "Erreur : Les dossiers ./backend ou ./frontend sont introuvables."
    exit 1
fi

# Créer les secrets
echo -e "${YELLOW}Création des secrets...${NC}"
read -sp "Mot de passe PostgreSQL: " DB_PASSWORD
echo
kubectl create secret generic db-secret \
  --from-literal=password=$DB_PASSWORD \
  --dry-run=client -o yaml | kubectl apply -f -

read -sp "Django SECRET_KEY: " DJANGO_SECRET
echo
kubectl create secret generic django-secret \
  --from-literal=secret-key=$DJANGO_SECRET \
  --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✓ Secrets créés${NC}"

# Déployer PostgreSQL
echo -e "${YELLOW}Déploiement de PostgreSQL...${NC}"
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres-deployment.yaml
echo -e "${GREEN}✓ PostgreSQL déployé${NC}"

# Attendre que PostgreSQL soit prêt
echo -e "${YELLOW}Attente du démarrage de PostgreSQL...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s

# Déployer Backend
echo -e "${YELLOW}Déploiement du Backend...${NC}"
kubectl apply -f k8s/backend-deployment.yaml
echo -e "${GREEN}✓ Backend déployé${NC}"

# Attendre que le backend soit prêt
echo -e "${YELLOW}Attente du démarrage du Backend...${NC}"
kubectl wait --for=condition=ready pod -l app=backend --timeout=300s

# Appliquer les migrations
echo -e "${YELLOW}Application des migrations Django...${NC}"
BACKEND_POD=$(kubectl get pods -l app=backend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $BACKEND_POD -- python manage.py migrate
echo -e "${GREEN}✓ Migrations appliquées${NC}"

# Déployer Frontend
echo -e "${YELLOW}Déploiement du Frontend...${NC}"
kubectl apply -f k8s/frontend-deployment.yaml
echo -e "${GREEN}✓ Frontend déployé${NC}"

# Attendre que le frontend soit prêt
echo -e "${YELLOW}Attente du démarrage du Frontend...${NC}"
kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s

# Afficher les URLs
echo ""
echo -e "${GREEN}=========================${NC}"
echo -e "${GREEN}Déploiement terminé !${NC}"
echo -e "${GREEN}=========================${NC}"
echo ""
echo "Accès aux services :"
echo "-------------------"
echo "Frontend: $(minikube service frontend --url)"
echo "Backend: $(minikube service backend --url)"
echo ""
echo "Commandes utiles :"
echo "- Voir les pods: kubectl get pods"
echo "- Voir les services: kubectl get services"
echo "- Logs backend: kubectl logs -f deployment/backend"
echo "- Logs frontend: kubectl logs -f deployment/frontend"
echo "- Dashboard: minikube dashboard"