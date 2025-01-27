data <- read.csv("metaboData/Datasets/2024-Cachexia/human_cachexia.csv", 
                 row.names = 1) # La primera columna contiene los identificadores


metadata <- as.data.frame(data$Muscle.loss) # Metadatos, la primera columna contiene inrformación sobre la pérdida muscular
expressiondata <- t(as.matrix(data[,-1])) # Convertimos los datos de expresión en matriz
rownames(metadata) <- rownames(data)
colnames(metadata) <- 'Muscle.loss'
colnames(expressiondata) <- rownames(data)



library(SummarizedExperiment)
se <- SummarizedExperiment(
  assays = SimpleList(counts = expressiondata),
  colData = metadata
)


# Información general
se

# Dimensiones
dim(se)

# Identificadores de muestras y características
dimnames(se)

# Metadatos
colData(se)
metadata(se)

# Datos de expresión
data_analysis <- assay(se, "counts")
head(data_analysis)

# Kolgomorov-Smirnov
normal_result <- list()

for (col in names(data)[-1]) {
  # Grupos
  control <- data[data$Muscle.loss == 'control', col]
  dis <- data[data$Muscle.loss == 'cachexic', col]
  # Prueba Kolgomorov-Smirnov
  prueba_control <- ks.test(control, "pnorm", mean = mean(control), sd = sd(control))
  prueba_dis <- ks.test(dis, "pnorm", mean = mean(dis), sd = sd(dis))
  
  normal_result[[col]] <- list(control_p = prueba_control$p.value, dis_p = prueba_dis$p.value)
}

normalidad <- names(normal_result)[sapply(normal_result, function(res) res$control_p > 0.05 & res$dis_p > 0.05)]
normalidad

# ANOVA
table(data$Muscle.loss)
ANOVA_result <- list()

# Realizar ANOVA para cada característica
for (col in normalidad) {
  anova_mod <- aov(data[[col]] ~ Muscle.loss, data = data)
  ANOVA_result[[col]] <- summary(anova_mod)
}

# p-valor < 0.05 = Valores sigmificativos, es decir, que difieren entre ambos grupos de datos
significativos <- list()

# Filtrar por p-value < 0.05
for (p in names(ANOVA_result)) {
  # Extraer el valor p del resumen del ANOVA
  p_value <- ANOVA_result[[p]][[1]][["Pr(>F)"]][1]
  
  # Verificar si el p-value es menor a 0.05
  if (!is.na(p_value) && p_value < 0.05) {
    significativos[[p]] <- ANOVA_result[[p]]
  }
}

# Nuevo data set
features_sig <- names(significativos)
new_data <- data[, c("Muscle.loss", features_sig)]


# Tamaño
names(significativos)


# Visualización del ANOVA
library(ggplot2)
library(patchwork)

grafics <- list() # lista para almacenar los graficos
for (col in names(significativos)) {
  # Crear un boxplot para cada característica significativa
  plots <- ggplot(data, aes(x = Muscle.loss, y = .data[[col]], fill = Muscle.loss)) +
    geom_boxplot(alpha = 0.7) +
    labs(title = paste("Boxplot de", col),
         x = "Grupo",
         y = col) +
    scale_fill_manual(values = c("pink", "lightgreen"))
  
  # Mostrar el gráfico
  grafics[[col]] <- plots
}

wrap_plots(grafics, nrow = 4)
