# Blog Post 2: NBA Player Impact Analysis

This project analyzes 2025–26 NBA player performance using data scraped from Basketball-Reference with R.

## Files

- `Code/scrape_nba.R` — scrapes per-game and advanced statistics
- `Code/clean_data.R` — cleans and merges the data
- `Code/analysis_nba.Rmd` — performs the analysis and creates figures
- `Data/` — contains raw and processed data
- `Figures/` — contains figures used in the blog post

## Reproduce

Run the files in this order:

1. `Code/scrape_nba.R`
2. `Code/clean_data.R`
3. `Code/analysis_nba.Rmd`

Required R packages include `rvest`, `readr`, `dplyr`, `janitor`, `stringr`, `ggplot2`, and `ggrepel`.