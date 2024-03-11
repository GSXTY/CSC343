-- Warmup Query 1

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO LibraryWarmup;
DROP TABLE IF EXISTS wu1 CASCADE;

CREATE TABLE wu1 (
    patron CHAR(20) NOT NULL,
    checkouts int NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
--DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here:
--CREATE VIEW intermediate_step AS ... ;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO wu1

SELECT checkout.patron, COUNT(checkout.id) AS checkouts
FROM checkout
LEFT JOIN return ON checkout.id = return.checkout
WHERE return.checkout IS NULL
GROUP BY checkout.patron
HAVING COUNT(checkout.id) >= 3;
