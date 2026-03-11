# Rapport de Synthèse
## Système Réparti — Déploiement d'une Application Web avec Docker, Kubernetes, Ansible et Jenkins

---

| | |
|---|---|
| **Projet** | Système Réparti |
| **Auteur** | Adrien Diong GOMIS |
| **Dépôt** | https://github.com/ADONIS-IX/Projet_Systeme_Reparti_SI |
| **Date** | 08 mars 2026 |
| **Technologies** | React 18 · Django 5 · PostgreSQL 17 · Docker · Kubernetes · Ansible · Jenkins |

---

## Table des matières

1. [Introduction](#1-introduction)
2. [Architecture et choix techniques](#2-architecture-et-choix-techniques)
3. [Développement de l'application](#3-développement-de-lapplication)
4. [Conteneurisation avec Docker](#4-conteneurisation-avec-docker)
5. [Déploiement Kubernetes](#5-déploiement-kubernetes)
6. [Automatisation avec Ansible](#6-automatisation-avec-ansible)
7. [Pipeline CI/CD avec Jenkins](#7-pipeline-cicd-avec-jenkins)
8. [Points de capture essentiels](#8-points-de-capture-essentiels)
9. [Conclusion](#9-conclusion)

---

## 1. Introduction

### 1.1 Contexte du projet

Dans le cadre du cours de Systèmes Répartis, ce projet vise à démontrer la maîtrise des pratiques DevOps modernes à travers la conception, le développement et le déploiement automatisé d'une application web distribuée. Le scénario retenu s'inscrit dans une problématique concrète : une startup technologique souhaite déployer une plateforme web composée de plusieurs services indépendants, avec l'exigence d'un déploiement automatisé, reproductible et conforme aux bonnes pratiques de l'ingénierie logicielle.

L'application réalisée est une plateforme de gestion d'utilisateurs et de produits, structurée autour de trois services distincts communicant au sein d'un réseau conteneurisé : un frontend React exposant une interface utilisateur, une API REST Django assurant la logique métier, et une base de données relationnelle PostgreSQL garantissant la persistance des données.

### 1.2 Objectifs pédagogiques

Ce projet a pour vocation de démontrer les compétences suivantes :

- **Conception d'une architecture microservices** : définition des composants, des interfaces et des flux de communication inter-services ;
- **Conteneurisation avec Docker** : rédaction de Dockerfiles multi-stages optimisés et orchestration locale via Docker Compose ;
- **Déploiement sur cluster Kubernetes** : écriture de manifests déclaratifs (Deployment, Service, PersistentVolumeClaim, Job) et déploiement sur Minikube ;
- **Automatisation d'infrastructure avec Ansible** : écriture d'un playbook modulaire organisé en rôles pour l'installation et la configuration complète de l'environnement ;
- **Mise en place d'un pipeline CI/CD avec Jenkins** : automatisation du cycle build–test–push–deploy à l'aide d'un Jenkinsfile déclaratif.

### 1.3 Organisation du rapport

Ce rapport présente successivement l'architecture retenue et les choix techniques qui la fondent, les détails d'implémentation de chaque couche de l'application, les mécanismes de conteneurisation et de déploiement, puis les éléments de preuve sous forme de captures d'écran commentées, avant de conclure par une synthèse critique du travail accompli.

---

## 2. Architecture et choix techniques

### 2.1 Architecture cible

L'application repose sur une architecture à trois niveaux (three-tier architecture), déclinée en microservices indépendants et orchestrée au sein d'un cluster Kubernetes :

```
┌──────────────────────────────────────────────────────────────────────┐
│                    Cluster Kubernetes (Minikube)                      │
│                                                                       │
│  ┌──────────────────┐    ┌───────────────────┐   ┌────────────────┐  │
│  │   Frontend        │    │      Backend       │   │   PostgreSQL   │  │
│  │   React 18/Nginx  │───▶│  Django 5/Gunicorn │──▶│  17-alpine     │  │
│  │   NodePort: 30080 │    │  NodePort: 30800   │   │  ClusterIP     │  │
│  │   2 réplicas      │    │  2 réplicas        │   │  PVC: 1 Gi     │  │
│  └──────────────────┘    └───────────────────┘   └────────────────┘  │
│         ▲ /api/ proxy                ▲ Job: django-migrate            │
│         └──────── Nginx reverse-proxy ┘                               │
└──────────────────────────────────────────────────────────────────────┘
              ▲ kubectl apply
   ┌──────────┴──────────┐
   │   Pipeline Jenkins   │   ◀── git push (déclencheur)
   │  lint → build → push │
   │  → deploy k8s        │
   └──────────────────────┘
              ▲ ansible-playbook
   ┌──────────┴──────────┐
   │   Ansible            │
   │   role: docker       │
   │   role: kubernetes   │
   │   role: jenkins      │
   │   role: deploy       │
   └──────────────────────┘
```

Le frontend est servi par un conteneur Nginx qui joue simultanément le rôle de serveur de fichiers statiques et de reverse proxy : toutes les requêtes à destination de `/api/*` sont redirigées vers le service backend interne au cluster, garantissant ainsi l'absence de problèmes CORS et simplifiant la configuration réseau.

### 2.2 Justification des choix technologiques

| Composant | Technologie retenue | Justification |
|---|---|---|
| Frontend | React 18 + Bootstrap 5 | Écosystème mature, composants réutilisables, intégration aisée avec les API REST |
| Backend | Django 5 + Django REST Framework | ORM puissant, administration intégrée, sérialisation native des modèles |
| Serveur WSGI | Gunicorn (3 workers, 2 threads) | Production-ready, gestion de la concurrence, compatibilité native Django |
| Base de données | PostgreSQL 17-alpine | Robustesse, conformité ACID, support natif Django, image Alpine légère |
| Fichiers statiques | WhiteNoise + Brotli | Supprime la dépendance à un CDN externe, compression automatique |
| Conteneurisation | Docker (build multi-stage) | Séparation build/runtime, images finales allégées |
| Orchestration | Kubernetes + Minikube | Standard industrie, portabilité, auto-healing, scalabilité horizontale |
| Automatisation | Ansible (rôles) | Idempotence, lisibilité YAML, structure modulaire en rôles |
| CI/CD | Jenkins (pipeline déclaratif) | Flexibilité, intégration Docker Hub, déclenchement sur push Git |

### 2.3 Communication entre services

La communication inter-services repose exclusivement sur le réseau interne de Kubernetes. Le DNS interne du cluster résout automatiquement les noms de services : le backend contacte PostgreSQL via l'hôte `postgres:5432`, et le frontend transmet ses requêtes API via Nginx vers `backend:8000`. Aucun service n'est directement exposé sur l'internet public ; seuls les NodePorts 30080 (frontend) et 30800 (backend) sont accessibles depuis l'hôte Minikube.

---

## 3. Développement de l'application

### 3.1 API REST — Backend Django

L'application Django est structurée autour d'un projet principal `core` et d'une application métier `api`. La configuration de la base de données est entièrement externalisée via des variables d'environnement, lues avec `python-dotenv` :

```python
# backend/core/settings.py (extrait)
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME', 'postgres'),
        'USER': os.getenv('DB_USER', 'postgres'),
        'PASSWORD': os.getenv('DB_PASSWORD', 'postgres'),
        'HOST': os.getenv('DB_HOST', 'localhost'),
        'PORT': os.getenv('DB_PORT', '5432'),
    }
}
```

#### 3.1.1 Modèles de données

L'application expose **trois modèles** via l'API REST :

**Modèle `Product`** — représente un article du catalogue :
```python
class Product(models.Model):
    name        = models.CharField(max_length=200)
    description = models.TextField()
    price       = models.DecimalField(max_digits=10, decimal_places=2)
    stock       = models.IntegerField(default=0)
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)
```

**Modèle `UserProfile`** — extension du modèle `User` natif de Django :
```python
class UserProfile(models.Model):
    user    = models.OneToOneField(User, on_delete=models.CASCADE)
    bio     = models.TextField(blank=True)
    phone   = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
```

#### 3.1.2 Endpoints REST exposés

Le routeur DRF (`DefaultRouter`) enregistre les ViewSets et génère automatiquement les routes CRUD complètes :

| Endpoint | Méthodes | Description |
|---|---|---|
| `/api/users/` | GET, POST | Liste et création d'utilisateurs |
| `/api/users/{id}/` | GET, PUT, DELETE | Détail, modification, suppression |
| `/api/users/{id}/profile/` | GET | Profil associé à un utilisateur |
| `/api/products/` | GET, POST | Liste et création de produits |
| `/api/products/{id}/` | GET, PUT, DELETE | Détail d'un produit |
| `/api/products/in_stock/` | GET | Produits disponibles en stock |
| `/api/products/{id}/add_stock/` | POST | Ajout de stock |
| `/api/profiles/` | GET, POST | Gestion des profils |

#### 3.1.3 Tests unitaires

Des tests automatisés couvrent les modèles et les endpoints API :

```python
class ProductAPITest(APITestCase):
    def test_create_product(self):
        data = {"name": "Écran", "description": "Écran 27 pouces",
                "price": 299.99, "stock": 5}
        response = self.client.post("/api/products/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
```

### 3.2 Frontend React

Le frontend est développé avec React 18 et Bootstrap 5. Le composant racine `App.js` orchestre l'affichage des composants `UserList` et `ProductList`, qui consomment l'API REST via une couche de service dédiée (`services/api.js`) utilisant Axios :

```javascript
// frontend/src/services/api.js
const API_BASE_URL = process.env.REACT_APP_API_URL || '/api';
const api = axios.create({ baseURL: API_BASE_URL });

export const productService = {
  getAll:    () => api.get('/products/'),
  getInStock:() => api.get('/products/in_stock/'),
  create:    (data) => api.post('/products/', data),
  addStock:  (id, qty) => api.post(`/products/${id}/add_stock/`, { quantity: qty }),
};
```

L'URL de l'API est injectée au moment du build Docker via l'argument `REACT_APP_API_URL`, ce qui permet de basculer entre l'environnement de développement (`http://localhost:8000/api`) et la configuration production (chemin relatif `/api` proxifié par Nginx) sans modifier le code source.

---

## 4. Conteneurisation avec Docker

### 4.1 Dockerfile Backend — Build multi-stage

Le Dockerfile du backend adopte une stratégie **multi-stage** pour minimiser la taille de l'image finale :

```dockerfile
# Stage 1 — Builder : compilation des dépendances C (psycopg2)
FROM python:3.11-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y gcc libpq-dev
COPY requirements.txt .
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

# Stage 2 — Runtime : image finale allégée
FROM python:3.11-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
RUN apt-get update && apt-get install -y libpq5 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /install /usr/local
COPY . .
RUN useradd -m -u 1000 django && chown -R django:django /app
USER django
RUN python manage.py collectstatic --noinput
EXPOSE 8000
CMD ["gunicorn", "core.wsgi:application", "--bind", "0.0.0.0:8000",
     "--workers=3", "--threads=2", "--timeout=120"]
```

L'utilisation d'un utilisateur non-root (`django`, UID 1000) constitue une bonne pratique de sécurité en production. Le stage builder isole les outils de compilation (gcc, libpq-dev), absents de l'image finale.

### 4.2 Dockerfile Frontend — Build multi-stage

Le frontend suit également un pattern multi-stage : Node.js compile l'application, puis Nginx sert les fichiers statiques résultants :

```dockerfile
# Stage 1 — Build React
FROM node:20-alpine AS builder
WORKDIR /app
ARG REACT_APP_API_URL
ENV REACT_APP_API_URL=$REACT_APP_API_URL
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2 — Serveur Nginx
FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

L'argument de build `REACT_APP_API_URL` permet d'injecter la configuration de l'API au moment de la compilation, rendant l'image portable entre les environnements.

### 4.3 Docker Compose — Orchestration locale

Le fichier `docker-compose.yml` définit les trois services et leurs dépendances :

```yaml
services:
  db:
    image: postgres:17-alpine
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s; timeout: 5s; retries: 5

  backend:
    build: ./backend
    command: >
      sh -c "python manage.py migrate --noinput &&
             python manage.py collectstatic --noinput &&
             gunicorn core.wsgi:application --bind 0.0.0.0:8000"
    depends_on:
      db:
        condition: service_healthy   # Attend que PostgreSQL soit prêt

  frontend:
    build:
      context: ./frontend
      args:
        REACT_APP_API_URL: "/api"   # URL relative → proxy Nginx interne
    ports:
      - "3000:80"
    depends_on: [backend]
```

La dépendance conditionnelle `service_healthy` garantit que le backend ne démarre pas avant que PostgreSQL ne soit opérationnel, évitant les erreurs de connexion au démarrage.

---

## 5. Déploiement Kubernetes

### 5.1 Structure des manifests

Le répertoire `k8s/` contient l'ensemble des manifests nécessaires au déploiement :

| Fichier | Type(s) d'objets | Rôle |
|---|---|---|
| `secrets.yaml` | Secret | Credentials BDD (`db-secret`) et clé Django (`django-secret`) |
| `postgres-pvc.yaml` | PersistentVolumeClaim | Volume de 1 Gi pour les données PostgreSQL |
| `postgres-deployment.yaml` | Deployment + Service (ClusterIP) | Base de données PostgreSQL |
| `backend-deployment.yaml` | Job + Deployment + Service (NodePort) | Migrations + API Django |
| `frontend-deployment.yaml` | Deployment + Service (NodePort) | Interface React via Nginx |

### 5.2 Gestion de la persistance — PostgreSQL

Le PersistentVolumeClaim garantit la survie des données entre les redémarrages de pods :

```yaml
# k8s/postgres-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi
```

Le Deployment PostgreSQL monte ce volume sur `/var/lib/postgresql/data` et utilise des probes de disponibilité (`pg_isready`) pour signaler son état au cluster.

### 5.3 Job de migration Django

Une approche par **Kubernetes Job** est retenue pour les migrations Django, garantissant leur exécution une seule fois avant le démarrage du Deployment backend :

```yaml
# k8s/backend-deployment.yaml (extrait Job)
apiVersion: batch/v1
kind: Job
metadata:
  name: django-migrate
spec:
  backoffLimit: 3
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: OnFailure
      initContainers:
      - name: wait-for-postgres
        image: busybox:1.36
        command: ["sh", "-c", "until nc -z postgres 5432; do sleep 2; done"]
      containers:
      - name: django-migrate
        image: adonisdocker/backend:latest
        command: ["python", "manage.py", "migrate", "--noinput"]
```

L'utilisation d'un `initContainer` avec `busybox` assure l'attente de la disponibilité de PostgreSQL avant le lancement des migrations.

### 5.4 Services et exposition réseau

| Service | Type | Port interne | NodePort | Accessible depuis |
|---|---|---|---|---|
| `postgres` | ClusterIP | 5432 | — | Backend uniquement |
| `backend` | NodePort | 8000 | **30800** | `<minikube-ip>:30800/api` |
| `frontend` | NodePort | 80 | **30080** | `<minikube-ip>:30080` |

### 5.5 Déploiement automatisé

Le script `k8s/deploy.sh` automatise l'intégralité de la séquence de déploiement :

```bash
# 1. Vérification Minikube
minikube status &>/dev/null || err "Minikube non démarré"

# 2. Redirection du daemon Docker
eval $(minikube docker-env)

# 3. Build des images dans le daemon Minikube
docker build -t adonisdocker/backend:latest ./backend
docker build --build-arg REACT_APP_API_URL="/api" \
             -t adonisdocker/frontend:latest ./frontend

# 4. Application des manifests dans l'ordre
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl rollout status deployment/postgres --timeout=120s
kubectl apply -f k8s/backend-deployment.yaml
kubectl wait --for=condition=complete job/django-migrate --timeout=120s
kubectl apply -f k8s/frontend-deployment.yaml
```

---

## 6. Automatisation avec Ansible

### 6.1 Structure du playbook

Le playbook Ansible est organisé en **quatre rôles** indépendants et réutilisables :

```
ansible/
├── playbook.yml       ← Playbook principal
├── inventory.ini      ← Hôte : localhost (connexion locale)
├── ansible.cfg        ← Configuration (become: sudo)
└── roles/
    ├── docker/        ← Installation du moteur Docker
    ├── kubernetes/    ← Installation Minikube v1.32.0 + kubectl v1.28.0
    ├── jenkins/       ← Installation Java 21 + Jenkins (port 8080)
    └── deploy/        ← Déploiement de l'application sur K8s
```

### 6.2 Playbook principal

```yaml
# ansible/playbook.yml
- name: Configuration complète de l'infrastructure DevOps
  hosts: local
  become: yes
  vars:
    kubectl_version:  "v1.28.0"
    minikube_version: "1.32.0"
    java_version:     "21"
    jenkins_port:     8080
  roles:
    - docker
    - kubernetes
    - jenkins
    - deploy
```

L'exécution est déclenchée par la commande :
```bash
ansible-playbook ansible/playbook.yml -v
```

Le playbook est **idempotent** : son exécution répétée ne produit aucun effet de bord sur un environnement déjà configuré. À l'issue de l'exécution, un message de synthèse confirme les services installés et l'URL de Jenkins.

---

## 7. Pipeline CI/CD avec Jenkins

### 7.1 Architecture du pipeline

Le Jenkinsfile déclaratif définit un pipeline en **quatre étapes séquentielles** (avec parallélisme interne à l'étape de tests) :

```
Git push
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  Stage 1 : Préparation                                   │
│  checkout scm                                            │
└────────────────────────┬────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Stage 2 : Linting & Tests (parallèle)                  │
│  ┌─────────────────────┐  ┌─────────────────────────┐   │
│  │ Backend              │  │ Frontend                 │   │
│  │ flake8 + django test │  │ npm ci + npm test        │   │
│  └─────────────────────┘  └─────────────────────────┘   │
└────────────────────────┬────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Stage 3 : Build & Push Docker Hub                      │
│  docker build backend → push adonisdocker/backend:N     │
│  docker build frontend → push adonisdocker/frontend:N   │
└────────────────────────┬────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Stage 4 : Déploiement Kubernetes                       │
│  kubectl delete job django-migrate --ignore-not-found   │
│  kubectl apply -f k8s/                                  │
│  kubectl rollout status deployment/backend              │
└─────────────────────────────────────────────────────────┘
```

### 7.2 Étape de linting et tests

```groovy
stage('Linting & Tests') {
    parallel {
        stage('Backend — Lint & Tests') {
            steps {
                dir('backend') {
                    sh '''
                        python3 -m venv .venv
                        . .venv/bin/activate
                        pip install --quiet -r requirements.txt flake8
                        flake8 --max-line-length=120 --exclude=.venv,migrations .
                        python manage.py test --verbosity=2
                    '''
                }
            }
        }
        stage('Frontend — Lint & Tests') {
            steps {
                dir('frontend') {
                    sh 'npm ci --silent && CI=true npm test -- --watchAll=false'
                }
            }
        }
    }
}
```

### 7.3 Étape de build et push

```groovy
stage('Build & Push Images') {
    steps {
        withCredentials([usernamePassword(
            credentialsId: 'dockerhub-credentials',
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
        )]) {
            sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
            sh """
                docker build -t ${BACKEND_IMAGE}:${BUILD_NUMBER} \
                             -t ${BACKEND_IMAGE}:latest ./backend
                docker push ${BACKEND_IMAGE}:${BUILD_NUMBER}
                docker push ${BACKEND_IMAGE}:latest
            """
        }
    }
}
```

Le credential Jenkins `dockerhub-credentials` stocke de manière sécurisée les identifiants Docker Hub, sans les exposer dans les logs du pipeline.

### 7.4 Configuration des credentials Jenkins

Avant d'exécuter le pipeline, il est nécessaire de créer le credential Docker Hub dans Jenkins :
- **Chemin** : Jenkins → Gérer Jenkins → Credentials → Global → Ajouter
- **Type** : Nom d'utilisateur et mot de passe
- **ID** : `dockerhub-credentials`

---

## 8. Points de capture essentiels

Cette section recense les éléments de preuve attendus pour valider chaque composant du système. Les captures doivent être intégrées au document PDF de synthèse dans l'ordre indiqué.

### 8.1 Validation Docker Compose (exécution locale)

| N° | Commande / URL | Ce que doit montrer la capture |
|---|---|---|
| **C-01** | `docker compose up --build` | Logs de build des trois images sans erreur |
| **C-02** | `docker compose ps` | Statuts `running` et `healthy` pour les trois services |
| **C-03** | `http://localhost:3000` | Page d'accueil React avec la liste des utilisateurs et des produits |
| **C-04** | `http://localhost:8000/api/` | Interface Browsable API de Django REST Framework |
| **C-05** | `http://localhost:8000/api/products/` | Réponse JSON avec la liste des produits |

### 8.2 Déploiement Kubernetes

| N° | Commande | Ce que doit montrer la capture |
|---|---|---|
| **C-06** | `minikube start --driver=docker` | Cluster démarré avec succès |
| **C-07** | `bash k8s/deploy.sh` | Sortie complète du script avec toutes les étapes validées (✓) |
| **C-08** | `kubectl get pods` | Pods `postgres-xxx`, `backend-xxx` (×2), `frontend-xxx` (×2) en état `Running` ; pod `django-migrate-xxx` en état `Completed` |
| **C-09** | `kubectl get services` | Services avec leurs types et NodePorts (30080, 30800) |
| **C-10** | `kubectl get pvc` | PVC `postgres-pvc` en état `Bound` |
| **C-11** | `http://<minikube-ip>:30080` | Application React accessible via le cluster Kubernetes |
| **C-12** | `kubectl logs job/django-migrate` | Logs confirmant l'application des migrations Django |
| **C-13** | `minikube dashboard` | Vue graphique du tableau de bord Kubernetes |

### 8.3 Automatisation Ansible

| N° | Commande | Ce que doit montrer la capture |
|---|---|---|
| **C-14** | `ansible all -m ping` | Réponse `pong` confirmant la connexion à l'hôte |
| **C-15** | `ansible-playbook playbook.yml -v` | PLAY RECAP final avec `failed=0` et `changed>0` |
| **C-16** | Message de synthèse Ansible | Affichage du résumé des services installés avec l'URL Jenkins |

### 8.4 Pipeline CI/CD Jenkins

| N° | Localisation | Ce que doit montrer la capture |
|---|---|---|
| **C-17** | `http://localhost:8080` | Tableau de bord Jenkins après connexion |
| **C-18** | Jenkins → Credentials | Credential `dockerhub-credentials` configuré |
| **C-19** | Jenkins → Pipeline → Blue Ocean ou Stage View | Pipeline en cours d'exécution avec les étapes colorées |
| **C-20** | Jenkins → Build → Résultat | Toutes les étapes en vert, statut `SUCCESS` |
| **C-21** | `hub.docker.com/r/adonisdocker/backend` | Images `backend` et `frontend` publiées avec les tags `latest` et le numéro de build |

---

## 9. Conclusion

### 9.1 Bilan du projet

Ce projet a permis de réaliser le déploiement complet d'une application web distribuée en adoptant une approche DevOps rigoureuse, de bout en bout. Les cinq axes pédagogiques définis en introduction ont été couverts :

1. **Architecture microservices** : trois services faiblement couplés, communicant via des interfaces REST standardisées et un réseau overlay Kubernetes ;
2. **Conteneurisation Docker** : Dockerfiles multi-stages produisant des images légères et sécurisées, orchestrées localement par Docker Compose ;
3. **Déploiement Kubernetes** : manifests déclaratifs complets (Job, Deployment, Service, PVC, Secret), gestion du cycle de vie et de la haute disponibilité avec deux réplicas par service ;
4. **Automatisation Ansible** : playbook modulaire en quatre rôles, idempotent, permettant de reproduire intégralement l'environnement à partir d'une machine vierge ;
5. **Pipeline CI/CD Jenkins** : chaîne complète automatisant lint, tests, build Docker, push vers Docker Hub et déploiement Kubernetes.

### 9.2 Apports techniques

Sur le plan technique, plusieurs bonnes pratiques notables ont été mises en œuvre : l'utilisation d'un `initContainer` pour synchroniser le démarrage des services dépendants, le recours à un Kubernetes Job pour les migrations de base de données (garantissant l'idempotence et la traçabilité), l'injection de configuration au moment du build Docker via des arguments de build, et la séparation stricte des secrets via les objets Kubernetes `Secret`.

### 9.3 Perspectives d'amélioration

Dans une perspective d'évolution vers un environnement de production réel, plusieurs améliorations seraient envisageables :

- **Sécurité** : passage en mode `DEBUG=False`, rotation des secrets via HashiCorp Vault ou Sealed Secrets, mise en place d'un réseau `NetworkPolicy` Kubernetes restrictif ;
- **Scalabilité** : remplacement de Minikube par un cluster managé (GKE, EKS, AKS) et configuration d'un Horizontal Pod Autoscaler (HPA) ;
- **Observabilité** : intégration d'une stack Prometheus/Grafana pour la métrologie et d'un agrégateur de logs centralisé (ELK ou Loki) ;
- **CI/CD avancé** : déclenchement automatique des builds sur push Git via des webhooks Jenkins, stratégie de déploiement Blue/Green ou Canary.

### 9.4 Conclusion générale

La réalisation de ce projet confirme que l'adoption des outils DevOps modernes — Docker, Kubernetes, Ansible et Jenkins — permet de transformer un processus de déploiement traditionnel et manuel en une chaîne automatisée, reproductible et résiliente. L'ensemble des livrables attendus a été produit et versionné dans le dépôt Git, constituant une base solide pour tout environnement de production réel.

---

*Rapport rédigé dans le cadre du cours Système Réparti — 2025/2026*  
*Dépôt Git : https://github.com/ADONIS-IX/Projet_Systeme_Reparti_SI*
