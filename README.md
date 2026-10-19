# PCA / PCR model identification | Identification de modèles par ACP / PCR

**EN** — Compare least-squares and PCA-based regression methods on a small process dataset, with a focus on scaling, prediction errors and correlated inputs.

**FR** — Comparer les méthodes de régression par moindres carrés et par ACP sur un petit jeu de données de procédé, en étudiant l’effet de la mise à l’échelle, les erreurs de prédiction et les variables corrélées.

[← Back to portfolio](https://github.com/mlmdc) · [Contents / Sommaire](#contents--sommaire)

![Least-squares and PCA model predictions on the standardized dataset](medias/LSE_PCA_err_std.png)

## Contents / Sommaire

- [Overview / Présentation](#overview--présentation)
- [Problem & approach / Problématique et approche](#problem--approach--problématique-et-approche)
- [Technical decisions / Choix techniques](#technical-decisions--choix-techniques)
- [Results & learnings / Résultats et apprentissages](#results--learnings--résultats-et-apprentissages)
- [Getting started](#getting-started)

## Overview / Présentation

**EN** — This MATLAB project estimates the process output `I_EFF` from three inputs: `A_FLOW`, `T_H2O` and `C_ACID`. It is intended for students and practitioners exploring linear model identification, least-squares estimation, principal component analysis (PCA) and principal component regression (PCR). The scripts compare model fits across input scaling methods and examine coefficient behavior when predictors are strongly correlated.

**FR** — Ce projet MATLAB estime la sortie du procédé `I_EFF` à partir de trois variables d’entrée : `A_FLOW`, `T_H2O` et `C_ACID`. Il s’adresse aux étudiants et praticiens qui étudient l’identification de modèles linéaires, les moindres carrés, l’analyse en composantes principales (ACP) et la régression sur composantes principales (PCR). Les scripts comparent les ajustements selon plusieurs méthodes de mise à l’échelle et examinent la stabilité des coefficients lorsque des variables sont fortement corrélées.

### Features / Fonctionnalités

| EN | FR |
| --- | --- |
| Compare least-squares estimation (LSE) with PCA-based regression and PCR. | Comparaison des moindres carrés (LSE), d’une régression fondée sur l’ACP et de la PCR. |
| Evaluate unscaled, min–max scaled and z-score inputs. | Évaluation des données brutes, normalisées entre 0 et 1 et standardisées par score-z. |
| Generate plots for model fits, errors and coefficient evolution under collinearity. | Génération de graphiques sur les ajustements, les erreurs et l’évolution des coefficients en présence de colinéarité. |
| Run a 7-fold cross-validation experiment on the 21 observations in the dataset. | Exécution d’une validation croisée en 7 plis sur les 21 observations du jeu de données. |

## Problem & approach / Problématique et approche

**EN** — With only 21 observations, the project examines how input scaling and collinearity affect a linear model’s predictions and parameter estimates. It implements least-squares and PCA/PCR workflows, selects principal components using a 95% cumulative explained-variance threshold, and compares the resulting fits and errors.

**FR** — Avec seulement 21 observations, le projet étudie l’influence de la mise à l’échelle et de la colinéarité sur les prédictions et les paramètres d’un modèle linéaire. Il met en œuvre les moindres carrés et des approches ACP/PCR, sélectionne les composantes jusqu’à 95 % de variance cumulée expliquée, puis compare les ajustements et les erreurs obtenus.

## Technical decisions / Choix techniques

**EN** — MATLAB is used for matrix-based numerical work and plotting; the dataset is included as a `.mat` file. The script compares min–max scaling and z-scores because PCA is scale-sensitive, and uses a 95% variance threshold to choose components. A small synthetic perturbation of a predictor is used to explore collinearity; no random seed is set, so that experiment can vary between runs.

**FR** — MATLAB est utilisé pour les calculs matriciels et les graphiques ; le jeu de données est fourni au format `.mat`. Les normalisations min–max et par score-z sont comparées, car l’ACP dépend de l’échelle des variables ; un seuil de 95 % de variance détermine le nombre de composantes. Une perturbation synthétique d’une variable sert à étudier la colinéarité ; aucune graine aléatoire n’étant fixée, cette expérience peut varier d’une exécution à l’autre.

## Results & learnings / Résultats et apprentissages

**EN**

- The repository includes plots comparing fitted curves and errors for LSE and PCA-based models, as well as plots of parameter evolution in the collinearity experiment.
- The comparisons make the influence of scaling and correlated inputs inspectable; the repository does not report a consolidated quantitative benchmark showing that one method is consistently more accurate.
- The analysis is limited to 21 observations. Cross-validation is implemented in the script, but the checked-in figures are not a substitute for a reproducible, aggregated evaluation; the collinearity experiment is stochastic.

**FR**

- Le dépôt contient des graphiques comparant les courbes ajustées et les erreurs des modèles LSE et fondés sur l’ACP, ainsi que l’évolution des paramètres dans l’expérience de colinéarité.
- Ces comparaisons permettent d’observer l’effet de l’échelle et des variables corrélées ; le dépôt ne fournit pas de benchmark quantitatif consolidé démontrant qu’une méthode est systématiquement plus précise.
- L’analyse porte sur 21 observations. La validation croisée est implémentée, mais les figures versionnées ne remplacent pas une évaluation agrégée et reproductible ; l’expérience de colinéarité comporte une part aléatoire.

## Getting started

### Requirements

- MATLAB R2024a or later (the main script defines local functions before its script statements).
- Statistics and Machine Learning Toolbox (`cvpartition` is used for 7-fold cross-validation).

### Run

Open MATLAB in the repository directory, where `VAJA3.mat` is located, then run:

```matlab
run("assignement3.m")
```

The script loads the dataset, runs the comparisons and opens figures. The repository also includes `kqzd.m`, a separate synthetic linear least-squares curve-fitting example:

```matlab
run("kqzd.m")
```

No additional configuration or package installation is required.
