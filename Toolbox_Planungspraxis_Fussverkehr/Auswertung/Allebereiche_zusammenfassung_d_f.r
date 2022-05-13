####Voraussetzung Skript Auswertung alle Bereiche:

# 1. Die Ordnerstruktur vom Repository ist unverändert
# 2. Die Ausgefüllten Raster vom Bereichplanungspraxis sind im selben Ordner wie diese Datei. Die Dateien beginnen alle mit der vierstelligen BFS-NR_XXXXXX.xlsx
# 3. Die Auswertungen für den Bereich Infrasturktur und Befragung ist gemacht und die Werte sind in der Datei Gesamtbewertung/Kaptiel_5_P2_Übersichtstabelle.xlsx eingetragen. Die Datei ist nach BFS-Nr. aufsteigend sortiert.

# Wenn 3. nicht erfüllt ist, können nur die Diagramme zur Planungspraxis verwendet werden.


#install the required packages
if(!require("tidyverse")) install.packages("tidyverse")
if(!require("readxl")) install.packages("readxl")
if(!require("fmsb")) install.packages("fmsb")
if(!require("scales")) install.packages("scales")
if(!require("ggplot2")) install.packages("ggplot2")
if(!require("tidyr")) install.packages("tidyr")
if(!require("svglite")) install.packages("svglite")
if(!require("writexl")) install.packages("writexl")
if(!require("systemfonts")) install.packages("systemfonts")



#load the required packages
library(tidyverse)
library(scales)
library(readxl)
library(fmsb)
library(ggplot2)
library(tidyr)
library(svglite)
library(writexl)
library(systemfonts)


##GGPLOT Farbpalette
Calibri <- match_font("Calibri")

theme_set(theme_bw())+theme(text = element_text(family = "Times New Roman"))

# GEHsund corporate colors
gehsund_colors <- c(
  `red`        = "#e83f37",
  `light red`        = "#e97868",
  `dark red`        = "#bb181c",
  `green`      = "#5db23e",
  `light green`      = "#9fc646",
  `dark green`      = "#099b48",
  `blue`       = "#088bcc",
  `light blue`       = "#90d1db",
  `dark blue`       = "#24438d",
  `pink`       = "#e83278",
  `light pink`       = "#24438d",
  `dark pink`       = "#951b81",
  `orange`     = "#ee7219",
  `light orange`     = "#f6a124",
  `yellow`     = "#feca2b",
  `light grey` = "#ededed",
  `grey` = "#b2b2b2",
  `dark grey`  = "#706f6f")

#' Function to extract drsimonj colors as hex codes
#'
#' @param ... Character names of drsimonj_colors 
#'
gehsund_cols <- function(...) {
  cols <- c(...)
  
  if (is.null(cols))
    return (drsimonj_colors)
  
  gehsund_colors[cols]
}

#combine colors into palettes

gehsund_palettes <- list(
  `main`  = gehsund_cols("blue","light blue", "dark blue", "green", "light green", "dark green", "pink","light pink", "dark pink", "red", "light red",  "dark red", "yellow", "light orange", "orange","light grey", "grey", "dark grey"),
  
  `bericht1`  = gehsund_cols("blue", "light blue","dark blue"),
  
  `bericht2`   = gehsund_cols("green", "light green", "dark green"),
  
  `bericht3` = gehsund_cols("pink", "light pink", "dark pink"),
  
  `bericht ti` = gehsund_cols("red", "light red", "dark red"),
  
  `grey`  = gehsund_cols("light grey", "grey", "dark grey")
)

#' Return function to interpolate a gehsund color palette
#'
#' @param palette Character name of palette in gehsund_palettes
#' @param reverse Boolean indicating whether the palette should be reversed
#' @param ... Additional arguments to pass to colorRampPalette()
#'
gehsund_pal <- function(palette = "main", reverse = FALSE, ...) {
  pal <- gehsund_palettes[[palette]]
  
  if (reverse) pal <- rev(pal)
  
  colorRampPalette(pal, ...)
}

