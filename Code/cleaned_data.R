# cleaned_data.R
# Blog Post 2 — NBA Player Impact Analysis

library(dplyr)
library(readr)
library(janitor)
library(stringr)


raw_data_dir <- file.path(
   "Data", "raw_data"
)

processed_data_dir <- file.path(
 "Data", "processed_data"
)

dir.create(
  processed_data_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

per_game_file <- file.path(
  raw_data_dir,
  "nba_2025_26_per_game_raw.csv"
)

advanced_file <- file.path(
  raw_data_dir,
  "nba_2025_26_advanced_raw.csv"
)

# Read raw data

per_game <- read_csv(
  per_game_file,
  show_col_types = FALSE
)

advanced <- read_csv(
  advanced_file,
  show_col_types = FALSE
)

# ---------------------------------------

per_game <- per_game |>
  clean_names()

advanced <- advanced |>
  clean_names()

# ---------------------------------------

per_game <- per_game |>
  filter(
    !is.na(player),
    player != "Player",
    player != "League Average"
  )

advanced <- advanced |>
  filter(
    !is.na(player),
    player != "Player",
    player != "League Average"
  )

# ---------------------------------------

per_game <- per_game |>
  mutate(
    across(
      any_of(c(
        "g", "mp", "pts", "trb", "ast", "stl", "blk"
      )),
      as.numeric
    )
  )

advanced <- advanced |>
  mutate(
    across(
      any_of(c(
        "g", "per", "ts_percent", "ws", "bpm", "vorp"
      )),
      as.numeric
    )
  )

# ---------------------------------------

per_game <- per_game |>
  select(
    player,
    team,
    g,
    mp,
    pts,
    trb,
    ast,
    stl,
    blk
  )

advanced <- advanced |>
  select(
    player,
    team,
    g,
    per,
    ts_percent,
    ws,
    bpm,
    vorp
  )
# ---------------------------------------

keep_combined_or_first <- function(data) {
  
  data |>
    mutate(
      team_for_check = coalesce(team, ""),
      is_combined_team = str_detect(team_for_check, "^[2-9]TM$")
    ) |>
    group_by(player) |>
    filter(
      if (any(is_combined_team, na.rm = TRUE)) {
        is_combined_team
      } else {
        row_number() == 1
      }
    ) |>
    ungroup() |>
    select(-team_for_check, -is_combined_team)
}

per_game <- keep_combined_or_first(per_game)
advanced <- keep_combined_or_first(advanced)

# ---------------------------------------

per_game <- per_game |>
  rename(
    games = g,
    minutes_per_game = mp,
    points_per_game = pts,
    rebounds_per_game = trb,
    assists_per_game = ast,
    steals_per_game = stl,
    blocks_per_game = blk
  )

advanced <- advanced |>
  rename(
    games_advanced = g
  )

# ---------------------------------------

nba_clean <- per_game |>
  left_join(
    advanced |>
      select(
        player,
        games_advanced,
        per,
        ts_percent,
        ws,
        bpm,
        vorp
      ),
    by = "player"
  )

# ---------------------------------------

nba_clean <- nba_clean |>
  filter(games >= 50)


processed_file <- file.path(
  processed_data_dir,
  "nba_2025_26_clean.csv"
)

write_csv(
  nba_clean,
  processed_file
)

nba_clean