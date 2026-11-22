# Banque de sujets du blog

Reserve editoriale de la tache mensuelle. Chaque sujet est ancre dans une
experience reelle de Hermann et evite le tutoriel generique. La tache prend le
premier sujet `a traiter`, le redige, puis le passe a `traite` (avec le slug
utilise) dans ce fichier et dans [le registre](blog-published.md).

Colonnes : `Statut` = a traiter | en cours | traite. `Difficulte` = effort de
redaction et de verification (1 = rapide, 5 = lourd).

## Pilier A - Elixir, Phoenix et exploitation en production

| # | Titre de travail | Angle | Statut | Difficulte |
| --- | --- | --- | --- | --- |
| A1 | Un blog Phoenix LiveView qui se publie tout seul | Dogfooding : ce portfolio, l'API privee, le volume persistant et les sauvegardes | traite (`blog-phoenix-autopublication`, 22/11/2026) | 2 |
| A2 | Phoenix sur Fly.io : ce que la persistance par volume change vraiment | Choix de stockage, sauvegardes, limites mono-region, migration vers Postgres/S3 | a traiter | 3 |
| A3 | LiveView en production : les pieges que la documentation ne dit pas | Sessions, memoire, assignations, tests, observabilite | a traiter | 4 |

## Pilier B - IA appliquee et donnees

| # | Titre de travail | Angle | Statut | Difficulte |
| --- | --- | --- | --- | --- |
| B1 | Transcrire les debats d'une assemblee parlementaire sans trahir la parole publique | Pipeline audio, ASR, correction, GED, gouvernance des donnees | traite (`transcription-debats-parlementaires`, 12/11/2026) | 4 |
| B2 | Un modele de ML sur GPU en production : latence, couts et supervision | Deploiement GPU, ELK + Grafana, derive de modele, alerting | a traiter | 4 |
| B3 | Recherche semantique pour des PME francophones : du mapping Elasticsearch au ranking | Analyse multi-langue, synonymes metier, evaluation | a traiter | 3 |
| B4 | Un chatbot institutionnel ancre dans des documents officiels | RAG, sources citees, garde-fous, evaluation | a traiter | 4 |

## Pilier C - Fintech, microfinance et produits de terrain

| # | Titre de travail | Angle | Statut | Difficulte |
| --- | --- | --- | --- | --- |
| C1 | Microfinance offline-first : synchroniser sans perdre une ecriture | Architecture Django/Flutter, conflits, files d'attente, support | a traiter | 4 |
| C2 | Facturation et primes : industrialiser un modele actuariel en production | Pipeline Python, validation metier, tracabilite | a traiter | 4 |

## Pilier D - Ingenierie d'equipe et secteur public

| # | Titre de travail | Angle | Statut | Difficulte |
| --- | --- | --- | --- | --- |
| D1 | Keycloak : federer les identites d'applications heterogenes | SSO, roles, migrations, exploitation | a traiter | 3 |
| D2 | Livrer un logiciel public quand la maintenance n'est pas budgetee | Tests, documentation, reprise par une autre equipe | a traiter | 3 |
| D3 | Piloter une equipe distribuee avec Jira sans theatre agile | Epics, stories, cadence, definition of done | a traiter | 2 |

## Ordre de publication conseille

1. ~~**B1** - Transcrire les debats parlementaires~~ (publie le 12/11/2026)
2. ~~**A1** - Un blog Phoenix LiveView qui se publie tout seul~~ (programme le 29/11/2026)
3. **B3** - Recherche semantique pour des PME francophones
4. **C1** - Microfinance offline-first
5. **A2** - Phoenix sur Fly.io : persistance par volume
6. **D1** - Keycloak et federation d'identites
7. **D2** - Maintenance d'un logiciel public non budgetee
8. **B2** - Modele ML sur GPU en production
9. **D3** - Piloter une equipe distribuee sans theatre agile
10. **C2** - Industrialiser un modele actuariel
11. **B4** - Chatbot institutionnel ancre dans des documents officiels
12. **A3** - LiveView en production : les pieges

## Notes de veille (verifiees le 12 novembre 2026)

A relire avant de rediger, pour ne pas publier une version fausse :

* LiveView 1.2 est stable depuis juin 2026 ; Phenix 1.8 est la version stable.
  Ne pas annoncer Phoenix 1.9 ou LiveView 1.3 comme publies : ils sont en
  developpement.
* Les volumes Fly sont lies a une Machine, non repliques, avec des snapshots ;
  verifier la limite de taille dans la documentation avant de citer un chiffre.
* Les GPU heberges chez Fly.io ne sont plus disponibles pour de nouveaux
  usages : ne pas proposer Fly comme plateforme d'inference GPU.
* pgvector 0.9 est annonce comme non publie : citer 0.8.x tant que la version
  n'est pas sortie.
* Verifier toute version de bibliotheque sur son changelog ou sur hex.pm avant
  de l'ecrire dans un article.

## Garde-fous communs

* Anonymiser les clients et retirer tout chiffre interne non public.
* Une source par affirmation externe ; sinon, retirer l'affirmation.
* Un seul sujet par article ; les details techniques servent la these.
