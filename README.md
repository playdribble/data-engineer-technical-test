# Midnite Data Engineer Technical Take Home

> **Please do not post your solution to this challenge publicly on GitHub or any other public platform.**

## Challenge Goal

This technical challenge is designed to allow you to showcase your Python and engineering skills and best practices.

We are not expecting full production grade code, but we do want you to showcase your knowledge of what production grade
code should look like. This could include:

- Writing high quality code (e.g. following DRY and SOLID principles etc)
- Handling common errors
- Considering edge cases
- Security considerations
- etc

We expect this challenge to take approximately 3-4 hours - but that's not a hard limit.
We value design thinking and knowing what to prioritise over completeness - a well-reasoned partial solution beats a rushed one, provided you fully document any shortcomings or missing production grade considerations in the `NOTES.md` file.

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

## Requirements

### Initial Data Ingestion

Using the files in `src/landed_files/`, create a Python based solution that:
1. Accepts a file path as a command-line argument (e.g. `python ingest.py --file src/landed_files/bets.csv`)
2. Reads the file and loads the data into the `raw.bet` table
3. Is idempotent — re-running the script with the same file should not insert duplicate rows
4. Validates the incoming data and enforces the relevant business rules as part of ingestion, rather than pushing that responsibility downstream. See the `Bets` details below for more details.
5. Assume that the data volume will significantly grow in coming months 

Feel free to use any libraries or packages you feel are necessary to complete this task, but be ready to justify your choices.

Remember that we want to showcase your knowledge of production grade code and engineering best practices.
This doesn't mean 100% production ready, but you should showcase or at a minimum document what other production grade considerations you would make.


### Simulating a Data Update

`src/landed_files/updated_bets.csv` simulates a subsequent batch of landed data that arrives
**after** the initial `bets.csv` load. Ingest it after `bets.csv`.


## Bets

The below summarises the Postgres table columns, data types and business rules / notes for the `raw.bet` table, which will help you with the above requirements. 

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

