# =============================================================================
# 03_models.R
# Estimation des modèles de panel : pooled OLS, effets fixes, effets aléatoires
# Tests : Breusch-Pagan, Hausman
# =============================================================================

library(plm)
library(broom)
library(openxlsx)
library(corrplot)

# -----------------------------------------------------------------------------
# 0. Charger le panel
# -----------------------------------------------------------------------------

load("data/processed/02_panel.RData")

# -----------------------------------------------------------------------------
# 1. Matrice de corrélations
# -----------------------------------------------------------------------------

cor_matrix <- cor(panelModel[, 3:11], use = "pairwise.complete.obs")

png("output/correlation_matrix.png", width = 800, height = 700, res = 120)
corrplot::corrplot(cor_matrix, method = "number")
dev.off()

cat("✓ Matrice de corrélations exportée.\n")

# -----------------------------------------------------------------------------
# 2. Test de Breusch-Pagan (effets individuels vs pooled OLS)
# -----------------------------------------------------------------------------

pool <- plm(shareInfOdd ~ ., data = panelModel, model = "pooling")
bp_test <- plmtest(pool, type = "bp")
cat("\nTest de Breusch-Pagan :\n")
print(bp_test)

# -----------------------------------------------------------------------------
# 3. Test de Hausman (effets fixes vs effets aléatoires)
# -----------------------------------------------------------------------------

formula_modele <- shareInfOdd ~ outputW + GOV_WGI_RQ + advanceEduc_share +
  slf_emp + broad_money + cit + wage_gdppc + electricity + internet

hausman_test <- phtest(
  formula_modele,
  data   = panelModel,
  model  = c("within", "random"),
  effect = "individual",
  method = "chisq"
)
cat("\nTest de Hausman :\n")
print(hausman_test)

# -----------------------------------------------------------------------------
# 4. Modèle à effets fixes (within)
# -----------------------------------------------------------------------------

model_fe <- plm(
  formula_modele,
  data  = panelModel,
  model = "within"
)
cat("\n--- Effets fixes ---\n")
print(summary(model_fe))

# -----------------------------------------------------------------------------
# 5. Modèle à effets aléatoires
# -----------------------------------------------------------------------------

model_re <- plm(
  formula_modele,
  data  = panelModel,
  model = "random"
)
cat("\n--- Effets aléatoires ---\n")
print(summary(model_re))

# -----------------------------------------------------------------------------
# 6. Diagnostics des résidus (effets fixes)
# -----------------------------------------------------------------------------

diag_df <- data.frame(
  fitted_vals = as.numeric(fitted(model_fe)),
  resid_vals  = as.numeric(residuals(model_fe))
)
save(diag_df, file = "data/processed/03_diag.RData")

# -----------------------------------------------------------------------------
# 7. Export des résultats (effets aléatoires) vers Excel
# -----------------------------------------------------------------------------

tidy_re    <- tidy(model_re)
glance_re  <- glance(model_re)

wb <- createWorkbook()
addWorksheet(wb, "Coefficients")
addWorksheet(wb, "Statistiques")
writeData(wb, "Coefficients", tidy_re)
writeData(wb, "Statistiques", glance_re)
saveWorkbook(wb, "output/model_re_results.xlsx", overwrite = TRUE)

cat("✓ Résultats exportés : output/model_re_results.xlsx\n")

# -----------------------------------------------------------------------------
# 8. Sauvegarder les modèles
# -----------------------------------------------------------------------------

save(model_fe, model_re, bp_test, hausman_test,
     file = "data/processed/03_models.RData")

cat("✓ Modèles sauvegardés : data/processed/03_models.RData\n")
