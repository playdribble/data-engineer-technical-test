# Midnite Senior Data Engineer Technical Take Home

> **Please do not post your solution to this challenge publicly on GitHub or any other public platform.**

## Challenge Goal

This technical challenge is designed to allow you to showcase your Python, SQL and general data engineering skills.

We would like you to showcase your knowledge of engineering best practices that you feel are relevant.
These could include:

- Writing high quality code (e.g. following DRY and SOLID principles etc)
- Writing appropriate unit tests (we love testing here at Midnite!!!)
- Handling common errors
- Considering edge cases
- Securely handling secrets
- Data quality testing / monitoring
- etc

We expect this challenge to take approximately 3-4 hours - but that's not a hard limit.
We value design thinking and knowing what to prioritise over completeness - a well-reasoned partial solution beats a rushed one, provided you fully document any shortcomings or missing production grade considerations in the `NOTES.md` file

If you don't have time to implement everything, that's fine. Feel free to explain what you would consider or do differently to make this a full production quality setup if you had more time in the `NOTES.md` file.
These will make great talking points during the final interview.

## Setup

**NOTE: The below instructions have only been tested on MacOS.**

1. Run `make build; make up` to start the docker containers
2. Run `make shell` and then run `pytest` to confirm the Python environment is set up as expected
3. Run `make show-tables` to inspect the tables in the postgres instance.
4. Use the following to connect to a DB editor:
```
+----------+-----------+
| Setting  | Value     |
+----------+-----------+
| HOST     | localhost |
| PORT     | 5432      |
| USER     | postgres  |
| PASSWORD | postgres  |
| DATABASE | analytics |
+----------+-----------+
```

Note: If you want to reset the database, including re-loading the dummy data in the `raw` schema, then run `make reset-db`.

Feel free to adapt the `Makefile`, `Dockerfile` or any part of the code as you see fit.

## Background Information & Context

- You are working as part of the data team at Better Betting Ltd.
- Better Betting provides online betting and gambling services.... Just like Midnite.
- Better Betting currently operates in Ireland and in the UK. The company does not have a license to operate in any other country at this stage, so we should not have any users from other countries.
- All the raw data tables are described in the `Raw Data Sources` section at the end of this file.
- There can be a delay from when a bet is placed to when it is settled. For example, a user places a bet on football on 2024-01-01, but the game doesn't finish until 2024-01-02. The bet is settled on 2024-01-02.

## Requirements

### Data Ingestion

Using the attached example `src/landed_files/bets.csv` file, write a Python CLI script (`ingest.py`) that:
1. Accepts a file path as a command-line argument. Run it from inside the container shell (`make shell`), where the repo's `src/` directory is mounted as the working directory `/opt/src`, so paths are relative to `src/` — e.g. `python ingest.py --file landed_files/bets.csv`
2. Reads the file and inserts the data into the `raw.bet` table in the database
3. Is idempotent — re-running the script with the same file should not insert duplicate rows
4. Validates the incoming data and enforces the relevant business rules as part of ingestion, rather than pushing that responsibility downstream. Using the background information above and the details in `Raw Data Sources`, consider validations such as:
   - `winnings` cannot be `< 0`
   - referential and domain integrity — e.g. `user_id`, `game_id` and (when set) `bet_outcome_id` should resolve against the pre-loaded `raw` tables, and users/currencies should be within the markets we operate in (IE / GB, `EUR` / `GBP`)
   - settlement consistency — `bet_outcome_id` and `settled_at` are `NULL` until a bet has settled, and `settled_at` should not be earlier than `created_at`

   It is up to you how to handle rows that fail validation (e.g. reject, quarantine, fail the run, log). Document the approach you chose and why in `NOTES.md`.

Feel free to use any libraries or packages you feel are necessary to complete this task, but be ready to justify your choices. Add any Python packages you need to `requirements.txt` and re-run `make build` to rebuild the image with them installed.

**Connecting to the database from `ingest.py`:** when running inside the container (`make shell`), connect to Postgres using host `postgres` (the compose service name), port `5432`, database `analytics`. These values are provided to the container as the `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER` and `POSTGRES_PASSWORD` environment variables, so you don't need to hardcode them. (The `localhost` connection settings in the `Setup` section above are for connecting an external DB editor from your host machine.)

As mentioned in the `Challenge Goal` section above, treat this as a mini-production setup and showcase relevant engineering best practices.