#' Color scale constructor for gehsund colors
#'
#' @param palette Character name of palette in gehsund_palettes
#' @param discrete Boolean indicating whether color aesthetic is discrete or not
#' @param reverse Boolean indicating whether the palette should be reversed
#' @param ... Additional arguments passed to discrete_scale() or
#'            scale_color_gradientn(), used respectively when discrete is TRUE or FALSE
#'
scale_color_gehsund <- function(palette = "main", discrete = TRUE, reverse = FALSE, ...) {
  pal <- gehsund_pal(palette = palette, reverse = reverse)
  
  if (discrete) {
    discrete_scale("colour", paste0("gehsund_", palette), palette = pal, ...)
  } else {
    scale_color_gradientn(colours = pal(256), ...)
  }
}

#' Fill scale constructor for gehund colors
#'
#' @param palette Character name of palette in gehsund_palettes
#' @param discrete Boolean indicating whether color aesthetic is discrete or not
#' @param reverse Boolean indicating whether the palette should be reversed
#' @param ... Additional arguments passed to discrete_scale() or
#'            scale_fill_gradientn(), used respectively when discrete is TRUE or FALSE
#'
scale_fill_gehsund <- function(palette = "main", discrete = TRUE, reverse = FALSE, ...) {
  pal <- gehsund_pal(palette = palette, reverse = reverse)
  
  if (discrete) {
    discrete_scale("fill", paste0("gehsund_", palette), palette = pal, ...)
  } else {
    scale_fill_gradientn(colours = pal(256), ...)
  }
}

#Arbeitsverzeichnis laden
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#Generiert die Liste der Exceldateien
file.list <- list.files(pattern='*.xlsx')

#Generiert eine Liste mit Data Frames aus den dem Bereich D101:D106 des Arbeitsblattes Bewertungsraster der Exceldateien 
df.list <- sapply(file.list, range = "D101:D107", sheet = 1, read_excel)

#Wandelt die Liste in ein Data Frame um
df.planungspraxis <- data.frame(t(sapply(df.list,c)))

n.gemeinden <- nrow(df.planungspraxis)

#Definieren der Deutschen Titel
c.planungspraxis.d <- c('Strategien,\nRessourcen', 'Fusswegnetzplanung', 'Öffentlicher Raum', 'Fussverkehr als Teil\ndes Gesamtverkehrs' , 'Kommunikation,\nControlling','Gesamtwertung')
c.planungspraxis.f <- c('Stratégies et\nressources' , 'Planification du\nréseau piéton' , 'Espace public' , 'La marche comme mode de\ndéplacement à part entière','Communication','Évaluation globale')
#Bei den Zeilennamen alles hinter dem ersten _ abschneiden. Damit steht dort nur den die BFS Nr.
colnames(df.planungspraxis) <- c.planungspraxis.d

clean.rownames <- as.vector(rownames(df.planungspraxis))



clean.rownames <- gsub("_.*","",clean.rownames)

rownames(df.planungspraxis) <- clean.rownames

df.list_Einwohner <- sapply(file.list, range = "Bewertungsraster!C2:C3", read_excel)
df.Einwohner <- data.frame(t(sapply(df.list_Einwohner,c)))
colnames(df.Einwohner) <- clean.rownames

#Daten Infrastruktur und Befragung importieren 
#Das Excel muss A-Z nach Gemeindename sortiert sein.

df.infrastruktur <- as.data.frame(read_excel("Gesamtbewertung/Kaptiel_5_P2_Übersichtstabelle.xlsx",range=paste0("Übersichtstabelle!C5:G",5+n.gemeinden)))
df.infrastruktur_scaled <- round(df.infrastruktur/100, 2)
df.befragung <- as.data.frame(read_excel("Gesamtbewertung/Kaptiel_5_P2_Übersichtstabelle.xlsx",range=paste0("Übersichtstabelle!N5:s",5+n.gemeinden) ))
df.befragung_scaled <- round(df.befragung/100, 2)

#Deutsche Beschriftung

