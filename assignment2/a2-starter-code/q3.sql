-- Promotion

-- You must not change the next 2 lines, the domain definition, or the table definition.
SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q3 cascade;

DROP DOMAIN IF EXISTS patronCategory;
create domain patronCategory as varchar(10)
  check (value in ('inactive', 'reader', 'doer', 'keener'));

create table q3 (
    patronID Char(20) NOT NULL,
    category patronCategory
);


-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
-- If you do not define any views, you can delete the lines about views.
--DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here:
--CREATE VIEW intermediate_step AS ... ;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3

WITH PatronCheckOut AS (
    (SELECT DISTINCT 
		c.patron, 
		lh.library
    FROM library.checkout c
    JOIN library.libraryholding lh ON c.copy = lh.barcode)
	ORDER BY c.patron
),
PatronLibraryCheckouts AS (
    SELECT c.patron, COUNT(*) AS patron_total_checkouts
    FROM library.checkout c
    GROUP BY c.patron
),
PatronSignUp AS (
	(SELECT DISTINCT
		es.patron,
		lr.library
	FROM library.eventsignup es
	JOIN library.libraryevent le ON es.event = le.id
	JOIN library.libraryroom lr ON le.room = lr.id)
	ORDER BY es.patron
),
PatronLibraries AS (
    (SELECT patron, library FROM PatronCheckOut
    UNION
    SELECT patron, library FROM PatronSignUp)
),
LibraryCheckouts AS (
	SELECT lh.library, c.patron AS checkout_patron
    FROM library.checkout c
    LEFT JOIN library.libraryholding lh ON c.copy = lh.barcode
    GROUP BY lh.library, c.patron
),
PatronCheckOutStats  AS (
	SELECT 
        pl.patron,
        pl.library,
        lc.checkout_patron
    FROM 
        PatronLibraries pl
    LEFT JOIN 
        LibraryCheckouts lc ON pl.library = lc.library
    ORDER BY pl.patron, lc.checkout_patron
),
CheckOutData AS (
    SELECT pcs.patron, pcs.checkout_patron, plc.patron_total_checkouts 
    FROM PatronCheckOutStats pcs
    JOIN PatronLibraryCheckouts plc
    ON pcs.checkout_patron = plc.patron
    GROUP BY pcs.patron, pcs.checkout_patron, plc.patron_total_checkouts
    ORDER BY pcs.patron, pcs.checkout_patron, plc.patron_total_checkouts
),
ALLCheckOutData AS (
    SELECT cod.patron, 
        CASE 
            WHEN plc.patron_total_checkouts IS NULL THEN 0
            ELSE plc.patron_total_checkouts
		END AS patronself_checkout,
       COUNT(DISTINCT(cod.checkout_patron)) AS total_checkout_patron,
       SUM(cod.patron_total_checkouts) AS other_total_checkout,
       CAST(SUM(cod.patron_total_checkouts) AS FLOAT) / NULLIF(COUNT(DISTINCT(cod.checkout_patron)), 0) AS average_checkout
    FROM CheckOutData cod
    LEFT JOIN PatronLibraryCheckouts plc
    ON cod.patron = plc.patron
    GROUP BY cod.patron, plc.patron_total_checkouts
    ORDER BY cod.patron
),
CheckOutClass AS (
	SELECT
		acod.patron,
		acod.average_checkout,
		acod.patronself_checkout,
		CASE
			WHEN acod.patronself_checkout > acod.average_checkout * 0.75 THEN 'high'
			WHEN acod.patronself_checkout < acod.average_checkout * 0.25 THEN 'low'
			WHEN acod.average_checkout IS NULL THEN 'low'
			ELSE 'medium' 
		END AS checkout_category
	FROM ALLCheckOutData acod
    ORDER BY acod.patron
),
PatronLibrarySignups AS (
    SELECT es.patron, COUNT(*) AS patron_total_signups
    FROM library.eventsignup es
    GROUP BY es.patron
),
LibrarySignups AS (
    SELECT lr.library, es.patron AS signup_patron
    FROM library.eventsignup es
    JOIN library.libraryevent le ON es.event = le.id
    JOIN library.libraryroom lr ON le.room = lr.id
    GROUP BY lr.library, es.patron
),
PatronSignUpStats  AS (
	SELECT 
        pl.patron,
        pl.library,
        ls.signup_patron
    FROM 
        PatronLibraries pl
    LEFT JOIN 
        LibrarySignups ls ON pl.library = ls.library
    ORDER BY pl.patron, ls.signup_patron
),
SignUpData AS (
    SELECT psu.patron, psu.signup_patron, pls.patron_total_signups 
    FROM PatronSignUpStats psu
    LEFT JOIN PatronLibrarySignups pls
    ON psu.signup_patron = pls.patron
    GROUP BY psu.patron, psu.signup_patron, pls.patron_total_signups
    ORDER BY psu.patron, psu.signup_patron, pls.patron_total_signups
),
ALLSignUpData AS (
    SELECT sud.patron, 
        CASE 
            WHEN pls.patron_total_signups IS NULL THEN 0
            ELSE pls.patron_total_signups
		END AS patronself_signup,
       COUNT(DISTINCT(sud.signup_patron)) AS total_signup_patron,
       SUM(sud.patron_total_signups) AS other_total_signup,
       CAST(SUM(sud.patron_total_signups) AS FLOAT) / NULLIF(COUNT(DISTINCT(sud.signup_patron)), 0) AS average_signup
    FROM SignUpData sud
    LEFT JOIN PatronLibrarySignups pls
    ON sud.patron = pls.patron
    GROUP BY sud.patron, pls.patron_total_signups
    ORDER BY sud.patron
),
SignUpClass AS (
	SELECT
		asud.patron,
		asud.average_signup,
		asud.patronself_signup,
		CASE
			WHEN asud.patronself_signup > asud.average_signup * 0.75 THEN 'high'
			WHEN asud.patronself_signup < asud.average_signup * 0.25 THEN 'low'
			WHEN asud.average_signup IS NULL THEN 'low'
			ELSE 'medium' 
		END AS signup_category
	FROM ALLSignUpData asud
),
AllPatron AS (
	SELECT patron
	FROM CheckOutClass
	UNION
	SELECT patron
	FROM SignUpClass
),
CombinedInfo AS (
    SELECT
        AP.patron,
        CO.average_checkout,
        CO.patronself_checkout,
		CO.checkout_category,
        SU.average_signup,
        SU.patronself_signup,
		SU.signup_category
    FROM AllPatron AP
    LEFT JOIN CheckOutClass CO ON AP.patron = CO.patron
    LEFT JOIN SignUpClass SU ON AP.patron = SU.patron
),
ClassifiedPatrons AS (
    SELECT 
        patron,
        average_checkout,
        patronself_checkout,
        checkout_category,
        average_signup,
        patronself_signup,
        signup_category,
        CASE
            WHEN checkout_category = 'low' AND signup_category = 'low' THEN 'inactive'
            WHEN checkout_category = 'high' AND signup_category = 'high' THEN 'keener'
            WHEN checkout_category = 'high' AND signup_category = 'low' THEN 'reader'
            WHEN checkout_category = 'low' AND signup_category = 'high' THEN 'doer'
            ELSE 'idk' -- 'idk' stands for "I don't know", representing all other cases not covered above
        END AS final_category
    FROM CombinedInfo
)
SELECT patron AS patronID, final_category AS category
FROM ClassifiedPatrons
WHERE NOT final_category = 'idk'
ORDER BY patron;
