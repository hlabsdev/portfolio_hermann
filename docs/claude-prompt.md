# Prompt pour Claude — automatisation du blog

Deux prompts à copier-coller : l'installation (une fois), puis la tâche récurrente
(exécutée par un planificateur). Le second est déjà celui qu'utilise DeepSeek
Harness ; les deux reposent sur les mêmes fichiers.

## Prérequis

1. Le secret Fly `BLOG_PUBLISH_TOKEN` est configuré :
   `fly secrets set BLOG_PUBLISH_TOKEN=<jeton> --app portfolio-hermann`
2. Le même jeton est disponible dans la variable d'environnement de la machine qui
   exécute la tâche (profil utilisateur, gestionnaire de secrets, coffre de l'outil).
   Jamais dans un fichier du dépôt.
3. L'API répond : `node scripts/blog-publish.mjs check` doit afficher `OK`.

## Prompt d'installation (à donner une seule fois)

```text
Tu travailles dans le dépôt C:\work\portfolio_hermann : un portfolio Elixir/Phoenix
LiveView déployé sur Fly.io, avec un blog Markdown servi sur /blog et une API privée
de publication documentée dans docs/blog-automation.md (lis-la d'abord).

Objectif : mettre en place l'automatisation de publication du blog, à raison de trois
articles par mois (le 1er, le 11 et le 21 à 09:00), avec relecture d'une semaine.

Livrables attendus :

1. scripts/blog-publish.mjs — client Node sans dépendance de l'API de publication.
   Commandes : check, article --file <json> [--status draft|scheduled|published]
   [--dry-run], media --file <image> --alt <texte>, delete --slug <slug>.
   Exigences : lit BLOG_PUBLISH_TOKEN dans l'environnement et ne l'affiche jamais ;
   BLOG_API_URL optionnelle ; valide title, body_markdown (>= 500 caractères),
   status, published_at (futur si scheduled), absence de HTML brut, cover_url
   commençant par /article-media/ ; n'accepte que 200 + ok=true comme succès ;
   messages d'erreur explicites pour 503 not_configured et 401 unauthorized ;
   codes de sortie 0 (succès), 1 (erreur API), 2 (usage/configuration).

2. scripts/blog_images.py — primitives Python/Pillow pour les images d'articles,
   au style du site : fond slate très foncé, accent orange, cartes arrondies,
   typographie Segoe UI, rendu 2x puis réduction LANCZOS, export WebP.
   Fournis au minimum make_cover() et make_figure() (titre, sous-titre, cartes,
   pied de page optionnel).

3. docs/blog-automation-task.md — mode opératoire de la tâche récurrente :
   cadence (1er, 11, 21 à 09:00 Africa/Lome), prérequis, 7 étapes (vérifier le
   jeton, choisir le sujet, vérifier les faits, rédiger, illustrer, publier,
   journaliser), tableau des erreurs (503, 401, 409, 422, 415, réseau) et règles
   éditoriales (anonymisation des clients, sources citées, pas de HTML brut,
   tableaux GFM, listes et liens rendus par le site).

4. docs/blog-topics.md — banque de 10 à 12 sujets ancrés dans l'expérience réelle
   de Hermann (Elixir/Phoenix, DevOps, IA appliquée, secteur public, fintech et
   microfinance en Afrique de l'Ouest, ingénierie d'équipe), avec angle, statut
   (a traiter / en cours / traite), difficulté et ordre de publication conseillé.
   Ajoute une section "Notes de veille" pour éviter les versions annoncées à tort.

5. docs/blog-published.md — registre : date, titre, slug, statut, date de
   publication, sujet clôturé.

6. docs/social/<slug>.md — pour chaque article : un post X de moins de 280
   caractères, un fil X de 3 posts et un post LinkedIn de 900 à 1 300 caractères,
   tous avec l'URL publique https://portfolio-hermann.fly.dev/blog/<slug>.

7. Un planificateur qui exécute le prompt de tâche récurrente ci-dessous. Propose
   la solution native de la machine (cron ou Planificateur de tâches Windows) en
   appelant Claude en mode headless, par exemple :
   - macOS/Linux : 0 9 1,11,21 * * cd /chemin/portfolio_hermann && claude -p "$(cat docs/claude-task.md)"
   - Windows : schtasks /SC MONTHLY /D 1,11,21 /ST 09:00 /TR "pwsh -NoProfile -Command \"cd C:\work\portfolio_hermann; claude -p (Get-Content docs/claude-task.md -Raw)\""
   Le jeton doit venir de l'environnement du planificateur, jamais d'un fichier.

Contraintes :
- Ne jamais écrire le jeton dans un fichier, un article, un commit ou un log.
- Ne pas modifier la logique de l'API de publication ni la persistance.
- Après implémentation : exécute "node scripts/blog-publish.mjs article --file
  <exemple> --dry-run" pour vérifier la validation, et "node scripts/blog-publish.mjs
  check" pour vérifier l'accès à l'API.
- Termine par un récapitulatif des fichiers créés et la commande exacte pour
  déclencher une exécution manuelle.
```

## Prompt de tâche récurrente

À placer dans `docs/claude-task.md` (ou à donner à Claude à chaque exécution).

```text
Tâche de publication du blog technique de Hermann GOLO (portfolio Phoenix déployé sur
Fly.io). Espace de travail : C:\work\portfolio_hermann.

Lis ces documents avant d'agir : docs/blog-automation.md,
docs/blog-automation-task.md, docs/blog-topics.md, docs/blog-published.md.

1. Vérifie l'accès : node scripts/blog-publish.mjs check.
   Si 503 [not_configured] ou 401 [unauthorized], arrête-toi et signale que
   BLOG_PUBLISH_TOKEN doit être configuré côté Fly et côté environnement de la tâche.
2. Compare docs/blog-published.md et https://portfolio-hermann.fly.dev/blog pour
   éviter tout doublon de sujet ou de slug.
3. Prends le premier sujet "a traiter" de docs/blog-topics.md en suivant l'ordre de
   publication conseillé. Vérifie les faits par 2 à 4 recherches en ligne (sources
   2025-2026) et rédige un article inédit en français de 1 200 à 1 800 mots, ton
   retour d'expérience, avec tableaux GFM, listes à puces et liens, sans HTML brut.
4. Écris tmp/blog/<slug>/article.json : title, slug stable en kebab-case, summary,
   tags (2-4), status, published_at, body_markdown.
5. Génère au moins une image originale avec scripts/blog_images.py (diagramme ou
   schéma, style du site), exporte en WebP, téléverse-la avec
   node scripts/blog-publish.mjs media --file <image> --alt "..."
   et utilise l'URL renvoyée pour cover_url et dans le corps.
6. Publie avec status "scheduled" et published_at à J+7 à 09:00 UTC, via
   node scripts/blog-publish.mjs article --file tmp/blog/<slug>/article.json.
   Ne considère l'envoi réussi que si la sortie contient "OK: article".
   Vérifie ensuite la page publique : HTTP 200, tableaux/listes/liens présents
   (aucun paragraphe commençant par un tube), sinon corrige et republie.
7. Mets à jour docs/blog-published.md et passe le sujet à "traite" dans
   docs/blog-topics.md. Écris les versions X et LinkedIn dans docs/social/<slug>.md.

Règles : ne jamais afficher ni enregistrer le jeton ; aucune donnée client
confidentielle (OIF, Sanlam Allianz, Assemblée nationale du Togo, clients
microfinance) ; citer chaque source externe par un lien ; ne pas boucler sur une
erreur ; ne jamais supprimer un article existant.

Rapport final : titre, slug, URL publique, date de publication programmée, statut,
résumé en 3 phrases, sources vérifiées et chemins des versions sociales.
```

## Déclenchement manuel

```sh
node scripts/blog-publish.mjs check
node scripts/blog-publish.mjs article --file tmp/blog/<slug>/article.json --dry-run
node scripts/blog-publish.mjs article --file tmp/blog/<slug>/article.json --status published
```
