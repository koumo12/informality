# =============================================================================
# 02_clean_merge.R
# Fusion de toutes les sources → construction du panel économétrique
# =============================================================================

library(dplyr)
library(purrr)
library(plm)
library(openxlsx)

# -----------------------------------------------------------------------------
# 0. Charger les données importées
# -----------------------------------------------------------------------------

load("data/processed/01_imported.RData")

# -----------------------------------------------------------------------------
# 1. Fusionner WDI + WGI
# -----------------------------------------------------------------------------

wdi_dataf <- wdi_data %>%
  inner_join(wgi, by = c("iso3c", "year"))

# -----------------------------------------------------------------------------
# 2. Fusionner toutes les sources → panel complet
# -----------------------------------------------------------------------------

panel <- reduce(
  list(
    wdi_dataf,
    informality,
    productivity,
    educationLF_clean,
    cit,
    labor_share_ilo,
    min_wage
  ),
  left_join,
  by = c("iso3c", "year")
) %>%
  mutate(
    year         = as.numeric(year),
    outputW      = log(outputW),                          # log productivité
    shareInfOdd  = log(informality / (100 - informality)),# log-odds informalité
    wage_outputpw = min_wage / outputW_lcu * 100,
    wage_gdppc    = min_wage / gdppc_lcu   * 100
  )

# -----------------------------------------------------------------------------
# 3. Sélectionner les variables du modèle et nettoyer
# -----------------------------------------------------------------------------

model_vars <- c(
  "iso3c", "year", "shareInfOdd", "outputW",
  "GOV_WGI_RQ", "advanceEduc_share", "slf_emp",
  "broad_money", "cit", "wage_gdppc",
  "electricity", "internet"
)

panelModel <- panel[, model_vars] %>%
  arrange(iso3c, year) %>%
  drop_na() %>%
  group_by(iso3c) %>%
  mutate(T = n()) %>%
  filter(T >= 4, year >= 2000) %>%
  select(-T) %>%
  ungroup()

# Convertir en objet panel (plm)
panelModel <- pdata.frame(panelModel, index = c("iso3c", "year"))

cat("Dimensions du panel :\n")
print(pdim(panelModel))

# -----------------------------------------------------------------------------
# 4. Données auxiliaires pour les graphiques (ILO)
# -----------------------------------------------------------------------------

africa <- readxl::read_excel("data/raw/Africa.xlsx", col_names = TRUE)
africa_codes <- africa$Code

ilo_data <- informality %>%
  inner_join(productivity, by = c("iso3c", "year")) %>%
  inner_join(g_outputW,   by = c("iso3c", "year")) %>%
  mutate(africa = ifelse(iso3c %in% africa_codes, "Africa", "Other"))

# Résumé par pays (TCAM productivité, variation informalité)
prod_summary <- ilo_data %>%
  arrange(iso3c, year) %>%
  group_by(iso3c) %>%
  mutate(
    T        = n(),
    n_years  = last(year) - first(year),
    g_prod_AAM = (last(outputW) / first(outputW))^(1 / (n_years - 1)) - 1,
    chginf     = (last(informality) / 100 - first(informality) / 100) / n_years,
    Final_Inf   = last(informality),
    Initial_Inf = first(informality),
    Final_Year   = last(year),
    Initial_Year = first(year)
  ) %>%
  filter(T >= 2) %>%
  summarise(
    Initial_Inf  = first(Initial_Inf),
    Final_Inf    = first(Final_Inf),
    Initial_Year = first(Initial_Year),
    Final_Year   = first(Final_Year),
    chginf       = first(chginf),
    g_prod_AAM   = first(g_prod_AAM),
    africa       = first(africa),
    .groups = "drop"
  )

# -----------------------------------------------------------------------------
# 5. Sauvegarder
# -----------------------------------------------------------------------------

save(
  panel, panelModel, ilo_data, prod_summary, africa_codes,
  file = "data/processed/02_panel.RData"
)

cat("✓ Panel construit. Fichier sauvegardé : data/processed/02_panel.RData\n")
