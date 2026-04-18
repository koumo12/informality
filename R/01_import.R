# =============================================================================
# 01_import.R
# Téléchargement et import de toutes les sources de données
# Sources : WDI (Banque mondiale), WGI, ILO, Tax Foundation
# =============================================================================

library(WDI)
library(Rilostat)
library(readxl)
library(dplyr)
library(tidyr)

# -----------------------------------------------------------------------------
# 1. WDI — World Development Indicators (Banque mondiale)
# -----------------------------------------------------------------------------

wdi_indicators <- c(
  slf_emp        = "SL.EMP.SELF.ZS",
  private_credit = "FS.AST.PRVT.GD.ZS",
  electricity    = "EG.ELC.ACCS.ZS",
  internet       = "IT.NET.USER.ZS",
  water_access   = "SH.H2O.BASW.ZS",
  stock_market   = "CM.MKT.LCAP.GD.ZS",
  broad_money    = "FM.LBL.BMNY.GD.ZS",
  gdppc_lcu      = "NY.GDP.PCAP.CN",
  gdp_lcu        = "NY.GDP.MKTP.CN",
  employment     = "SL.EMP.TOTL.SP.ZS",
  population     = "SP.POP.TOTL"
)

wdi_data <- WDI(
  country   = "all",
  indicator = wdi_indicators,
  start     = 2000,
  end       = 2023
) %>%
  select(iso3c, year, all_of(names(wdi_indicators))) %>%
  arrange(iso3c, year) %>%
  mutate(
    employed_total = population * employment / 100,
    outputW_lcu    = gdp_lcu / employed_total
  )

# -----------------------------------------------------------------------------
# 2. WGI — Worldwide Governance Indicators (fichier local)
# -----------------------------------------------------------------------------
# Fichier attendu : data/raw/wgi.xlsx  (feuille "Est")

wgi <- read_excel("data/raw/wgi.xlsx", sheet = "Est") %>%
  pivot_longer(
    cols      = -c(iso3c, INDICATOR),
    names_to  = "year",
    values_to = "value"
  ) %>%
  mutate(year = as.numeric(year)) %>%
  filter(!is.na(value), year >= 2000) %>%
  pivot_wider(
    names_from  = INDICATOR,
    values_from = value
  )

# -----------------------------------------------------------------------------
# 3. ILO — Informalité, productivité, éducation, salaire minimum, part salariale
# -----------------------------------------------------------------------------

# 3a. Informalité (variable dépendante principale)
informality <- get_ilostat(id = "SDG_0831_SEX_ECO_RT_A", time_format = "num") %>%
  filter(
    sex      == "SEX_T",
    classif1 == "ECO_AGGREGATE_TOTAL"
  ) %>%
  select(iso3c = ref_area, year = time, informality = obs_value) %>%
  group_by(iso3c, year) %>%
  summarise(informality = median(informality, na.rm = TRUE), .groups = "drop")

# 3b. Croissance de la productivité du travail
g_outputW <- get_ilostat(id = "SDG_0821_NOC_RT_A", time_format = "num") %>%
  select(iso3c = ref_area, year = time, g_outputW = obs_value)

# 3c. Productivité du travail (niveau)
productivity <- get_ilostat(id = "GDP_205U_NOC_NB_A", time_format = "num") %>%
  select(iso3c = ref_area, year = time, outputW = obs_value)

# 3d. Éducation de la population active
educationLF_clean <- get_ilostat(
  id = "EAP_TEAP_SEX_EDU_NB_A", time_format = "num"
) %>%
  filter(
    sex      == "SEX_T",
    classif1 %in% c("EDU_AGGREGATE_ADV", "EDU_AGGREGATE_TOTAL")
  ) %>%
  select(iso3c = ref_area, year = time, classif1, value = obs_value) %>%
  pivot_wider(names_from = classif1, values_from = value) %>%
  mutate(advanceEduc_share = EDU_AGGREGATE_ADV / EDU_AGGREGATE_TOTAL * 100) %>%
  select(iso3c, year, advanceEduc_share)

# 3e. Salaire minimum annuel
min_wage <- get_ilostat(
  id = "EAR_INEE_NOC_NB_A", time_format = "num"
) %>%
  select(iso3c = ref_area, year = time, min_wage = obs_value) %>%
  mutate(min_wage = min_wage * 12)

# 3f. Part salariale dans le PIB
labor_share_ilo <- get_ilostat(
  id = "LAP_2GDP_NOC_RT_A", time_format = "num"
) %>%
  select(iso3c = ref_area, year = time, labor_share = obs_value)

# -----------------------------------------------------------------------------
# 4. CIT — Taux d'imposition des sociétés (Tax Foundation)
# -----------------------------------------------------------------------------
# Fichier attendu : data/raw/cit.xlsx

cit <- read_excel("data/raw/cit.xlsx", col_names = TRUE) %>%
  pivot_longer(
    cols      = -iso3c,
    names_to  = "year",
    values_to = "cit"
  ) %>%
  mutate(
    year = as.numeric(year),
    cit  = as.numeric(na_if(cit, "NA"))
  )

# -----------------------------------------------------------------------------
# 5. Sauvegarder les objets pour la prochaine étape
# -----------------------------------------------------------------------------

save(
  wdi_data, wgi, informality, g_outputW, productivity,
  educationLF_clean, min_wage, labor_share_ilo, cit,
  file = "data/processed/01_imported.RData"
)

cat("✓ Import terminé. Fichier sauvegardé : data/processed/01_imported.RData\n")