c.infrastruktur.d <- colnames(df.infrastruktur)
c.befragung.d <- colnames(df.befragung)


#Eine Zeile mit den Minimas, Maximas und Mittelwerte definieren und als Zeilen 1-3 an das data frame anfügen.
 c.max.punkte.praxis <- c(13,14,16,35,22,100)
 c.max.punkte.infra <- c(1,1,1,1,1)
 c.max.punkte.befragung <- c(1,1,1,1,1,1)
 
 c.min.punkte.infra <- c(0,0,0,0,0)
 c.min.punkte.praxis <- c(0,0,0,0,0,0)
 c.min.punkte.befragung <- c.min.punkte.praxis
 
 c.mittelwerte.infrastruktur_scaled <- colMeans(df.infrastruktur_scaled)
 c.mittelwerte.planungspraxis <- colMeans(df.planungspraxis)
 c.mittelwerte.befragung_scaled <- colMeans(df.befragung_scaled)

 #Die Zeilen Min, Max und Average beschriften
 df.planungspraxis <- rbind(c.max.punkte.praxis, c.min.punkte.praxis, c.mittelwerte.planungspraxis, df.planungspraxis)
 rownames(df.planungspraxis) <- c('Max', 'Min', 'Average', clean.rownames)
 
 df.infrastruktur_scaled <- rbind(c.max.punkte.infra, c.min.punkte.infra, c.mittelwerte.infrastruktur_scaled, df.infrastruktur_scaled)
rownames(df.infrastruktur_scaled) <- c('Max', 'Min', 'Average', clean.rownames)

