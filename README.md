# MarsAir

Modélisation de la qualité de l'air en tout point du territoire à partir de mesures ponctuelles.

## Description 

Ce dépôt les scripts créés dans le cadre du cours de M2 *Analyse Spatiale Avancée* du CMI Ingénierie pour la durabilité des territoires. 

## Données 

| Facteurs             | Sources de données (envisagées) | Réalisation       |
|----------------------|---------------------------------|-------------------|
| Mesures PM2,5        | AtmoSud                         | Antoine           |
| Trafic routier       | Geosirene + population + OSM    | N'Dri (geosirene) |
| Morphologie urbaine  | BDNB                            |                   |
| Sites industriels    | OCS GEO / CLC                   |                   |
| Trafic maritime      | AisHub                          |                   |
| Relief               | IGN                             | Capucine          |
| Vent                 | Meteo France                    | Yancouba          |
| Végétation           | OCS GE / Sentinel               | Jeanne            |

## Avancée

```
MarsAir
├── scripts
│   ├── zone.R           ✅
│   ├── emploi_pop.R 
│   ├── meteo.R
│   ├── mesures.R
│   ├── topographie.R
│   └── vegetation.R
├── data
│   ├── raw
│   └── clean
└── outputs
```