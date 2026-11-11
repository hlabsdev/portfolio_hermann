# Portfolio Hermann GOLO

Portfolio Elixir/Phoenix LiveView déployé sur Fly.io. Les projets et leurs médias
sont gérés depuis `/admin/projects`.

## Persistance Fly.io

**Avant d'appliquer ce changement à l'application déjà en ligne, sauvegarder les
données de la machine actuelle.** Jusqu'ici, projets et compteurs vivaient dans
le système de fichiers éphémère de la machine, et les anciens uploads sous
`priv/static/uploads`. Le nouveau volume vide est initialisé avec les JSON du
dépôt : il ne peut pas récupérer les dernières modifications faites en ligne.
Exporter les fichiers de la machine courante et les recopier dans le volume
`portfolio_data` avant de considérer la migration terminée.

Les données modifiables (projets, compteurs et images téléversées) sont stockées
dans `PORTFOLIO_DATA_DIR`. En production, `fly.toml` monte le volume
`portfolio_data` dans `/data`. Créer ce volume dans la région `cdg` avant le
premier déploiement :

```sh
fly volumes create portfolio_data --region cdg --size 1 --app portfolio-hermann
```

Le volume Fly est attaché à une seule machine/région. Il survit aux déploiements,
mais ne remplace pas une sauvegarde hors site. Sauvegarder régulièrement
`/data/projects.json`, `/data/techs.json`, `/data/analytics.json` et
`/data/uploads`. Avec plusieurs machines, migrer le stockage vers PostgreSQL
et un stockage objet tel que S3.

Au premier démarrage sur le volume, `projects.json` et `techs.json` sont initialisés
depuis les fichiers livrés avec l'application. En local, les données restent sous
`priv/` ; pour tester un répertoire différent, définir `PORTFOLIO_DATA_DIR`.

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: <https://www.phoenixframework.org/>
* Guides: <https://hexdocs.pm/phoenix/overview.html>
* Docs: <https://hexdocs.pm/phoenix>
* Forum: <https://elixirforum.com/c/phoenix-forum>
* Source: <https://github.com/phoenixframework/phoenix>

## TODO

* Gerer la creation d'article avec des fichiers markdown
* Formulaire de contact dynamique (Choix de projet et sujet) et qui m'envoie un mail directement
* Faire un post sur linkdein