df.befragung_scaled <- rbind(c.max.punkte.befragung, c.min.punkte.befragung, c.mittelwerte.befragung_scaled, df.befragung_scaled)
rownames(df.befragung_scaled) <- c('Max', 'Min', 'Average', clean.rownames)
 #Auf Werte von 0-1 Skalieren
 df.planungspraxis.scaled <- round(apply(df.planungspraxis, 2, scales::rescale), 2)
 df.planungspraxis.scaled <- as.data.frame(df.planungspraxis.scaled)

 #Alle Bereiche zusammfassen
 
 df_alle <- cbind(df.infrastruktur_scaled[c(1,2,3,4)], df.planungspraxis.scaled[c(1,2,3,4,5)], df.befragung_scaled[c(1,2,3,4,5)])
 df_alle <- round(df_alle, 2)
 #Holt Gemeindenamen und BFS Nummer
 ## Die Datei BFSNR_Bewertung_Planungspraxis_Gemeindename.xlsx muss im Übergeordneten Verzeichnis liegen.
 
  df.list.gemeindenamen <- sapply("../BFSNR_Bewertung_Planungspraxis_Gemeindename.xlsx", range = "Gemeinde_Kennzahlen!A9:B2181", read_excel)
  GemeindeNamen <- df.list.gemeindenamen[1]
 
  
  #Bereitet die Daten für GGPlot vor 
  df.planungspraxis.scaled.plot <- df.planungspraxis.scaled[4:nrow(df.planungspraxis.scaled),]
  df.infrastruktur.scaled.plot <- df.infrastruktur_scaled[4:nrow(df.infrastruktur_scaled),]
  df.befragung.scaled.plot <- df.befragung_scaled[4:nrow(df.befragung_scaled),]
  

  GemeindeNamen <- as.factor(as.integer(row.names(df.planungspraxis.scaled.plot)))
  GemeindeNamen <- factor(GemeindeNamen, levels = c(df.list.gemeindenamen[[1]]), labels = c(df.list.gemeindenamen[[2]]))
  

  
  df.planungspraxis.scaled.plot <- cbind(df.planungspraxis.scaled.plot, GemeindeNamen)
  df.infrastruktur.scaled.plot <- cbind(df.infrastruktur.scaled.plot, GemeindeNamen)
  df.befragung.scaled.plot <- cbind(df.befragung.scaled.plot, GemeindeNamen)
  

  
  df.planungspraxis.scaled.plot.long <- df.planungspraxis.scaled.plot %>% gather(categorie, bewertung, -c(GemeindeNamen))
  df.infrastruktur.scaled.plot.long <- df.infrastruktur.scaled.plot %>% gather(categorie, bewertung, -c(GemeindeNamen))
  df.befragung.scaled.plot.long <- df.befragung.scaled.plot %>% gather(categorie, bewertung, -c(GemeindeNamen))
  
  df.planungspraxis.scaled.plot.long$categorie <- factor(df.planungspraxis.scaled.plot.long$categorie,levels = rev(c.planungspraxis.d))  
  df.infrastruktur.scaled.plot.long$categorie <- factor(df.infrastruktur.scaled.plot.long$categorie,levels= rev(c.infrastruktur.d))
  df.befragung.scaled.plot.long$categorie <- factor(df.befragung.scaled.plot.long$categorie, levels = rev(c.befragung.d))

  mean.planungspraxis <- df.planungspraxis.scaled.plot.long%>% group_by(categorie)%>%summarise(bewertung=mean(bewertung))
  mean.infrastruktur <- df.infrastruktur.scaled.plot.long%>% group_by(categorie)%>%summarise(bewertung=mean(bewertung))
  mean.befragung <- df.befragung.scaled.plot.long%>% group_by(categorie)%>%summarise(bewertung=mean(bewertung))
  
  
 #Spiderdiagramme erzeugen und in Unterordner Spider mit als BFS-NR.svg abspeichern
 for (i in 4:nrow(df.planungspraxis.scaled)) {
         setwd("Spider")
         file.name <- gsub(" ", "", paste(row.names(df.planungspraxis.scaled)[i],".svg"))
         svg(file.name)
         
        GemeindeName <- as.factor(as.integer(row.names(df.planungspraxis.scaled)[i]))
        GemeindeName <- factor(GemeindeName, levels = c(df.list.gemeindenamen[[1]]), labels = c(df.list.gemeindenamen[[2]]))
         
         radarchart(
                 df_alle[c(1:3, i), ],
                 pfcol = c("#b2b2b280",NA),
                 pcol= c(NA,gehsund_cols("green")), plty = 1, plwd = 2,
                 title = GemeindeName,
                 axistype=1,
                 vlcex=0.81,
                 cglty=1,
                 cglcol="#b2b2b280",
                 axislabcol="#b2b2b280",
                 caxislabels=c("0%", "25%", "50%", "75%", "100%")
         )
         
         
            dev.off() 
         setwd("..")
         
#Strahldiagramm mit Mittelwert Planungspraxis wird in Unterordner planungspraxis abgelegt.
         
         setwd("planungspraxis")
         file.name <- gsub(" ", "", paste(row.names(df.planungspraxis.scaled)[i],".svg"))

         df.planungspraxis.scaled.plot.long.single <- df.planungspraxis.scaled.plot.long %>%filter(GemeindeNamen == GemeindeName)
         
         planungspraxis.scaled.plot.title <- toString(paste("Planungspraxis",GemeindeName))
         
         image=df.planungspraxis.scaled.plot.long %>% ggplot(aes(x=categorie, y=bewertung)) + scale_y_continuous(labels=scales::percent) + coord_flip() + geom_point(color= gehsund_cols("dark grey"), size = 3)+ggtitle(planungspraxis.scaled.plot.title)+theme(axis.title.x = element_blank(), axis.title.y = element_blank(), text = element_text(family = "Calibri", size=20)) +geom_point(data = df.planungspraxis.scaled.plot.long.single, color = gehsund_cols("pink"), size = 6)+geom_point(data = mean.planungspraxis, mapping=aes(x=as.numeric(categorie)+0.05, y=bewertung), color = "black", size =10, shape ="|")+theme(legend.position="none")

         ggsave(file=file.name, plot=image, width=10, height=5)
         

         
         setwd("..")
         
         #Strahldiagramm mit Mittelwert Infrastruktur wird in Unterordner strahl_infrastruktur abgelegt.
         
         setwd("strahl_infrastruktur")
         file.name <- gsub(" ", "", paste(row.names(df.planungspraxis.scaled)[i],".svg"))
         
         df.infrastruktur.scaled.plot.long.single <- df.infrastruktur.scaled.plot.long %>%filter(GemeindeNamen == GemeindeName)
         
         infrastruktur.scaled.plot.title <- toString(paste("Fussverkehrstest",GemeindeName))
         
         image=df.infrastruktur.scaled.plot.long %>% ggplot(aes(x=categorie, y=bewertung)) + scale_y_continuous(labels=scales::percent) + coord_flip() + geom_point(color= gehsund_cols("dark grey"), size = 3, outlier.shape = NA)+ggtitle(infrastruktur.scaled.plot.title)+theme(axis.title.x = element_blank(), axis.title.y = element_blank(), text = element_text(family = "Calibri", size=20)) +geom_point(data = df.infrastruktur.scaled.plot.long.single, color = gehsund_cols("green"), size = 6)+geom_point(data = mean.infrastruktur, mapping=aes(x=as.numeric(categorie)+0.05, y=bewertung), color = "black", size =10, shape ="|")+theme(legend.position="none")

         ggsave(file=file.name, plot=image, width=10, height=5)
         
         
         
         setwd("..")
         
         #Strahldiagramm mit Mittelwert Befragung wird in Unterordner strahl_befragung abgelegt.
         
         setwd("strahl_befragung")
         file.name <- gsub(" ", "", paste(row.names(df.planungspraxis.scaled)[i],".svg"))
         
         df.befragung.scaled.plot.long.single <- df.befragung.scaled.plot.long %>%filter(GemeindeNamen == GemeindeName)
         
         befragung.scaled.plot.title <- toString(paste("Zufriedenheit",GemeindeName))
         
         image=df.befragung.scaled.plot.long %>% ggplot(aes(x=categorie, y=bewertung)) + scale_y_continuous(labels=scales::percent) + coord_flip() + geom_point(color= gehsund_cols("dark grey"), size = 3, outlier.shape = NA)+ggtitle(befragung.scaled.plot.title)+theme(axis.title.x = element_blank(), axis.title.y = element_blank(), text = element_text(family = "Calibri", size=20)) +geom_point(data = df.befragung.scaled.plot.long.single, color = gehsund_cols("blue"), size = 6)+geom_point(data = mean.befragung, mapping=aes(x=as.numeric(categorie)+0.05, y=bewertung), color = "black", size =10, shape ="|")+theme(legend.position="none")

         ggsave(file=file.name, plot=image, width=10, height=5)
         
         
         
         setwd("..")
         
 }
  df.planungspraxis.scaled.plot.long$categorie <- factor(df.planungspraxis.scaled.plot.long$categorie,levels = c.planungspraxis.d)  

 



