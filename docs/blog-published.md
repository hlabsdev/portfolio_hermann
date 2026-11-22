# Registre des articles de blog

Tenue par la tache mensuelle de publication. Une ligne par article envoye a
l'API, dans l'ordre chronologique inverse (le plus recent en haut). Ne jamais
reutiliser un slug present ici.

| Date d'envoi | Titre | Slug | Statut | Publication | Sujet de la banque cloture |
| --- | --- | --- | --- | --- | --- |
| 22/11/2026 | Un blog Phoenix LiveView qui se publie tout seul | blog-phoenix-autopublication | published | 22/11/2026 | A1 |
| 12/11/2026 | Transcrire les débats parlementaires sans trahir la parole publique | transcription-debats-parlementaires | published | 12/11/2026 | B1 |

Notes :

* Statuts possibles : `draft`, `scheduled`, `published`.
* L'URL publique est toujours `https://portfolio-hermann.fly.dev/blog/<slug>`.
* En cas de suppression volontaire d'un article, conserver la ligne et ajouter
  `supprime` dans la colonne Statut.
