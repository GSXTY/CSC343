-- Devoted Fans
 
-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q6 cascade;

CREATE TABLE q6 (
    patronID Char(20) NOT NULL,
    devotedness INT NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
--DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here:
--CREATE VIEW intermediate_step AS ... ;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q6

WITH AuthorBookCount AS (
    SELECT hc.contributor, COUNT(*) AS book_count
    FROM library.holdingcontributor hc
    JOIN library.holding h ON h.id = hc.holding
    WHERE h.htype = 'books'
    GROUP BY hc.contributor
    HAVING COUNT(*) >= 2
),
PatronCheckout AS (
    SELECT c.patron, hc.contributor, COUNT(c.copy) as checkout_time
    FROM library.checkout c
    JOIN library.libraryholding lh ON lh.barcode = c.copy
    JOIN library.holdingcontributor hc ON hc.holding = lh.holding
    JOIN library.holding h ON h.id = lh.holding
    WHERE h.htype = 'books'
    GROUP BY c.patron, hc.contributor
),
PatronReview AS (
    SELECT r.patron, hc.contributor, AVG(r.stars) as avg_rating
    FROM library.review r
    JOIN library.holdingcontributor hc ON hc.holding = r.holding
    GROUP BY r.patron, hc.contributor
    HAVING AVG(r.stars) >= 4.0
),
EligibleAuthors AS (
    SELECT pc.patron, pc.contributor
    FROM PatronCheckout pc
    JOIN AuthorBookCount abc ON pc.contributor = abc.contributor
    WHERE pc.checkout_time >= abc.book_count - 1
    GROUP BY pc.patron, pc.contributor, abc.book_count
    
),
DevotedFans AS (
    SELECT ea.patron, COUNT(ea.contributor) as devotedness
    FROM EligibleAuthors ea
    JOIN PatronReview pr ON ea.patron = pr.patron AND ea.contributor = pr.contributor
    WHERE pr.avg_rating >= 4.0
    GROUP BY ea.patron
)
SELECT p.card_number AS patronID, COALESCE(df.devotedness, 0) AS devotedness
FROM library.patron p
LEFT JOIN DevotedFans df ON p.card_number = df.patron
GROUP BY p.card_number, df.devotedness;

