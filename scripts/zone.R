#===============================================================================
# Nom : zone.R
# Objet : Définition du périmètre et création de la grille
# Auteur : Antoine Peris, UMR CNRS 7300 ESPACE
# Date : 06/10/2026
#===============================================================================

# Charger le package osmdata
library(osmdata)
library(dplyr)
library(sf)
library(ggplot2)
library(ggspatial)


# Définition du lien vers l'API Overpass
set_overpass_url("https://lz4.overpass-api.de/api/interpreter")

# Récupérer les données de périmètres administratifs à Marseille
marseille <- opq("Marseille") |> 
  add_osm_feature(key = "boundary", value = "administrative") |> 
  osmdata_sf()

# Afficher les données
print(marseille)

# Sélection du périmètre municipal de Marseille
mun <- marseille$osm_multipolygons |> 
  filter(admin_level=="8", 
         name == "Marseille")

# Visualisation de la commune
ggplot()+
  annotation_scale()+
  annotation_north_arrow(style = north_arrow_minimal(), 
                         location = "br")+
  geom_sf(data = mun)+
  theme_minimal()+
  coord_sf(datum = NA)

# Éclater le multipolygone en polygones individuels
mun <- mun |> 
  st_make_valid() |>
  st_union() |>          
  st_sf()

polys <- st_cast(mun, "POLYGON")

# Calculer les aires et garder le plus grand
polys$aire <- as.numeric(st_area(polys))
plus_grand <- polys[which.max(polys$aire), ]

# Renommage des colones
colnames(polys)[1] <- "geom"

# Reprojection
mun <- st_transform(mun, 2154)

# Création d'une grille
grid <- st_make_grid(mun, 100)

# Ecriture des données
st_write(plus_grand, "data/marseille.gpkg", append = F)
st_write(plus_grand, "data/grille.gpkg", append = F)
