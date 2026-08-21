CREATE DATABASE analytics;

\c analytics
CREATE SCHEMA raw AUTHORIZATION postgres;

CREATE TABLE raw.bet (
  id INT PRIMARY KEY,
  user_id INT,
  bet_outcome_id INT,
  game_id INT,
  wager DECIMAL(10,4),
  is_cash_wager BOOLEAN,
  winnings DECIMAL(10,4),
  created_at TIMESTAMP,
  settled_at TIMESTAMP
);