write_xlsx(df.planungspraxis.scaled.plot, "planungspraxis/auswertung_plaungspraxis.xlsx")

######################### Franz

#Definieren der Franz Titel
c.planungspraxis.f <- c('Stratégies et\nressources' , 'Planification du\nréseau piéton' , 'Espace public' , 'La marche comme mode de\ndéplacement à part entière','Communication','Évaluation globale')
colnames(df.planungspraxis) <- c.planungspraxis.f
colnames(df.planungspraxis.scaled) <- c.planungspraxis.f


c.infrastruktur.f <- c('Tronçons' , 'Traversées' , 'Arrêts TP' , 'Places','Évaluation globale')
colnames(df.infrastruktur) <- c.infrastruktur.f
colnames(df.infrastruktur_scaled) <- c.infrastruktur.f

c.befragung.d <- colnames(df.befragung)
c.befragung.f <- c('Importance dans\nla planification' , 'Réseau piéton' , 'Bien-être' , 'Infrastructures','Cohabitation','Évaluation globale')
colnames(df.befragung) <- c.befragung.f
colnames(df.befragung_scaled) <- c.befragung.f




#Alle Bereiche zusammfassen

df_alle <- cbind(df.infrastruktur_scaled[c(1,2,3,4)], df.planungspraxis.scaled[c(1,2,3,4,5)], df.befragung_scaled[c(1,2,3,4,5)])
df_alle <- round(df_alle, 2)


