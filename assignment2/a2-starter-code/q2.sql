-- Overdue Items

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q2 cascade;

create table q2 (
    branch CHAR(5) NOT NULL,
    patron CHAR(20),
    title TEXT NOT NULL,
    overdue INT NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
--DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here:
--CREATE VIEW intermediate_step AS ... ;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2

SELECT 
    lh.library AS branch,
    co.patron,
    h.title,
    CASE 
        WHEN h.htype IN ('books', 'audiobooks') THEN EXTRACT(DAY FROM CURRENT_DATE - (co.checkout_time + INTERVAL '21 days'))
        WHEN h.htype IN ('movies', 'music', 'magazines and newspapers') THEN EXTRACT(DAY FROM CURRENT_DATE - (co.checkout_time + INTERVAL '7 days'))
    END AS overdue
FROM 
    library.checkout co
JOIN library.libraryholding lh ON co.copy = lh.barcode
JOIN library.holding h ON lh.holding = h.id
LEFT JOIN library.return r ON co.id = r.checkout
WHERE 
    co.checkout_time + CASE 
        WHEN h.htype IN ('books', 'audiobooks') THEN interval '21 days'
        WHEN h.htype IN ('movies', 'music', 'magazines and newspapers') THEN interval '7 days'
    END < CURRENT_DATE
    AND r.return_time IS NULL
    AND lh.library IN (SELECT code
                       FROM library.librarybranch JOIN library.ward ON librarybranch.ward = library.ward.id
                       WHERE library.ward.name = 'Parkdale-High Park');