### Simulating a Data Update

`src/landed_files/updated_bets.csv` simulates a subsequent batch of landed data that arrives
**after** the initial `bets.csv` load. Ingest it after `bets.csv` (from inside `make shell`):

```
python ingest.py --file landed_files/bets.csv
python ingest.py --file landed_files/updated_bets.csv
```

It is designed to exercise how your pipeline handles change over time — your ingestion should be
idempotent and update-aware, not insert-only. The file contains:

- **Settlements** of bets that were previously open in `bets.csv` (same `id`, now with
  `bet_outcome_id`, `winnings` and `settled_at` populated).
- **Corrections** to bets that were already settled (e.g. a changed `winnings` value or `outcome`).
- **New bets** with `id`s not present in `bets.csv`.
- **Rows identical** to `bets.csv` — re-running must not create duplicates.
- A few rows that **violate the business rules**, so validation is exercised on the update run too.

Re-running this file should be safe: existing bets are updated in place, new bets are inserted, and no
duplicate `id`s are created.

## Raw Source Data

All the data for this challenge is automatically loaded when you build and start the postgres docker container. The data is stored in the schema called `raw`.

The `raw` schema contains 6 tables: `users`, `user_address`, `bet`, `bet_outcome`, `game`, and `fx_rates`. 

### Tables

#### Users

| Column       | Data Type | Notes                                                             |
| ------------ | --------- | ----------------------------------------------------------------- |
| id           | int       | The unique ID of the user                                         |
| Name         | varchar   | The first name of the user                                        |
| IsTestUser   | boolean   | Set to true if the user is an internal / development test account |
| CurrencyCode | varchar   | 3-character currency code of either `EUR` or `GBP`                |
| CreatedAt    | timestamp | The datetime when the user registered / created their account     |

#### User Address

| Column       | Data Type | Notes                                                      |
| ------------ | --------- | ---------------------------------------------------------- |
| user_id      | int       | The unique ID of the user                                  |
| address      | varchar   | The street address of where the user lives                 |
| country_code | varchar   | The ISO 3166 country code of the user. Either `IE` or `GB` |

#### Bet Outcome

| Column  | Data Type | Notes                                                                |
| ------- | --------- | -------------------------------------------------------------------- |
| id      | int       | The unique ID of the bet outcome type                                |
| outcome | varchar   | The name of the bet outcome type. Either `winner`, `loser` or `draw` |

#### Game

| Column     | Data Type | Notes                                                                              |
| ---------- | --------- | ---------------------------------------------------------------------------------- |
| id         | int       | The unique ID of the game which can be bet on                                      |
| name       | varchar   | The display name of the game (e.g. `Golf`, `Tennis`, `Rugby League`)               |
| vertical   | varchar   | The product vertical the game belongs to of either `sports`, `esports` or `casino` |
| created_at | timestamp | The date the game was created in the database                                      |

#### Bet

| Column         | Data Type | Notes                                                                                  |
| -------------- | --------- | -------------------------------------------------------------------------------------- |
| id             | int       | The unique ID of the bet                                                               |
| user_id        | int       | ID of the user who placed the bet                                                      |
| bet_outcome_id | int       | The bet outcome ID. `NULL` until the game has finished (i.e. the bet has settled)      |
| game_id        | int       | The ID of the game which the user placed a bet on                                      |
| wager          | decimal   | The amount wagered by the user on the bet (e.g. the user placed a £10 bet).            |
| is_cash_wager  | boolean   | True if the bet is an all cash wager. If false, then the bet was made with free credit |
| winnings       | decimal   | The amount of cash paid to the user when the bet has been settled. Cannot be < 0.      |
| created_at     | timestamp | The date the bet was placed                                                            |
| settled_at     | timestamp | The date when the bet settles (i.e. the bet is won, lost or draw)                      |

_NOTE: All financial attributes (i.e. `wager` and `winnings`) are recorded in the users' account currency (e.g. GBP, EUR) depending on the currency_code in the user table_

#### FX Rates

| Column        | Data Type | Notes                                                                           |
| ------------- | --------- | ------------------------------------------------------------------------------- |
| date          | date      | The exchange rate date                                                          |
| currency_code | varchar   | 3-character currency code of either `EUR` or `GBP`                              |
| rate          | decimal   | The FX rate to convert the financial attributes from the user's currency to USD |
