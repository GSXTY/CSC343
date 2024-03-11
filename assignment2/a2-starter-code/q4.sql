-- Explorers Contest

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q4 cascade;

CREATE TABLE q4 (
    patronID CHAR(20) NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
--DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here:
--CREATE VIEW intermediate_step AS ... ;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4


WITH LibraryEvents AS (
  SELECT DISTINCT e.id AS event_id, lb.ward
  FROM libraryevent e
  INNER JOIN libraryroom lr ON e.room = lr.id
  INNER JOIN librarybranch lb ON lr.library = lb.code
),
PatronEvents AS (
  SELECT es.patron, le.ward
  FROM eventsignup es
  INNER JOIN LibraryEvents le ON es.event = le.event_id
),
Explorers AS (
  SELECT pe.patron AS patronID
  FROM PatronEvents pe
  GROUP BY pe.patron
  HAVING COUNT(DISTINCT pe.ward) = (SELECT COUNT(DISTINCT ward) FROM librarybranch)
)
SELECT patronID
FROM Explorers;