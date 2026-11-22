# Sujet de blog n°1 - proposition

Date de la proposition : 12 novembre 2026.
Base : experiences reelles de Hermann (YULCOM, Assemblee nationale du Togo,
fintech/microfinance) + recherches en ligne verifiees ci-dessous.

## Recommandation n°1

**Titre de travail : Transcrire les debats parlementaires sans trahir la parole
publique - anatomie d'une chaine ASR + GED**

* Slug pressenti : `transcription-debats-parlementaires` (stable, a conserver apres publication)
* Tags : `IA`, `Services publics`, `Donnees`
* Resume public : "Un compte rendu parlementaire automatise ne se resume pas a un
  modele de reconnaissance vocale. Architecture, qualite, gouvernance et
  enseignements d'un projet mene pour une assemblee nationale."
* Sujet B1 dans [la banque de sujets](blog-topics.md).

### These

Le compte rendu parlementaire n'est pas un probleme de speech-to-text, c'est un
probleme editorial et de gouvernance. Le modele vocal represente une petite part
du travail ; l'essentiel se joue autour : captation audio, segmentation par
orateur, lexique metier (noms d'institutions, titres, procedures, articles de
loi), validation humaine, archivage et tracabilite. Un article qui explique cette
chaine, avec ses limites et ses couts, est plus utile - et plus rare - qu'un
tutoriel Whisper.

### Pourquoi maintenant (signaux verifies)

* Le Senat francais etudie l'usage de l'IA pour la retranscription des comptes
  rendus des debats (Public Senat, 18 avril 2025) :
  https://www.publicsenat.fr/actualites/institutions/lusage-de-lintelligence-artificielle-est-a-letude-au-senat-pour-les-comptes-rendus-des-debats
* L'Union interparlementaire publie un catalogue de cas d'usage de l'IA dans les
  parlements, dont les comptes rendus automatises de type Hansard (decembre 2024) :
  https://www.ipu.org/resources/publications/reference/2024-12/use-cases-ai-in-parliaments
  et la fiche detaillee :
  https://www.ipu.org/fr/ai-use-cases/systeme-automatise-de-comptes-rendus-hansard-conversion-de-laudio-parlementaire-en-texte-laide-de-lia
* Le Togo engage la numerisation de son Assemblee nationale avec l'appui des
  Nations unies (Togo First, 3 juin 2025) :
  https://www.togofirst.com/en/itc/0306-16470-togo-un-to-support-digitalization-process-of-national-assembly
* L'Assemblee nationale francaise lance en 2026 un hackathon d'IA souveraine pour
  ses travaux, avec un defi de transcription et de comptes rendus structures :
  https://hackathon2026.assemblee-nationale.fr/defis/ae4eed5e-cebe-4461-ba87-87683dcae953
* Le secteur public francais structure justement le duo capture / GED / IA
  (Archimag, 8 septembre 2026) :
  https://www.archimag.com/demat-cloud/2026/09/08/secteur-public-piloter-information-intelligente-capture-ged-bpm-ia
* Cote outillage, les briques evoluent : Whisper (large ~10 Go de VRAM, turbo ~6 Go
  et environ 8 fois plus rapide), LiveView 1.2 stable depuis juin 2026
  (https://phoenixframework.org/blog/phoenix-liveview-1-2-released).

Constat de marche : les articles existants sur le sujet sont institutionnels ou
juridiques ; les retours d'ingenierie en francais sont presque inexistants.

### Public vise

Directions des systemes d'information d'institutions publiques, integrateurs
francophones, chefs de projet govtech, recruteurs cherchant un profil "IA
appliquee + ingenierie de production", developpeurs curieux d'un retour de
terrain plutot que d'une demonstration.

### Plan propose (H2)

1. Ce qu'un compte rendu doit garantir : fidelite, lisibilite, tracabilite
2. Le contexte : une assemblee, des contraintes de connectivite, de budget et de souverainete
3. La chaine complete : captation, segmentation, ASR, normalisation, validation, archivage
4. Le lexique metier, ou se gagne la qualite (noms propres, homophones, procedures, articles de loi)
5. Mesurer autre chose que le WER : entites nommees, taux de correction humaine par minute
6. GPU dedie, API externe ou hybride : couts, latence, confidentialite
7. Gestion documentaire et conservation : versions, indexation, droits d'acces (Keycloak)
8. Ce que j'en retiens : une checklist en 8 points pour un projet de transcription institutionnelle

### Experience a mobiliser

GED et transcription automatisee des debats pour l'Assemblee nationale du Togo
(anonymisee : aucun nom de personne, aucun volume contractuel), supervision de
plateformes OIF (ELK/Grafana), livraison en contexte public, Keycloak, Docker.

### Garde-fous redactionnels

* Aucun document interne, aucun nom d'elu ou de fonctionnaire, aucun chiffre
  contractuel non public.
* Distinguer clairement les faits sources (liens ci-dessus) de l'experience
  personnelle.
* Assumer les limites : la validation humaine reste indispensable, et le cout de
  cette validation est le vrai sujet budgetaire.

### Chiffres a mettre en avant si disponibles

Heures d'audio traitees, cout par heure d'audio, taux d'erreur par type de
locuteur, delai entre la seance et le compte rendu publiable, taux de correction
humaine.

## Alternatives solides

### A1 - Un blog Phoenix LiveView qui se publie tout seul

* Angle : dogfooding de ce portfolio (API privee, volume persistant Fly.io,
  sauvegardes, Markdown). Public : developpeurs Elixir/Phoenix.
* Forces : demonstration immediate, sujet maitrise, bon deuxieme article pour
  amorcer le blog. Faiblesse : moins differenciant, un peu auto-centre.
* Faits utiles verifies : les volumes Fly sont lies a une seule Machine, non
  repliques, avec des snapshots (https://docs.fly.io/volumes/overview) ; le prix
  de l'egress en Afrique est plus eleve qu'en Amerique du Nord
  (https://fly.io/pricing/), un angle original pour un hebergement a Lomé.

### B3 - Recherche semantique pour des PME francophones

* Angle : du mapping Elasticsearch au ranking metier, avec evaluation (BM25 +
  embeddings, RRF). Public : equipes data/produit. Force : expertise rare
  (plateforme OIF). Faiblesse : demande plus etroite, plus de pedagogie.

## Ordre de publication conseille

1. B1 (signature : positionne l'expertise "IA + secteur public")
2. A1 (amorce le blog cote communaute Elixir, plus facile a partager)
3. B3 ou C1 (approfondit les piliers data et fintech)

## Sources verifiees le 12 novembre 2026

* Public Senat, IA et comptes rendus des debats au Senat (18/04/2025)
* UIP, cas d'usage de l'IA dans les parlements (12/2024)
* UIP, comptes rendus Hansard automatises
* Togo First, numerisation de l'Assemblee nationale (03/06/2025)
* Hackathon Assemblee nationale 2026, defi AnIA SCRIPT
* Archimag, capture / GED / IA dans le secteur public (08/09/2026)
* Phoenix LiveView 1.2 (10/06/2026)
* Documentation Fly.io, volumes persistants et tarifs
