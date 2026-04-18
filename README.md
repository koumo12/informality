# Informality Research

Analyse économétrique des déterminants de l'emploi informel à l'échelle internationale.
Panel de données couvrant la période 2000–2023, construit à partir de sources publiques (Banque mondiale, ILO, WGI, Tax Foundation).

## Question de recherche

Quels facteurs structurels (productivité du travail, gouvernance, accès au crédit, fiscalité, infrastructure) expliquent le niveau d'emploi informel dans les pays en développement et développés ?

## Structure du projet

```
informality-research/
├── data/
│   ├── raw/          ← données sources (xlsx, non modifiées)
│   └── processed/    ← fichiers .RData générés par les scripts (non versionnés)
├── R/
│   ├── 01\_import.R       ← téléchargement et import des sources
│   ├── 02\_clean\_merge.R  ← nettoyage, fusion, construction du panel
│   ├── 03\_models.R       ← estimation économétrique, tests
│   └── 04\_plots.R        ← visualisations
├── output/           ← graphiques et tableaux exportés (non versionnés)
├── docs/             ← rapport final, notes de travail
└── README.md
```

## Sources de données

|Source|Indicateurs|Accès|
|-|-|-|
|[World Development Indicators](https://data.worldbank.org/)|Accès électricité, internet, crédit privé...|API via `{WDI}`|
|[ILO](https://ilostat.ilo.org/)|Informalité, productivité, salaire minimum|API via `{Rilostat}`|
|[Worldwide Governance Indicators](https://info.worldbank.org/governance/wgi/)|Qualité réglementaire|Fichier local `wgi.xlsx`|
|[Tax Foundation](https://taxfoundation.org/)|Taux IS|Fichier local `cit.xlsx`|

## Variable dépendante

`shareInfOdd` : part de l'emploi informel transformée en log-odds  
`log(informality / (100 - informality))`

## Modèles estimés

* **Pooled OLS** (référence)
* **Effets fixes** (within, individus)
* **Effets aléatoires** (GLS)
* Tests : Breusch-Pagan, Hausman

## Comment reproduire les résultats

```r
# Lancer les scripts dans l'ordre
source("R/01\_import.R")
source("R/02\_clean\_merge.R")
source("R/03\_models.R")
source("R/04\_plots.R")
```

> Les scripts `02`, `03` et `04` chargent les fichiers `.RData` produits par l'étape précédente.

## Dépendances R

```r
install.packages(c(
  "WDI", "Rilostat", "readxl", "openxlsx",
  "dplyr", "tidyr", "purrr",
  "plm", "broom",
  "ggplot2", "corrplot"
))
```

## Auteur

Koumo Mahamat