#Bereitet die Daten für GGPlot vor 
df.planungspraxis.scaled.plot <- df.planungspraxis.scaled[4:nrow(df.planungspraxis.scaled),]
df.infrastruktur.scaled.plot <- df.infrastruktur_scaled[4:nrow(df.infrastruktur_scaled),]
df.befragung.scaled.plot <- df.befragung_scaled[4:nrow(df.befragung_scaled),]


GemeindeNamen <- as.factor(as.integer(row.names(df.planungspraxis.scaled.plot)))
GemeindeNamen <- factor(GemeindeNamen, levels = c(df.list.gemeindenamen[[1]]), labels = c(df.list.gemeindenamen[[2]]))



df.planungspraxis.scaled.plot <- cbind(df.planungspraxis.scaled.plot, GemeindeNamen)
df.infrastruktur.scaled.plot <- cbind(df.infrastruktur.scaled.plot, GemeindeNamen)
df.befragung.scaled.plot <- cbind(df.befragung.scaled.plot, GemeindeNamen)



df.planungspraxis.scaled.plot.long <- df.planungspraxis.scaled.plot %>% gather(categorie, bewertung, -c(GemeindeNamen))
df.infrastruktur.scaled.plot.long <- df.infrastruktur.scaled.plot %>% gather(categorie, bewertung, -c(GemeindeNamen))
df.befragung.scaled.plot.long <- df.befragung.scaled.plot %>% gather(categorie, bewertung, -c(GemeindeNamen))

df.planungspraxis.scaled.plot.long$categorie <- factor(df.planungspraxis.scaled.plot.long$categorie,levels = rev(c.planungspraxis.f))  
df.infrastruktur.scaled.plot.long$categorie <- factor(df.infrastruktur.scaled.plot.long$categorie,levels= rev(c.infrastruktur.f))
df.befragung.scaled.plot.long$categorie <- factor(df.befragung.scaled.plot.long$categorie, levels = rev(c.befragung.f))

mean.planungspraxis <- df.planungspraxis.scaled.plot.long%>% group_by(categorie)%>%summarise(bewertung=mean(bewertung))
mean.infrastruktur <- df.infrastruktur.scaled.plot.long%>% group_by(categorie)%>%summarise(bewertung=mean(bewertung))
mean.befragung <- df.befragung.scaled.plot.long%>% group_by(categorie)%>%summarise(bewertung=mean(bewertung))


