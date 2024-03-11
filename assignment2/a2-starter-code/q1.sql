-- Branch Activity

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q1 cascade;

CREATE TABLE q1 (
    branch CHAR(5) NOT NULL,
    year INT NOT NULL,
    events INT NOT NULL,
    sessions FLOAT NOT NULL,
    registration INT NOT NULL,
    holdings INT NOT NULL,
    checkouts INT NOT NULL,
    duration FLOAT NOT NULL
);

CREATE TABLE YearTable (
    year INT PRIMARY KEY
);

INSERT INTO YearTable (year) VALUES (2019);
INSERT INTO YearTable (year) VALUES (2020);
INSERT INTO YearTable (year) VALUES (2021);
INSERT INTO YearTable (year) VALUES (2022);
INSERT INTO YearTable (year) VALUES (2023);
-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
DROP VIEW IF EXISTS branch_code CASCADE;
DROP VIEW IF EXISTS branch_year CASCADE;
DROP VIEW IF EXISTS new_event_schedule CASCADE;
DROP VIEW IF EXISTS new_event_schedule2 CASCADE;
DROP VIEW IF EXISTS event_inter CASCADE;
DROP VIEW IF EXISTS event CASCADE;
DROP VIEW IF EXISTS step_three CASCADE;
DROP VIEW IF EXISTS registration_inter CASCADE;
DROP VIEW IF EXISTS registration_inter2 CASCADE;
DROP VIEW IF EXISTS registration CASCADE;
DROP VIEW IF EXISTS step_five CASCADE;
DROP VIEW IF EXISTS holdings CASCADE;
DROP VIEW IF EXISTS step_six CASCADE;
DROP VIEW IF EXISTS librarycheckout CASCADE;
DROP VIEW IF EXISTS checkouts CASCADE;
DROP VIEW IF EXISTS step_seven CASCADE;
DROP VIEW IF EXISTS duration_inter CASCADE;
DROP VIEW IF EXISTS checkout_return CASCADE;
DROP VIEW IF EXISTS duration_calc CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW branch_code AS 
SELECT code
FROM librarybranch;

-- This is a table that contains tha branch code and 5 years
CREATE VIEW branch_year AS 
SELECT *
FROM branch_code, YearTable;

CREATE VIEW new_event_schedule AS
SELECT EXTRACT(YEAR FROM edate) AS year, event, start_time
FROM eventschedule;

CREATE VIEW new_event_schedule2 AS
SELECT event, year, count(start_time) AS num_sessions
FROM new_event_schedule
GROUP BY event, year;

CREATE VIEW event_inter AS 
SELECT new_event_schedule2.year AS year, libraryevent.room AS room,  libraryevent.name AS event_name, libraryevent.id AS ID, new_event_schedule2.num_sessions AS num_sessions
FROM libraryevent, new_event_schedule2
WHERE libraryevent.id = new_event_schedule2.event;

-- All events in each year and each branch
CREATE VIEW event AS 
SELECT libraryroom.library AS branch, event_inter.year AS year, count(event_inter.room) AS events, avg(num_sessions) AS sessions
FROM libraryroom, event_inter
WHERE libraryroom.id = event_inter.room
GROUP BY libraryroom.library, event_inter.year;

CREATE VIEW step_three AS 
SELECT branch_year.code AS branch, branch_year.year AS year, COALESCE(event.events, 0) AS events, COALESCE(event.sessions, 0) AS sessions
FROM branch_year LEFT JOIN event ON (branch_year.code = event.branch AND branch_year.year = event.year);

CREATE VIEW registration_inter AS 
SELECT event AS ID, count(patron) AS registration
FROM eventsignup
GROUP BY event;

CREATE VIEW registration_inter2 AS 
SELECT libraryroom.library AS branch, event_inter.year AS year, event_inter.ID as ID
FROM libraryroom, event_inter
WHERE libraryroom.id = event_inter.room;

CREATE VIEW registration AS 
SELECT registration_inter2.branch, registration_inter2.year, sum(registration_inter.registration) AS registration
FROM registration_inter2, registration_inter
WHERE registration_inter2.ID = registration_inter.ID
GROUP BY registration_inter2.branch, registration_inter2.year;

CREATE VIEW step_five AS 
SELECT step_three.branch, step_three.year, step_three.events, step_three.sessions, COALESCE(registration.registration, 0) AS registration
FROM step_three LEFT JOIN registration ON (step_three.branch = registration.branch AND step_three.year = registration.year);

CREATE VIEW holdings AS 
SELECT library AS branch, count(holding) AS holdings
FROM libraryholding
GROUP BY library;

CREATE VIEW step_six AS 
SELECT step_five.branch, step_five.year, step_five.events, step_five.sessions, step_five.registration, COALESCE(holdings.holdings, 0) AS holdings
FROM step_five LEFT JOIN holdings ON (step_five.branch = holdings.branch);

CREATE VIEW librarycheckout AS 
SELECT libraryholding.library AS branch, checkout.id AS ID, EXTRACT(YEAR FROM checkout.checkout_time) AS year
FROM libraryholding, checkout
WHERE libraryholding.barcode = checkout.copy;

CREATE VIEW checkouts AS 
SELECT branch, year, count(id) AS checkouts
FROM librarycheckout
GROUP BY branch, year;

CREATE VIEW step_seven AS 
SELECT step_six.branch, step_six.year, step_six.events, step_six.sessions, step_six.registration, step_six.holdings, COALESCE(checkouts.checkouts, 0) AS checkouts
FROM step_six LEFT JOIN checkouts ON (step_six.branch = checkouts.branch AND step_six.year = checkouts.year);

CREATE VIEW duration_inter AS 
SELECT libraryholding.library AS branch, checkout.id AS ID, checkout.checkout_time AS checkout_time, EXTRACT(YEAR FROM checkout.checkout_time) AS year
FROM libraryholding, checkout
WHERE libraryholding.barcode = checkout.copy;

CREATE VIEW checkout_return AS 
-- SELECT EXTRACT(EPOCH FROM (return.return_time - duration_inter.checkout_time))/86400 AS durations, duration_inter.branch AS branch, duration_inter.year AS year
SELECT (DATE(return.return_time) - DATE(duration_inter.checkout_time)) AS durations, duration_inter.branch AS branch, duration_inter.year AS year
FROM duration_inter, return
WHERE duration_inter.ID = return.checkout;

CREATE VIEW duration_calc AS 
SELECT avg(durations) AS duration, branch, year
FROM checkout_return
GROUP BY branch, year;

-- Your query that answers the question goes below the "insert into" line:

INSERT INTO q1
SELECT step_seven.branch, step_seven.year, step_seven.events, step_seven.sessions, step_seven.registration, step_seven.holdings, step_seven.checkouts, COALESCE(duration_calc.duration, 0.0) AS duration
FROM step_seven LEFT JOIN duration_calc ON (step_seven.branch = duration_calc.branch AND step_seven.year = duration_calc.year);