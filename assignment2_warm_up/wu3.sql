-- Warmup Query 3

SET SEARCH_PATH TO LibraryWarmup;

-- You must not change the next 2 lines, the type definition, or the table definition.
DROP TYPE IF EXISTS size_type CASCADE;
DROP TABLE IF EXISTS wu3 CASCADE;

CREATE TYPE LibraryWarmup.size_type AS ENUM (
	'large', 'medium', 'small'
);

CREATE TABLE wu3 (
    ward INT,
    size size_type NOT NULL,
    num_branches int NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
--DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here:
--CREATE VIEW intermediate_step AS ... ;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO wu3

WITH Info AS (
    SELECT lb.ward,
        CASE
            WHEN lb.has_parking = true AND lr.auditorium = true THEN 'large'
            WHEN lb.has_parking = true OR lr.auditorium = true THEN 'medium'
            ELSE 'small'
        END AS ward_size
    FROM librarybranch lb
    LEFT JOIN (
        SELECT library, BOOL_OR(rtype = 'auditorium') AS auditorium
        FROM libraryroom
        GROUP BY library
    ) lr ON lb.code = lr.library
)
SELECT ward, ward_size::LibraryWarmup.size_type, COUNT(*)
FROM Info
GROUP BY ward, ward_size
ORDER BY ward, ward_size;


