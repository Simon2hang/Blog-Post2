# scrape_nba.R
# Blog Post 2 — NBA Player Impact Analysis

library(rvest)
library(readr)

per_game_url <- "https://www.basketball-reference.com/leagues/NBA_2026_per_game.html"
advanced_url <- "https://www.basketball-reference.com/leagues/NBA_2026_advanced.html"


raw_data_dir <- file.path(
   "Data", "raw_data"
)

dir.create(
  raw_data_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

# ---------------------------------------

extract_table_by_columns <- function(page, required_columns) {
  
  tables <- page |>
    html_elements("table") |>
    html_table(fill = TRUE)
  
  matches <- vapply(
    tables,
    function(tbl) all(required_columns %in% names(tbl)),
    logical(1)
  )
  
  if (!any(matches)) {
    stop(
      "Could not find a table containing these columns: ",
      paste(required_columns, collapse = ", ")
    )
  }
  
  tables[[which(matches)[1]]]
}

# ---------------------------------------

message("Scraping 2025–26 NBA per-game statistics...")

per_game_page <- read_html(per_game_url)

per_game_raw <- extract_table_by_columns(
  per_game_page,
  required_columns = c(
    "Player", "Team", "G", "MP", "PTS", "TRB", "AST"
  )
)

message(
  "Per-game table collected: ",
  nrow(per_game_raw), " rows × ",
  ncol(per_game_raw), " columns."
)

Sys.sleep(3)

# ---------------------------------------

message("Scraping 2025–26 NBA advanced statistics...")

advanced_page <- read_html(advanced_url)

advanced_raw <- extract_table_by_columns(
  advanced_page,
  required_columns = c(
    "Player", "Team", "G", "PER", "TS%", "BPM", "VORP"
  )
)

message(
  "Advanced table collected: ",
  nrow(advanced_raw), " rows × ",
  ncol(advanced_raw), " columns."
)


# ---------------------------------------
per_game_file <- file.path(
  raw_data_dir,
  "nba_2025_26_per_game_raw.csv"
)

advanced_file <- file.path(
  raw_data_dir,
  "nba_2025_26_advanced_raw.csv"
)

write_csv(per_game_raw, per_game_file)
write_csv(advanced_raw, advanced_file)