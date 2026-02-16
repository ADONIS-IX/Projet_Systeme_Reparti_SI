# Utiliser une image Python officielle comme base
FROM python:3.11-slim AS builder

# Définir le répertoire de travail
WORKDIR /app

# Installer les dépendances système nécessaires
RUN apt-get update && apt-get install -y gcc libpq-dev

# Copier le fichier des dépendances
COPY requirements.txt .

# Installer les dépendances Python
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

FROM python:3.11-slim
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /app

# Installer les dépendances système nécessaires
RUN apt-get update && apt-get install -y libpq5 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /install /usr/local

# Copier le code de l'application
COPY . .

# Créer l'utilisateur et changer les permissions AVANT de switcher
RUN useradd -m -u 1000 django \
    && chown -R django:django /app

# Switcher vers l'utilisateur django
USER django

# Maintenant collectstatic fonctionnera avec les bonnes permissions
RUN python manage.py collectstatic --noinput

# Exposer le port 8000
EXPOSE 8000

# Commande pour démarrer l'application
CMD ["gunicorn", "core.wsgi:application", \
    "--bind", "0.0.0.0:8000", \
    "--workers=3", \
    "--threads=2", \
    "--timeout=120"]