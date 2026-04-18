# =============================================================================
# 04_plots.R
# Visualisations : scatter plots, diagnostics des résidus
# =============================================================================

library(ggplot2)
library(dplyr)

# -----------------------------------------------------------------------------
# 0. Charger les données
# -----------------------------------------------------------------------------

load("data/processed/02_panel.RData")
load("data/processed/03_models.RData")
load("data/processed/03_diag.RData")

# Thème commun à tous les graphiques
theme_research <- theme_minimal() +
  theme(
    panel.grid.major  = element_blank(),
    panel.grid.minor  = element_blank(),
    axis.line         = element_line(color = "black", linewidth = 0.6),
    axis.ticks        = element_line(color = "black"),
    axis.ticks.length = unit(0.2, "cm"),
    axis.text         = element_text(color = "black"),
    axis.title        = element_text(color = "black"),
    legend.position   = "none"
  )

# -----------------------------------------------------------------------------
# 1. Scatter : crédit privé vs informalité (log-odds)
# -----------------------------------------------------------------------------

p1 <- ggplot(panel, aes(x = private_credit, y = shareInfOdd)) +
  geom_point(size = 1.8, color = "steelblue", alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE, color = "blue", linewidth = 0.7) +
  labs(
    x = "Crédit domestique au secteur privé (% du PIB)",
    y = "Informalité (log-odds)"
  ) +
  theme_research

ggsave("output/scatter_credit_informality.png", p1,
       width = 7, height = 5, dpi = 150)

# -----------------------------------------------------------------------------
# 2. Scatter : productivité vs variation de l'informalité (par pays)
# -----------------------------------------------------------------------------

p2 <- ggplot(prod_summary, aes(x = g_prod_AAM, y = chginf, color = africa)) +
  geom_point(size = 1.5, alpha = 0.7) +
  geom_text(
    aes(label = iso3c), size = 1.5, vjust = -0.6,
    check_overlap = TRUE
  ) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.7,
              aes(group = 1), color = "gray40") +
  scale_color_manual(values = c("Africa" = "#E25822", "Other" = "#4472C4")) +
  labs(
    x     = "TCAM de la productivité du travail",
    y     = "Variation annuelle moyenne de l'informalité",
    color = NULL
  ) +
  theme_research +
  theme(legend.position = "right")

ggsave("output/scatter_productivity_informality.png", p2,
       width = 7, height = 5, dpi = 150)

# -----------------------------------------------------------------------------
# 3. Diagnostics des résidus (modèle à effets fixes)
# -----------------------------------------------------------------------------

# 3a. Résidus vs valeurs ajustées
p3a <- ggplot(diag_df, aes(x = fitted_vals, y = resid_vals)) +
  geom_point(alpha = 0.4, color = "#4472C4") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  geom_smooth(method = "loess", color = "orange", se = FALSE, linewidth = 0.7) +
  labs(
    title = "Résidus vs valeurs ajustées",
    x     = "Valeurs ajustées",
    y     = "Résidus"
  ) +
  theme_research

# 3b. Q-Q plot des résidus
p3b <- ggplot(diag_df, aes(sample = resid_vals)) +
  stat_qq(color = "#4472C4", alpha = 0.5) +
  stat_qq_line(color = "red", linetype = "dashed") +
  labs(
    title = "Q-Q plot des résidus",
    x     = "Quantiles théoriques",
    y     = "Quantiles empiriques"
  ) +
  theme_research

ggsave("output/diagnostic_residuals_fitted.png", p3a,
       width = 6, height = 4.5, dpi = 150)
ggsave("output/diagnostic_qq.png", p3b,
       width = 6, height = 4.5, dpi = 150)

cat("✓ Graphiques exportés dans output/\n")
