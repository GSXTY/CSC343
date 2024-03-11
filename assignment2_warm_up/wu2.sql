-- Warmup Query 2

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO LibraryWarmup;
DROP TABLE IF EXISTS wu2 cascade;

CREATE TABLE wu2 (
    card_number CHAR(20),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    average FLOAT NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
--DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here:
--CREATE VIEW intermediate_step AS ... ;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO wu2

SELECT card_number, first_name, last_name, AVG(review.stars) as average
FROM review 
INNER JOIN patron ON review.patron = patron.card_number
GROUP BY patron.card_number, patron.first_name, patron.last_name
HAVING COUNT(review.stars) > 1 AND MAX(review.stars) = 5;

