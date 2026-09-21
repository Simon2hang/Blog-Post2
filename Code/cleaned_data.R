# clean_data.R
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

# --------------------------------------------------
# 2. Read raw data
# --------------------------------------------------

per_game <- read_csv(
  per_game_file,
  show_col_types = FALSE
)

advanced <- read_csv(
  advanced_file,
  show_col_types = FALSE
)

# --------------------------------------------------
# 3. Clean column names
# --------------------------------------------------

per_game <- per_game |>
  clean_names()

advanced <- advanced |>
  clean_names()

# --------------------------------------------------
# 4. Remove non-player / invalid rows
# --------------------------------------------------
# Remove blank rows, repeated header rows, and the "League Average" summary row.

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

# --------------------------------------------------
# 5. Convert relevant columns to numeric
# --------------------------------------------------

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

# --------------------------------------------------
# 6. Keep variables needed for the analysis
# --------------------------------------------------

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

# --------------------------------------------------
# 7. Handle traded players
# --------------------------------------------------
# Traded players may have one row for each team plus a combined
# season row such as 2TM or 3TM.
#
# If a combined row exists, keep that row.
# Otherwise, keep the player's single row.
#
# coalesce() converts missing team values to an empty string so
# str_detect() does not return NA.

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

# --------------------------------------------------
# 8. Rename variables before merging
# --------------------------------------------------

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

# --------------------------------------------------
# 9. Merge per-game and advanced datasets
# --------------------------------------------------

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

# --------------------------------------------------
# 10. Keep regular contributors
# --------------------------------------------------

nba_clean <- nba_clean |>
  filter(games >= 50)

# --------------------------------------------------
# 11. Quality checks
# --------------------------------------------------

duplicate_players <- nba_clean |>
  count(player) |>
  filter(n > 1)

if (nrow(duplicate_players) > 0) {
  warning("Duplicate players remain after cleaning.")
}

missing_key_stats <- nba_clean |>
  summarise(
    missing_per = sum(is.na(per)),
    missing_ts = sum(is.na(ts_percent)),
    missing_ws = sum(is.na(ws)),
    missing_bpm = sum(is.na(bpm)),
    missing_vorp = sum(is.na(vorp))
  )

print(missing_key_stats)

# --------------------------------------------------
# 12. Save processed data
# --------------------------------------------------

processed_file <- file.path(
  processed_data_dir,
  "nba_2025_26_clean.csv"
)

write_csv(
  nba_clean,
  processed_file
)