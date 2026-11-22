# Tache automatisee : trois articles de blog par mois

Ce document est le mode operatoire de la tache recurrente creee dans DeepSeek
Harness (voir aussi [l'API de publication](blog-automation.md)). La tache suit ce
fichier : si une regle doit changer, modifier ce document, pas le prompt de la
tache.

## Objet et cadence

* Objet : rediger, illustrer et publier un article de blog technique en francais
  sur le portfolio, a partir des competences reelles de Hermann et de recherches
  en ligne a jour.
* Cadence : trois executions par mois, les 1er, 11 et 21 a 09:00 (Africa/Lome).
  Chaque article est programme a J+7, donc publie le 8, le 18 et le 28.
* Session : session d'automatisation dediee (cible `new_once`), qui conserve son
  contexte d'une execution a l'autre.
* Resultat attendu : un article envoye avec `status: "scheduled"` et une date de
  publication a J+7, ce qui laisse une semaine de relecture avant mise en ligne.
  Pour publier immediatement, remplacer `scheduled` par `published` a l'etape 6.

## Prerequis

1. Secret Fly `BLOG_PUBLISH_TOKEN` configure :
   `fly secrets set BLOG_PUBLISH_TOKEN=<jeton> --app portfolio-hermann`
2. Le meme jeton enregistre dans le coffre de secrets de la session de tache.
3. Verification avant toute redaction : `node scripts/blog-publish.mjs check`
   * `OK` : l'API repond et le jeton est accepte.
   * `HTTP 503 [not_configured]` : le secret Fly manque ; arreter la tache et
     le signaler, ne rien publier.
   * `HTTP 401 [unauthorized]` : le jeton de la session ne correspond pas au
     secret Fly ; arreter et le signaler.
4. Le jeton ne doit apparaitre ni dans un article, ni dans un fichier du depot,
   ni dans un journal de la tache.

## Etapes de chaque execution

### 1. Verifier l'environnement et l'historique

* Executer `node scripts/blog-publish.mjs check`.
* Lire [le registre des articles publies](blog-published.md) : ne jamais reprendre
  un slug deja utilise.
* Verifier sur `https://portfolio-hermann.fly.dev/blog` que le sujet choisi ne
  figure pas deja en ligne.

### 2. Choisir le sujet

* Suivre l'ordre de publication conseille de [la banque de sujets](blog-topics.md)
  et prendre le premier sujet `a traiter` qui n'a pas encore de slug dans le registre.
* Si l'actualite rend un sujet obsolete, en choisir un autre et le noter dans le
  registre.
* Interdit : tutoriel generique sans experience personnelle, sujet deja traite,
  contenu qui expose un client sans accord (anonymiser, retirer les chiffres
  internes, ne jamais publier de donnees personnelles ou de secrets).

### 3. Rechercher et verifier

* Faire 2 a 4 recherches en ligne (sources 2025-2026 prioritaires) pour verifier
  les faits techniques, les versions et les pratiques actuelles.
* Toute affirmation externe doit etre sourcee par un lien dans l'article ou
  retiree. Ne pas inventer d'URL, de chiffre ou de citation.

### 4. Rediger l'article

* Francais, 1 200 a 1 800 mots, ton retour d'experience, a la premiere personne.
* Structure : accroche concrete (probleme et contexte), 5 a 8 sections H2,
  extraits de code ou tableau si utile, encadre "ce que j'en retiens", conclusion
  avec limites de l'approche.
* Markdown uniquement, rendu par le site en GitHub Flavored Markdown (GFM).
  Structures supportees :
  * titres (`#` a `######`), paragraphes, **gras**, *italique*, ~~texte barre~~ ;
  * listes a puces (`-`), listes numerotees (`1.`), listes de taches
    (`- [x]` / `- [ ]`, affichees avec une case a cocher) ;
  * tableaux GFM avec ligne d'en-tete (`| Colonne | ... |` + `| --- |`),
    rendus avec en-tetes et bordures et defilant horizontalement sur mobile :
    preferer un tableau a une liste des qu'il y a plusieurs colonnes ;
  * citations (`>`), y compris les encadres GitHub (`> [!NOTE]`,
    `> [!TIP]`, `> [!WARNING]`), blocs de code clotures par des backticks avec
    langue (` ```elixir `), code inline, traits de separation (`---`) ;
  * liens, liens automatiques (une URL en clair devient un lien), images,
    notes de bas de page (`[^1]` + `[^1]: ...`), emoticones `:smile:`.
  Le HTML brut (balises `<script>`, `<div>`, `onerror=`...) n'est pas rendu : le
  site l'ignore (il est remplace par un commentaire invisible dans la page). Ne
  pas s'en servir pour mettre en forme, utiliser les structures Markdown
  ci-dessus. Ces structures sont couvertes par
  `test/portfolio_hermann_web/markdown_test.exs`.
* Eviter les superlatifs creux ; assumer les contraintes (budget, equipement,
  connectivite, delais).
* Ecrire l'article dans `tmp/blog/<slug>/article.json` avec les champs
  `title`, `slug` (stable, kebab-case, court), `summary` (1 a 2 phrases),
  `tags` (2 a 4), `status`, `published_at`, `body_markdown`.

### 5. Illustrer

* Image de couverture recommandee : schema d'architecture ou graphique
  original, genere avec Python/Pillow (voir `scripts/blog_images.py` pour les
  primitives et le style : fond slate tres fonce, accent orange, cartes arrondies).
  Format WebP, moins de 8 Mo. Au moins une figure dans le corps en plus de la couverture.
* Ne jamais fabriquer une fausse capture d'ecran ni publier un ecran client
  identifiable.
* Televerser avec `node scripts/blog-publish.mjs media --file <image> --alt "<texte alternatif>"`,
  puis reprendre l'URL `/article-media/...` renvoyee dans `cover_url` et dans le corps.

### 6. Publier

* Relire `article.json` puis :
  `node scripts/blog-publish.mjs article --file tmp/blog/<slug>/article.json`
* Ajouter `--status published` pour publier tout de suite, ou laisser
  `scheduled` (J+7) pour la relecture.
* Ne considerer l'etape terminee que si la sortie contient `OK: article`.
* En cas d'erreur, appliquer la section "Erreurs" et ne pas boucler.

### 7. Journaliser et rapporter

* Ajouter une ligne dans [le registre](blog-published.md) : date, titre, slug,
  statut, URL, sujet de la banque cloture.
* Ecrire les versions sociales dans `docs/social/<slug>.md` : un post X court
  (moins de 280 caracteres) avec le lien public, un fil X de 3 posts, et un post
  LinkedIn de 900 a 1 300 caracteres avec le lien et 3 a 5 enseignements.
* Message final : titre, slug, URL publique, date de publication programmee,
  statut, resume en 3 phrases, la liste des sources verifiees et les chemins des
  versions sociales.

## Erreurs

| Reponse | Cause probable | Action |
| --- | --- | --- |
| `503 not_configured` | secret Fly absent | arreter, signaler, ne pas reessayer |
| `401 unauthorized` | jeton de session different | arreter, demander la rotation |
| `409 slug_taken` | slug deja pris par un autre article | changer de slug, ne pas ecraser |
| `422 ...` | champ invalide | corriger la charge utile, ne pas boucler |
| `415 unsupported_image` | format d'image | convertir en WebP ou PNG |
| reseau | panne Fly ou reseau local | reessayer une fois, puis signaler |

## Regles editoriales

* Le blog engage Hermann : exactitude, pas d'exageration, pas de contenu genere
  sans relecture humaine des faits.
* Les donnees clients (OIF, Sanlam Allianz, Assemblee nationale du Togo, clients
  microfinance) restent confidentielles : decrire la categorie de probleme et
  l'architecture generique, jamais les noms de personnes, montants ou documents
  internes.
* Slug stable apres publication ; ne jamais supprimer un article publie sans
  instruction explicite.
