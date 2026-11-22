# Versions sociales — blog-phoenix-autopublication

Article : https://portfolio-hermann.fly.dev/blog/blog-phoenix-autopublication
Publication programmée : 29 novembre 2026, 09:00 UTC
Image à joindre : la couverture de l'article (ratio 16:9).

## X (Twitter) — post unique (266 caractères, limite 280)

```
Un blog qui se publie tout seul : Markdown, API privée, date programmée. Pas de CI ni de déploiement pour corriger une virgule.

Ce que ce dogfooding m'a appris sur les fichiers et les sauvegardes :
https://portfolio-hermann.fly.dev/blog/blog-phoenix-autopublication
```

## X — fil de 3 posts

**Post 1/3 (232 car.)**

```
Un article programmé n'a pas besoin d'un cron : j'enregistre published_at et la LiveView compare la date. Aucun job à maintenir, aucun double envoi au redémarrage.

https://portfolio-hermann.fly.dev/blog/blog-phoenix-autopublication
```

**Post 2/3 (234 car.)**

```
Le stockage : un JSON sur un volume Fly, écriture atomique et verrou. Trois articles par mois, oui. Deux machines, non : le verrou protège un nœud, pas deux volumes.

https://portfolio-hermann.fly.dev/blog/blog-phoenix-autopublication
```

**Post 3/3 (192 car.)**

```
Les snapshots Fly (5 jours par défaut) ne sont pas une sauvegarde. Ma copie de référence reste /data — c'est la dette que je raconte. Et vous, que se passe-t-il si le disque meurt cette nuit ?
```

## LinkedIn (1 286 caractères, limite 3 000)

```
Ce blog se publie tout seul.

Une tâche écrit le Markdown, téléverse une image, appelle une API privée protégée par un jeton, et l'article devient visible à la date prévue. Aucun déploiement pour corriger une faute.

Je l'ai construit pour ce portfolio Phoenix hébergé sur Fly.io : une machine, un volume, un fichier JSON, un jeton. C'est peu, et c'est suffisant pour trois articles par mois. C'est aussi fragile dès qu'on change d'échelle.

Cinq choses que ce dogfooding m'a apprises :

1. Un blog peut se publier sans intégration continue ni redéploiement : une API privée et un volume persistant suffisent.
2. La publication programmée par comparaison de dates est plus simple et plus robuste qu'un job planifié.
3. Un fichier JSON verrouillé et écrit de façon atomique tient pour quelques dizaines d'articles, pas pour plusieurs machines.
4. Un jeton unique est acceptable pour un projet personnel, pas pour une API d'équipe : pas de rotation, pas d'audit, pas de scopes.
5. Les snapshots Fly (1 à 60 jours) ne remplacent pas une copie hors site. Ma copie de référence reste /data, et c'est la dette la plus sérieuse.

L'architecture complète, les limites et ce que je changerais :
https://portfolio-hermann.fly.dev/blog/blog-phoenix-autopublication

#Elixir #Phoenix #FlyIO #DevOps
```

## Hashtags de secours

#Elixir #Phoenix #FlyIO #DevOps #DéveloppementLogiciel

## Conseils de diffusion

* Joindre la couverture aux deux plateformes.
* Sur X, publier le post 1 puis les réponses dans les minutes qui suivent.
* Sur LinkedIn, publier entre 8 h et 10 h en semaine ; garder le lien dans le corps du post.
* Répondre aux commentaires dans la première heure : la portée en dépend.
* Le lien public ne sera actif qu'à partir du 29 novembre 2026 à 09:00 UTC.
