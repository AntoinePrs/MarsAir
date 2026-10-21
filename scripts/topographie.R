#===============================================================================
# Nom : topographie.R
# Objet : création d'un raster d'altitude (à l'échelle de la grille)
# Auteur : Antoine Peris, UMR CNRS 7300 ESPACE
# Date : 21/10/2026
#===============================================================================

# Packages
library(sf)
library(ggplot2)
library(dplyr)
library(terra)

# Paramètres
CRS_L93 <- 2154   # Lambert-93 : système de coordonnées de la BD ALTI
MARGE   <- 500    # marge (m) autour de la grille, pour couvrir entièrement les mailles de bord

# Chargement de la grille (reprojetée en Lambert-93 si besoin)
grid   <- st_read("data/clean/grille.gpkg") |> st_transform(CRS_L93)
grid_v <- vect(grid)

# Emprise de la grille + marge
e <- ext(grid_v)
emprise <- ext(xmin(e) - MARGE, xmax(e) + MARGE, ymin(e) - MARGE, ymax(e) + MARGE)

# Définition du dossier dans lequel on trouve le téléchargement BD Alti
# (renommé src_dir : "source" masquait la fonction base::source)
src_dir <- "/home/perisa/Téléchargements/BDALTIV2_2-0_25M_ASC_LAMB93-IGN69_D013_2022-12-16/BDALTIV2/1_DONNEES_LIVRAISON_2023-01-00224/BDALTIV2_MNT_25M_ASC_LAMB93_IGN69_D013/"

# Définition du dossier où écrire les tuiles pertinentes
dest <- "data/raw/bdalti/"
dir.create(dest, recursive = TRUE, showWarnings = FALSE)

#-------------------------------------------------------------------------------
# 1. Identification et copie des tuiles qui recouvrent la grille
#-------------------------------------------------------------------------------

# Extraction de la liste des fichiers
f <- list.files(src_dir, pattern = "\\.asc$", full.names = TRUE)

# Emprise de chaque tuile (lecture de l'en-tête uniquement) et test de recouvrement
emprises <- lapply(f, function(x) ext(rast(x)))

# Boucle d'intersection  
int <- sapply(1:length(f), function(x) relate(ext(rast(f[x])), emprise, "intersects"))
f_sel <- f[int]
cat(length(f_sel), "tuile(s) recouvrent la grille.")

# Copie des tuiles retenues (et des fichiers associés, de même nom : .prj, .xml...)
file.copy(f_sel, dest, overwrite = TRUE)

#-------------------------------------------------------------------------------
# 2. Assemblage des tuiles puis découpe selon l'emprise de la grille
#-------------------------------------------------------------------------------

# Lecture des tuiles copiées (un .asc n'embarque pas toujours son CRS)
tuiles <- lapply(list.files(dest, full.names = T), function(x) {
  r <- rast(x)
  if (crs(r) == "") crs(r) <- paste0("EPSG:", CRS_L93)
  r
})



mnt <- terra::merge(sprc(tuiles))
mnt <- terra::crop(mnt, emprise, snap = "out")
names(mnt) <- "altitude"
mnt   # contrôle : résolution 25 m, étendue, valeurs min/max

# Ecriture du MNT fin si besoin
writeRaster(mnt, "data/clean/mnt_25m_emprise.tif", overwrite = TRUE)    

#-------------------------------------------------------------------------------
# 3. Visualisation du MNT découpé (25 m) avec le contour de la grille
#-------------------------------------------------------------------------------
plot(mnt, main = "BD ALTI 25 m - emprise de la grille")
plot(as.polygons(e, crs = crs(grid_v)), add = TRUE, border = "red", lwd = 2)

#-------------------------------------------------------------------------------
# 4. Agrégation des valeurs suivant les mailles de la grille
#-------------------------------------------------------------------------------

# Moyenne des pixels 25 m dont le centre tombe dans chaque maille
ex <- terra::extract(mnt, grid_v, fun = mean, na.rm = TRUE)
grid$alt_moy <- ex[[2]]

summary(grid$alt_moy)

#-------------------------------------------------------------------------------
# 5. Visualisation du résultat
#-------------------------------------------------------------------------------
ggplot(grid) +
  geom_sf(aes(fill = alt_moy), colour = NA) +
#  geom_sf(data = grid, fill=NA, linewidth=.1)+
  scale_fill_viridis_c(name = "Altitude\nmoyenne (m)", na.value = "grey90") +
  labs(title = "Altitude moyenne par maille (BD ALTI 25 m)") +
  theme_minimal()

#-------------------------------------------------------------------------------
# 6. Enregistrement en raster (pour la modélisation)
#-------------------------------------------------------------------------------

# Taille de maille déduite de la grille (contrôle : doit valoir 100)
taille <- round(sqrt(median(as.numeric(st_area(grid)))))
cat("Taille de maille estimée :", taille, "m\n")

# Raster modèle calé sur l'emprise de la grille, puis rasterisation de l'altitude moyenne
modele <- rast(e, resolution = taille, crs = crs(grid_v))
grid_v$alt_moy <- grid$alt_moy
alt <- terra::rasterize(grid_v, modele, field = "alt_moy")
names(alt) <- "altitude"
plot(alt, main = "Altitude moyenne (maille de la grille)")

# Ecriture de la grille avec les données d'altitude
writeRaster(alt, "data/clean/altitude_grille.tif", overwrite = TRUE)    # altitude à l'échelle de la grille
