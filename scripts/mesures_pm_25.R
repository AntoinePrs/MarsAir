rm(list=ls())

# Packages
library(lubridate)

# ---- Paramètres --------------------------------------------------------------
MOIS          <- "2026-09"


# Bornes temporelles 
debut <- ymd(paste0(MOIS, "-01"), tz = "UTC")
fin   <- debut %m+% months(1)                 # borne exclusive
iso   <- function(x) format(x, "%Y-%m-%dT%H:%M:%S+00:00")




capteurs <- fromJSON("https://api.aircarto.fr/capteurs/metadata?capteurType=NebuleAir&format=JSON")
stations <- fromJSON("https://api.atmosud.org/observations/stations?format=json&station_en_service=true&polluant_en_service=true&download=false&metadata=true")
