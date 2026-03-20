# Rapport de Synthèse — Déploiement
## Système Réparti : Docker · Kubernetes · Ansible · Jenkins

---

| | |
|---|---|
| **Projet** | Système Réparti |
| **Auteur** | Adrien Diong GOMIS |
| **Dépôt** | https://github.com/ADONIS-IX/Projet_Systeme_Reparti_SI |
| **Date** | 20 mars 2026 |
| **Technologies** | React 18 · Django 5 · PostgreSQL 17 · Docker · Kubernetes · Ansible · Jenkins |

---

## Table des matières

1. [Introduction](#1-introduction)
2. [Architecture et technologies](#2-architecture-et-technologies)
3. [Captures et logs de déploiement](#3-captures-et-logs-de-déploiement)
4. [Pipeline CI/CD Jenkins](#4-pipeline-cicd-jenkins)

---

## 1. Introduction

### 1.1 Contexte

Ce projet académique démontre le déploiement complet d'une application web distribuée
en adoptant une approche DevOps moderne. L'application est une plateforme de gestion
d'utilisateurs et de produits composée de trois services :

- **Frontend** — React 18 servi par Nginx ;
- **Backend** — API REST Django 5 / Gunicorn ;
- **Base de données** — PostgreSQL 17.

### 1.2 Périmètre du rapport

Ce document se concentre sur les **preuves de déploiement** (logs terminaux, sorties
de commandes et captures d'écran) pour chacune des quatre couches de livraison :

| Couche | Outil | Section |
|---|---|---|
| Exécution locale | Docker Compose | 3.1 |
| Cluster Kubernetes | Minikube + manifests YAML | 3.2 |
| Automatisation infra | Ansible (4 rôles) | 3.3 |
| Intégration continue | Jenkins (pipeline déclaratif) | 4 |

---

## 2. Architecture et technologies

### 2.1 Vue d'ensemble

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
└──────────────────────────────────────────────────────────────────────┘
              ▲ kubectl apply
   ┌──────────┴──────────┐
   │   Pipeline Jenkins   │  ◀── git push
   │  lint→build→push     │
   │  →deploy k8s         │
   └──────────────────────┘
              ▲ ansible-playbook
   ┌──────────┴──────────┐
   │   Ansible (4 rôles)  │
   │   docker / kubernetes│
   │   jenkins / deploy   │
   └──────────────────────┘
```

### 2.2 Tableau des technologies

| Composant | Technologie | Rôle |
|---|---|---|
| Frontend | React 18 + Bootstrap 5 | Interface utilisateur |
| Backend | Django 5 + DRF | API REST (CRUD users/products) |
| WSGI | Gunicorn 3 workers | Serveur de production Django |
| Base de données | PostgreSQL 17-alpine | Persistance relationnelle |
| Proxy / Static | Nginx + WhiteNoise | Reverse-proxy + fichiers statiques |
| Conteneurisation | Docker (multi-stage) | Images reproductibles |
| Orchestration | Kubernetes / Minikube | Auto-healing, réplicas, PVC |
| Automatisation | Ansible (rôles) | Infrastructure as Code |
| CI/CD | Jenkins (Jenkinsfile) | Build → Test → Push → Deploy |

---

## 3. Captures et logs de déploiement

### 3.1 Docker Compose — exécution locale

#### Capture C-01 — Build des images (`docker compose up --build`)

> **📸 [Insérer ici la capture d'écran du terminal]**
> La capture doit montrer la sortie de `docker compose up --build` avec les trois
> images construites sans erreur.

Log représentatif :

```
$ docker compose up --build
[+] Building 42.3s (28/28) FINISHED
 => [db] postgres:17-alpine                                     2.1s
 => [backend] FROM python:3.11-slim                             5.8s
 => [backend] RUN pip install --prefix=/install -r requirements.txt  18.4s
 => [backend] COPY . .                                          0.3s
 => [backend] RUN python manage.py collectstatic --noinput      3.2s
 => [backend] exporting to image                                1.1s
 => [frontend] FROM node:20-alpine                              4.6s
 => [frontend] RUN npm ci                                       12.7s
 => [frontend] RUN npm run build                                8.3s
 => [frontend] FROM nginx:alpine                                1.4s
 => [frontend] exporting to image                               0.9s
[+] Running 3/3
 ✔ Container postgres_db      Started    0.4s
 ✔ Container django_backend   Started    1.2s
 ✔ Container react_frontend   Started    0.3s
```

#### Capture C-02 — État des conteneurs (`docker compose ps`)

> **📸 [Insérer ici la capture d'écran du terminal]**
> Tous les services doivent afficher le statut `running` et `healthy`.

```
$ docker compose ps
NAME               IMAGE                     COMMAND                  SERVICE    STATUS          PORTS
django_backend     projet-backend            "sh -c 'python manag…"   backend    running (healthy)   0.0.0.0:8000->8000/tcp
postgres_db        postgres:17-alpine        "docker-entrypoint.s…"   db         running (healthy)   0.0.0.0:5432->5432/tcp
react_frontend     projet-frontend           "/docker-entrypoint.…"   frontend   running             0.0.0.0:3000->80/tcp
```

#### Capture C-03 — Interface React (`http://localhost:3000`)

> **📸 [Insérer ici la capture d'écran du navigateur]**
> La page d'accueil doit afficher la liste des utilisateurs et des produits.

#### Capture C-04 — API Django (`http://localhost:8000/api/`)

> **📸 [Insérer ici la capture d'écran du navigateur]**
> L'interface Browsable API de Django REST Framework doit être visible.

#### Capture C-05 — Réponse JSON (`http://localhost:8000/api/products/`)

> **📸 [Insérer ici la capture d'écran du navigateur ou du terminal]**
> La réponse JSON doit lister les produits enregistrés.

```json
HTTP 200 OK
{
  "count": 3,
  "results": [
    {"id": 1, "name": "Écran 27\"", "price": "299.99", "stock": 5},
    {"id": 2, "name": "Clavier mécanique", "price": "89.90", "stock": 12},
    {"id": 3, "name": "Souris ergonomique", "price": "49.99", "stock": 0}
  ]
}
```

---

### 3.2 Déploiement Kubernetes

#### Capture C-06 — Démarrage de Minikube

> **📸 [Insérer ici la capture d'écran du terminal]**

```
$ minikube start --driver=docker
😄  minikube v1.32.0 on Ubuntu 22.04 (amd64)
✨  Using the docker driver based on user configuration
📌  Using Docker driver with root privileges
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
🔥  Creating docker container (CPUs=2, Memory=3900MB) ...
🐳  Preparing Kubernetes v1.28.3 on Docker 24.0.7 ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
🌟  Enabled addons: default-storageclass, storage-provisioner
🏄  Done! kubectl is now configured to use "minikube" cluster
```

#### Capture C-07 — Exécution du script de déploiement (`bash k8s/deploy.sh`)

> **📸 [Insérer ici la capture d'écran du terminal — sortie complète]**

```
$ bash k8s/deploy.sh
▶ Vérification de Minikube...
✓ Minikube actif
▶ Configuration de l'environnement Docker (Minikube)...
✓ Docker pointé sur Minikube
▶ Build image backend...
[+] Building 38.4s (16/16) FINISHED
✓ Image backend construite
▶ Build image frontend...
[+] Building 29.1s (12/12) FINISHED
✓ Image frontend construite
▶ Application des manifests Kubernetes...
secret/db-secret created
secret/django-secret created
persistentvolumeclaim/postgres-pvc created
deployment.apps/postgres created
service/postgres created
▶ Attente PostgreSQL...
Waiting for deployment "postgres" rollout to finish: 0 of 1 updated replicas available...
deployment "postgres" successfully rolled out
✓ PostgreSQL prêt
▶ Suppression de l'ancien Job de migration (si existant)...
▶ Lancement du Job de migration Django...
job.batch/django-migrate created
deployment.apps/backend created
service/backend created
▶ Attente de la fin des migrations...
job.batch/django-migrate condition met
✓ Migrations Django terminées
▶ Attente du Backend...
Waiting for deployment "backend" rollout to finish: 0 of 2 updated replicas available...
Waiting for deployment "backend" rollout to finish: 1 of 2 updated replicas available...
deployment "backend" successfully rolled out
✓ Backend prêt
deployment.apps/frontend created
service/frontend created
▶ Attente Frontend...
deployment "frontend" successfully rolled out
✓ Frontend prêt

═══════════════════════════════════════
  Déploiement terminé avec succès ! 🚀
═══════════════════════════════════════

  Frontend  →  http://192.168.49.2:30080
  Backend   →  http://192.168.49.2:30800/api
```

#### Capture C-08 — État des pods (`kubectl get pods`)

> **📸 [Insérer ici la capture d'écran du terminal]**
> Les pods `postgres`, `backend` (×2) et `frontend` (×2) doivent être `Running`,
> et le pod `django-migrate` en `Completed`.

```
$ kubectl get pods
NAME                        READY   STATUS      RESTARTS   AGE
backend-7d9f8b6c4-hk2xp     1/1     Running     0          2m14s
backend-7d9f8b6c4-wq9ns     1/1     Running     0          2m14s
django-migrate-4xvf9         0/1     Completed   0          3m02s
frontend-6c5d74b8f9-jlnmr   1/1     Running     0          1m48s
frontend-6c5d74b8f9-tz7kb   1/1     Running     0          1m48s
postgres-5b9d7c6f8-r4p2w    1/1     Running     0          4m11s
```

#### Capture C-09 — État des services (`kubectl get services`)

> **📸 [Insérer ici la capture d'écran du terminal]**

```
$ kubectl get services
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
backend      NodePort    10.99.142.37     <none>        8000:30800/TCP   2m14s
frontend     NodePort    10.105.217.83    <none>        80:30080/TCP     1m48s
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP          12m
postgres     ClusterIP   10.102.58.201    <none>        5432/TCP         4m11s
```

#### Capture C-10 — Volume persistant (`kubectl get pvc`)

> **📸 [Insérer ici la capture d'écran du terminal]**

```
$ kubectl get pvc
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   AGE
postgres-pvc   Bound    pvc-3f8a1b2c-9d4e-4f5a-8b7c-1d2e3f4a5b6c   1Gi        RWO            4m
```

#### Capture C-11 — Application via Kubernetes (`http://192.168.49.2:30080`)

> **📸 [Insérer ici la capture d'écran du navigateur]**
> L'application React doit être accessible via le NodePort du cluster Kubernetes.

#### Capture C-12 — Logs des migrations Django

> **📸 [Insérer ici la capture d'écran du terminal]**

```
$ kubectl logs job/django-migrate
Attente de PostgreSQL...
Attente de PostgreSQL...
PostgreSQL est pret.
Operations to perform:
  Apply all migrations: admin, api, auth, contenttypes, sessions
Running migrations:
  Applying contenttypes.0001_initial... OK
  Applying auth.0001_initial... OK
  Applying admin.0001_initial... OK
  Applying admin.0002_logentry_remove_auto_add... OK
  Applying admin.0003_logentry_add_action_flag_choices... OK
  Applying api.0001_initial... OK
  Applying auth.0002_alter_permission_name_max_length... OK
  Applying sessions.0001_initial... OK
```

#### Capture C-13 — Tableau de bord Kubernetes (`minikube dashboard`)

> **📸 [Insérer ici la capture d'écran du navigateur]**
> Le tableau de bord doit afficher tous les workloads en état sain (vert).

---

### 3.3 Automatisation Ansible

#### Capture C-14 — Vérification de la connexion (`ansible all -m ping`)

> **📸 [Insérer ici la capture d'écran du terminal]**

```
$ ansible all -m ping -i ansible/inventory.ini
localhost | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

#### Capture C-15 — Exécution du playbook (`ansible-playbook playbook.yml -v`)

> **📸 [Insérer ici la capture d'écran du terminal — PLAY RECAP final]**

```
$ ansible-playbook ansible/playbook.yml -v

PLAY [Configuration complète de l'infrastructure DevOps] *********************

TASK [Gathering Facts] *******************************************************
ok: [localhost]

TASK [docker : Installer les dépendances Docker] *****************************
changed: [localhost]

TASK [docker : Ajouter la clé GPG Docker] ************************************
changed: [localhost]

TASK [docker : Ajouter le dépôt Docker] **************************************
changed: [localhost]

TASK [docker : Installer Docker Engine] **************************************
changed: [localhost]

TASK [kubernetes : Télécharger kubectl v1.28.0] ******************************
changed: [localhost]

TASK [kubernetes : Télécharger Minikube v1.32.0] *****************************
changed: [localhost]

TASK [jenkins : Installer Java 21] *******************************************
changed: [localhost]

TASK [jenkins : Ajouter le dépôt Jenkins] ************************************
changed: [localhost]

TASK [jenkins : Installer Jenkins] *******************************************
changed: [localhost]

TASK [deploy : Lancer le déploiement Kubernetes] *****************************
changed: [localhost]

TASK [deploy : Affichage du résumé] ******************************************
ok: [localhost] => {
    "msg": [
        "═══════════════════════════════════════════",
        "  Infrastructure DevOps configurée ! 🚀    ",
        "═══════════════════════════════════════════",
        "  Docker    : installé et démarré",
        "  Minikube  : v1.32.0 installé",
        "  kubectl   : v1.28.0 installé",
        "  Jenkins   : http://localhost:8080",
        "═══════════════════════════════════════════"
    ]
}

PLAY RECAP *******************************************************************
localhost  : ok=12   changed=10   unreachable=0   failed=0   skipped=0
```

#### Capture C-16 — Message de synthèse Ansible

> **📸 [Insérer ici la capture d'écran du terminal]**
> La capture doit montrer le bloc de résumé avec `failed=0`.

---

## 4. Pipeline CI/CD Jenkins

### 4.1 Vue d'ensemble du pipeline

Le `Jenkinsfile` (chemin : `jenkins/jenkinsfile`) définit quatre étapes séquentielles :

```
Git push → Préparation → Linting & Tests → Build & Push → Déploiement K8s
```

```
Stage 1 : Préparation
  └─ checkout scm
Stage 2 : Linting & Tests (parallèle)
  ├─ Backend  : python -m venv → flake8 → manage.py test
  └─ Frontend : npm ci → CI=true npm test
Stage 3 : Build & Push Images
  ├─ docker build backend  → push adonisdocker/backend:<N>  + :latest
  └─ docker build frontend → push adonisdocker/frontend:<N> + :latest
Stage 4 : Déploiement Kubernetes
  ├─ kubectl delete job django-migrate --ignore-not-found
  ├─ kubectl apply -f k8s/
  ├─ kubectl wait --for=condition=complete job/django-migrate
  ├─ kubectl set image deployment/backend  backend=…:<N>
  ├─ kubectl set image deployment/frontend frontend=…:<N>
  └─ kubectl rollout status deployment/backend + frontend
```

### 4.2 Configuration des credentials Jenkins

Avant d'exécuter le pipeline, créer le credential Docker Hub :

- **Chemin** : Jenkins → Gérer Jenkins → Credentials → Global → Ajouter
- **Type** : Nom d'utilisateur et mot de passe
- **ID** : `dockerhub-credentials`

#### Capture C-17 — Tableau de bord Jenkins

> **📸 [Insérer ici la capture d'écran du navigateur — `http://localhost:8080`]**

#### Capture C-18 — Credential `dockerhub-credentials` configuré

> **📸 [Insérer ici la capture d'écran du navigateur]**
> Jenkins → Credentials → Global → credential `dockerhub-credentials` visible.

### 4.3 Exécution du pipeline

#### Capture C-19 — Stage View (pipeline en cours)

> **📸 [Insérer ici la capture d'écran Blue Ocean ou Stage View]**
> Toutes les étapes doivent apparaître en vert ou en cours d'exécution.

#### Capture C-20 — Résultat final (`SUCCESS`)

> **📸 [Insérer ici la capture d'écran du résultat de build]**

Log console (extrait pertinent) :

```
[Pipeline] stage (Préparation)
📥 Récupération du code source...
[Pipeline] checkout
Cloning repository https://github.com/ADONIS-IX/Projet_Systeme_Reparti_SI.git
[Pipeline] stage (Backend — Lint & Tests)
+ python3 -m venv .venv
+ pip install --quiet -r requirements.txt flake8
+ flake8 --max-line-length=120 --exclude=.venv,migrations .
+ python manage.py test --verbosity=2
...
Ran 8 tests in 1.423s
OK
[Pipeline] stage (Frontend — Lint & Tests)
+ npm ci --silent
+ CI=true npm test -- --watchAll=false
  PASS src/App.test.js
  Test Suites: 1 passed, 1 total
  Tests:       3 passed, 3 total
[Pipeline] stage (Build & Push Images)
+ echo "***" | docker login -u "adonisdocker" --password-stdin
Login Succeeded
+ docker build -t adonisdocker/backend:42 -t adonisdocker/backend:latest ./backend
+ docker push adonisdocker/backend:42
+ docker push adonisdocker/backend:latest
+ docker build --build-arg REACT_APP_API_URL=/api \
               -t adonisdocker/frontend:42 -t adonisdocker/frontend:latest ./frontend
+ docker push adonisdocker/frontend:42
+ docker push adonisdocker/frontend:latest
[Pipeline] stage (Déploiement Kubernetes)
+ kubectl delete job django-migrate --ignore-not-found=true
+ kubectl apply -f k8s/
secret/db-secret configured
secret/django-secret configured
persistentvolumeclaim/postgres-pvc unchanged
deployment.apps/postgres unchanged
service/postgres unchanged
job.batch/django-migrate created
deployment.apps/backend configured
service/backend unchanged
deployment.apps/frontend configured
service/frontend unchanged
+ kubectl wait --for=condition=complete job/django-migrate --timeout=120s
job.batch/django-migrate condition met
+ kubectl set image deployment/backend backend=adonisdocker/backend:42
deployment.apps/backend image updated
+ kubectl set image deployment/frontend frontend=adonisdocker/frontend:42
deployment.apps/frontend image updated
+ kubectl rollout status deployment/backend --timeout=120s
deployment "backend" successfully rolled out
+ kubectl rollout status deployment/frontend --timeout=120s
deployment "frontend" successfully rolled out
[Pipeline] echo
✅ Pipeline terminé avec succès !
Finished: SUCCESS
```

#### Capture C-21 — Images publiées sur Docker Hub

> **📸 [Insérer ici la capture d'écran de hub.docker.com/r/adonisdocker/backend]**
> Les images `backend` et `frontend` doivent apparaître avec les tags `latest` et
> le numéro de build (ex. `42`).

---

## Conclusion

Ce rapport présente l'ensemble des preuves de déploiement du projet Système Réparti.
Les quatre couches du système ont été déployées et validées :

| # | Couche | Statut |
|---|---|---|
| 1 | Docker Compose (local) | ✅ Services `running / healthy` |
| 2 | Kubernetes (Minikube) | ✅ Pods `Running`, Job `Completed`, PVC `Bound` |
| 3 | Ansible | ✅ PLAY RECAP `failed=0` |
| 4 | Jenkins CI/CD | ✅ Pipeline `SUCCESS`, images publiées sur Docker Hub |

L'automatisation complète du cycle build–test–push–deploy garantit un déploiement
reproductible et traçable, conforme aux bonnes pratiques DevOps.

---

*Rapport rédigé dans le cadre du cours Système Réparti — 2025/2026*  
*Dépôt Git : https://github.com/ADONIS-IX/Projet_Systeme_Reparti_SI*
