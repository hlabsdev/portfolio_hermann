# Portfolio Hermann GOLO

Portfolio Elixir/Phoenix LiveView déployé sur Fly.io ([portfolio-hermann.fly.dev](https://portfolio-hermann.fly.dev)).
Après connexion à `/login`, les projets se gèrent dans `/admin/projects`, le parcours dans
`/admin/experiences`, les articles dans `/admin/articles` et les statistiques dans `/admin/stats`.

## Stack technique (v1.0.0)

| Composant | Version stable |
| --- | --- |
| Elixir / Erlang OTP | 1.20.5 / OTP 29.1.2 |
| Phoenix | 1.8.17 |
| Phoenix LiveView | 1.2.15 |
| Bandit | 1.15.0 |
| Phoenix LiveDashboard | 0.9.1 |
| MDEx (Markdown vers HTML) | 0.14.7 |
| Tailwind CSS / esbuild | 3.4.19 / 0.28.2 |

Les dépendances sont verrouillées dans `mix.lock` ; l'image de production est construite par
le `Dockerfile` (Debian bookworm, Elixir 1.20.5, OTP 29.1.2).

## Développement local

Prérequis : Elixir 1.20+ avec Erlang/OTP 29.

```sh
mix setup          # dépendances + assets
mix phx.server     # http://localhost:4000
mix test           # suite ExUnit (inclut les tests Markdown et publication)
```

Le port d'écoute peut être surchargé avec `PORT` (utile si 4000 est réservé sur Windows) :

```sh
PORT=4300 mix phx.server
```

## Contenu et administration

### Articles

Les articles sont rédigés en Markdown depuis `/admin/articles` et conservés sur le volume
persistant Fly (`/data/articles.json`). Trois statuts explicites sont proposés dans l'éditeur :

* **Brouillon** : jamais visible publiquement ;
* **Programmé** : visible à partir de la date/heure UTC choisie (champ « Publication programmée ») ;
* **Publié (maintenant)** : publication immédiate.

Un article programmé peut être publié tout de suite de deux façons :

* dans la liste de `/admin/articles`, bouton **« Publier maintenant »** ;
* via l'API de publication, en renvoyant l'article avec `status: "published"` sans `published_at`
  (voir [la documentation de l'API](docs/blog-automation.md)).

Éditer un article déjà publié conserve sa date de publication d'origine.

### Rendu Markdown

`PortfolioHermannWeb.Helpers.md_to_html/1` centralise le rendu MDEx avec les extensions
GitHub Flavored Markdown : tableaux, listes ordonnées et non ordonnées, listes de tâches,
texte barré, citations, encadrés `[!NOTE]`, blocs de code avec langue, liens automatiques,
notes de bas de page, images et emoji. Le HTML brut présent dans un article est ignoré
(jamais exécuté). Les styles sont fournis par le plugin `@tailwindcss/typography` et des
compléments dans `assets/css/app.css` (tableaux scrollables sur mobile, cases à cocher,
citations, mode sombre).

### Persistance Fly.io

Les données modifiables (projets, compteurs, parcours, articles et images téléversées) sont stockées
dans `PORTFOLIO_DATA_DIR`. En production, `fly.toml` monte le volume
`portfolio_data` dans `/data`. Créer ce volume dans la région `cdg` avant le
premier déploiement :

```sh
fly volumes create portfolio_data --region cdg --size 1 --app portfolio-hermann
```

Le volume Fly est attaché à une seule machine/région. Il survit aux déploiements,
mais ne remplace pas une sauvegarde hors site. Sauvegarder régulièrement
`/data/projects.json`, `/data/techs.json`, `/data/experiences.json`,
`/data/articles.json`, `/data/analytics.json` et
`/data/uploads`. Avec plusieurs machines, migrer le stockage vers PostgreSQL
et un stockage objet tel que S3.

## Optimisations

* Lectures JSON mises en cache (`:persistent_term`) avec invalidation par `mtime`/taille/inode et
  écriture traversante : plus de lecture/décodage à chaque requête.
* Compteurs de vues agrégés en mémoire et écrits par lots (toutes les 5 s, plus un flush à
  l'arrêt propre) au lieu d'une écriture disque par page vue ; statistiques limitées à 365 jours.
* Assets statiques gzippés servis directement depuis les `.gz` produits par `mix phx.digest`.
* Images inutilisées retirées/compressées, composants morts supprimés.

## Déploiement

```sh
fly deploy --app portfolio-hermann
```

Le build Docker exécute `mix deps.get`, `mix assets.deploy` (Tailwind + esbuild + digest) et
`mix release`. Les secrets requis sont `SECRET_KEY_BASE`, `ADMIN_PASSWORD` et
`BLOG_PUBLISH_TOKEN` (`fly secrets list`).

## Automatisation du blog

* Une tâche planifiée rédige et programme trois articles par mois : voir le
  [mode opératoire](docs/blog-automation-task.md), la [banque de sujets](docs/blog-topics.md)
  et le [registre des publications](docs/blog-published.md).
* Le client de publication s'utilise avec `node scripts/blog-publish.mjs check`, puis
  `node scripts/blog-publish.mjs article --file article.json`. Avec `--status published`,
  l'article est publié immédiatement (la date programmée obsolète est ignorée).
* Le formulaire de contact achemine les messages avec FormSubmit vers `kekeligolo@gmail.com`.
  Le premier envoi doit être confirmé depuis la boîte de réception du destinataire.

## Learn more

* Official website: <https://www.phoenixframework.org/>
* Guides: <https://hexdocs.pm/phoenix/overview.html>
* Docs: <https://hexdocs.pm/phoenix>
* Forum: <https://elixirforum.com/c/phoenix-forum>
