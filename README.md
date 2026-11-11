# Portfolio Hermann GOLO

Portfolio Elixir/Phoenix LiveView déployé sur Fly.io. Après connexion à `/login`,
les projets se gèrent dans `/admin/projects`, le parcours dans `/admin/experiences`
et les articles dans `/admin/articles`.

## Persistance Fly.io

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

Au premier démarrage sur le volume, les fichiers de données sont initialisés
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

## Contact et automatisation

* Le formulaire de contact achemine les messages avec FormSubmit vers `ghermann@yulcom.ca`.
  Le premier envoi doit être confirmé depuis la boîte de réception du destinataire. Le contenu est traité par ce fournisseur externe et n'est pas archivé sur le volume Fly.
* Les articles se rédigent en Markdown depuis `/admin/articles` et sont conservés dans `/data/articles.json`.
  Pour les tâches Claude ou DeepSeek Harness, voir [l’API et le guide d’automatisation](docs/blog-automation.md).
  Configurer un jeton aléatoire dans le secret Fly `BLOG_PUBLISH_TOKEN` et dans le coffre de secrets de la tâche.
