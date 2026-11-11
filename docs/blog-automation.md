# Automatiser la publication du blog

Le blog est disponible sur `/blog`. Les articles se gèrent manuellement dans
`/admin/articles` ou depuis une tâche d’automatisation via l’API privée.
L’API accepte du Markdown et écrit dans le même stockage persistant que
l’interface d’administration.

## Authentification

Chaque appel d’écriture doit envoyer :

```http
Authorization: Bearer <BLOG_PUBLISH_TOKEN>
```

Génère un jeton aléatoire long, configure-le comme secret Fly sous
`BLOG_PUBLISH_TOKEN`, puis enregistre exactement le même jeton dans le coffre de
secrets de la tâche Claude ou DeepSeek Harness. Ne le mets ni dans le dépôt, ni
dans le contenu d’un article, ni dans les journaux de la tâche. Pour le changer,
remplace le secret Fly et celui de la tâche ensemble.

Tant que `BLOG_PUBLISH_TOKEN` n’est pas configuré, les endpoints d’écriture
répondent `503`. Un jeton absent ou incorrect reçoit `401`.

## Créer, mettre à jour ou programmer un article

`POST https://portfolio-hermann.fly.dev/api/articles`

```json
{
  "title": "Livrer une application Phoenix sur Fly.io",
  "slug": "phoenix-fly-io",
  "summary": "Retour d’expérience sur la mise en production et la persistance.",
  "tags": ["Elixir", "Phoenix", "DevOps"],
  "cover_url": "/article-media/UUID.webp",
  "status": "draft",
  "body_markdown": "# Introduction\n\nLe contenu complet en **Markdown**…"
}
```

Valeurs possibles de `status` :

* `draft` : conservé dans l’administration, invisible publiquement.
* `published` : visible immédiatement.
* `scheduled` : conservé comme publié, mais invisible jusqu’à `published_at`.

Exemple de publication programmée :

```json
{
  "title": "Article à publier plus tard",
  "slug": "article-a-publier-plus-tard",
  "summary": "Résumé public.",
  "tags": ["Data"],
  "status": "scheduled",
  "published_at": "2026-12-01T09:00:00+00:00",
  "body_markdown": "# Article\n\nTexte en Markdown."
}
```

`published_at` doit être une date ISO 8601 avec fuseau horaire. Une tâche peut
utiliser un slug fixe : renvoyer le même slug met à jour l’article existant au
lieu d’en créer un second. Garde ce slug stable après publication pour ne pas
changer l’adresse de l’article.

Pour supprimer un brouillon ou un article, appeler
`DELETE /api/articles/<slug>` avec le même en-tête Bearer.

## Ajouter des images

`POST https://portfolio-hermann.fly.dev/api/articles/media`

Envoie un formulaire `multipart/form-data` avec un champ `file` :

```sh
curl -X POST "https://portfolio-hermann.fly.dev/api/articles/media" \
  -H "Authorization: Bearer $BLOG_PUBLISH_TOKEN" \
  -F "file=@schema.webp" \
  -F "alt=Architecture de déploiement"
```

Les formats JPEG, PNG, GIF et WebP sont acceptés jusqu’à 8 Mo. L’API vérifie
l’extension et la signature du fichier. La réponse contient `url` et `markdown`;
copie le Markdown renvoyé dans `body_markdown`. Les fichiers sont enregistrés
sous `/data/uploads/articles` et servis sous `/article-media/<nom>`, donc les
liens restent valides après les déploiements.

Le corps d’article accepte le Markdown courant, y compris les images, liens,
listes, tableaux et blocs de code. Le HTML brut n’est pas rendu. Pour une vidéo,
utilise un lien vers la plateforme vidéo ou intègre une image cliquable.

## Exemple de tâche planifiée

1. Rédiger l’article et ses images dans l’espace de travail de la tâche.
2. Téléverser les images; reprendre leurs URL dans le Markdown.
3. Envoyer l’article avec `status: "draft"` pour demander une relecture, ou
   `status: "published"` pour le publier.
4. Pour une date de publication précise, envoyer `status: "scheduled"` et
   `published_at` en ISO 8601.

L’API renvoie l’article enregistré et son slug. Les erreurs de validation
retournent un code HTTP 4xx avec un champ `error.code`; ne considère la tâche
terminée que si `ok` vaut `true`.