#Spiderdiagramme erzeugen und in Unterordner Spider_f mit als BFS-NR.svg abspeichern
for (i in 4:nrow(df.planungspraxis.scaled)) {
  setwd("Spider_f")
  file.name <- gsub(" ", "", paste(row.names(df.planungspraxis.scaled)[i],".svg"))
  svg(file.name)
  
  GemeindeName <- as.factor(as.integer(row.names(df.planungspraxis.scaled)[i]))
  GemeindeName <- factor(GemeindeName, levels = c(df.list.gemeindenamen[[1]]), labels = c(df.list.gemeindenamen[[2]]))
  
  radarchart(
    df_alle[c(1:3, i), ],
    pfcol = c("#b2b2b280",NA),
    pcol= c(NA,gehsund_cols("green")), plty = 1, plwd = 2,
    title = GemeindeName,
    axistype=1,
    vlcex=0.81,
    cglty=1,
    cglcol="#b2b2b280",
    axislabcol="#b2b2b280",
    caxislabels=c("0%", "25%", "50%", "75%", "100%")
  )
  
  
  dev.off() 
  setwd("..")
  
  #Strahldiagramm mit Mittelwert Planungspraxis wird in Unterordner planungspraxis abgelegt.
  
  
  setwd("planungspraxis_f")
  file.name <- gsub(" ", "", paste(row.names(df.planungspraxis.scaled)[i],".svg"))
  
  df.planungspraxis.scaled.plot.long.single <- df.planungspraxis.scaled.plot.long %>%filter(GemeindeNamen == GemeindeName)
  
  planungspraxis.scaled.plot.title <- toString(paste("Planification communale",GemeindeName))
  
  image=df.planungspraxis.scaled.plot.long %>% ggplot(aes(x=categorie, y=bewertung)) + scale_y_continuous(labels=scales::percent) + coord_flip() + geom_point(color= gehsund_cols("dark grey"), size = 3)+ggtitle(planungspraxis.scaled.plot.title)+theme(axis.title.x = element_blank(), axis.title.y = element_blank(), text = element_text(family = "Calibri", size=20)) +geom_point(data = df.planungspraxis.scaled.plot.long.single, color = gehsund_cols("pink"), size = 6)+geom_point(data = mean.planungspraxis, mapping=aes(x=as.numeric(categorie)+0.05, y=bewertung), color = "black", size =10, shape ="|")+theme(legend.position="none")

  ggsave(file=file.name, plot=image, width=10, height=5)
  
  
  
  setwd("..")
  
  #Strahldiagramm mit Mittelwert Infrastruktur wird in Unterordner strahl_infrastruktur_f abgelegt.
  
  
  setwd("strahl_infrastruktur_f")
  file.name <- gsub(" ", "", paste(row.names(df.planungspraxis.scaled)[i],".svg"))
  
  df.infrastruktur.scaled.plot.long.single <- df.infrastruktur.scaled.plot.long %>%filter(GemeindeNamen == GemeindeName)
  
  infrastruktur.scaled.plot.title <- toString(paste("Analyse de terrain",GemeindeName))
  
  image=df.infrastruktur.scaled.plot.long %>% ggplot(aes(x=categorie, y=bewertung)) + scale_y_continuous(labels=scales::percent) + coord_flip() + geom_point(color= gehsund_cols("dark grey"), size = 3, outlier.shape = NA)+ggtitle(infrastruktur.scaled.plot.title)+theme(axis.title.x = element_blank(), axis.title.y = element_blank(), text = element_text(family = "Calibri", size=20)) +geom_point(data = df.infrastruktur.scaled.plot.long.single, color = gehsund_cols("green"), size = 6)+geom_point(data = mean.infrastruktur, mapping=aes(x=as.numeric(categorie)+0.05, y=bewertung), color = "black", size =10, shape ="|")+theme(legend.position="none")

  ggsave(file=file.name, plot=image, width=10, height=5)
  
  
  
  setwd("..")
  
  #Strahldiagramm mit Mittelwert Befragung wird in Unterordner strahl_befragung_f abgelegt.
  
  
  setwd("strahl_befragung_f")
  file.name <- gsub(" ", "", paste(row.names(df.planungspraxis.scaled)[i],".svg"))
  
  df.befragung.scaled.plot.long.single <- df.befragung.scaled.plot.long %>%filter(GemeindeNamen == GemeindeName)
  
  befragung.scaled.plot.title <- toString(paste("Sondage marchabilité",GemeindeName))
  
  image=df.befragung.scaled.plot.long %>% ggplot(aes(x=categorie, y=bewertung)) + scale_y_continuous(labels=scales::percent) + coord_flip() + geom_point(color= gehsund_cols("dark grey"), size = 3, outlier.shape = NA)+ggtitle(befragung.scaled.plot.title)+theme(axis.title.x = element_blank(), axis.title.y = element_blank(), text = element_text(family = "Calibri", size=20)) +geom_point(data = df.befragung.scaled.plot.long.single, color = gehsund_cols("blue"), size = 6)+geom_point(data = mean.befragung, mapping=aes(x=as.numeric(categorie)+0.05, y=bewertung), color = "black", size =10, shape ="|")+theme(legend.position="none")

  ggsave(file=file.name, plot=image, width=10, height=5)
  
  
  
  setwd("..")
  
}
