-- Lure Them Back

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q5 cascade;

CREATE TABLE q5 (
    patronID CHAR(20) NOT NULL,
    email TEXT NOT NULL,
    usage INT NOT NULL,
    decline INT NOT NULL,
    missed INT NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
--DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here:
--CREATE VIEW intermediate_step AS ... ;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5


WITH ActiveMonths2022 AS (
    SELECT patron, COUNT(DISTINCT EXTRACT(MONTH FROM checkout_time)) AS active_months_2022
    FROM library.checkout
    WHERE EXTRACT(YEAR FROM checkout_time) = 2022
    GROUP BY patron
),
ActiveMonths2023 AS (
    SELECT patron, COUNT(DISTINCT EXTRACT(MONTH FROM checkout_time)) AS active_months_2023,
           12 - COUNT(DISTINCT EXTRACT(MONTH FROM checkout_time)) AS inactive_months_2023
    FROM library.checkout
    WHERE EXTRACT(YEAR FROM checkout_time) = 2023
    GROUP BY patron
),
Checkouts2022 AS (
    SELECT patron, COUNT(copy) AS checkouts_2022
    FROM library.checkout
    WHERE EXTRACT(YEAR FROM checkout_time) = 2022
    GROUP BY patron
),
Checkouts2023 AS (
    SELECT patron, COUNT(copy) AS checkouts_2023
    FROM library.checkout
    WHERE EXTRACT(YEAR FROM checkout_time) = 2023
    GROUP BY patron
),
Checkouts2024 AS (
    SELECT patron
    FROM library.checkout
    WHERE EXTRACT(YEAR FROM checkout_time) = 2024
    GROUP BY patron
),
NoCheckouts2024 AS (
    SELECT patron
    FROM library.checkout
    EXCEPT
    SELECT patron
    FROM Checkouts2024
),
EligiblePatrons AS (
    SELECT p.card_number, p.email,
           COALESCE(c2022.checkouts_2022, 0) - COALESCE(c2023.checkouts_2023, 0) AS decline,
           COALESCE(a2023.inactive_months_2023, 0) AS missed
    FROM library.patron p
    JOIN ActiveMonths2022 a2022 ON p.card_number = a2022.patron
    JOIN ActiveMonths2023 a2023 ON p.card_number = a2023.patron
    JOIN NoCheckouts2024 n2024 ON p.card_number = n2024.patron
    LEFT JOIN Checkouts2022 c2022 ON p.card_number = c2022.patron
    LEFT JOIN Checkouts2023 c2023 ON p.card_number = c2023.patron
    WHERE a2022.active_months_2022 = 12 AND a2023.active_months_2023 >= 5 AND a2023.inactive_months_2023 > 0
)
SELECT card_number AS patronID,
       COALESCE(email, 'none') AS email,
       (SELECT COUNT(DISTINCT copy) FROM library.checkout co WHERE co.patron = EligiblePatrons.card_number) AS usage,
       decline,
       missed
FROM EligiblePatrons;

