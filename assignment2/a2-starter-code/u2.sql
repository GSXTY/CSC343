WITH CheckOutInfo AS (
  SELECT 
      lh.library AS branch,
      lb.name,
      co.patron,
      co.id,
      h.title,
      co.checkout_time,
      co.checkout_time + INTERVAL '21 days' AS expected_return,
      CURRENT_DATE AS current_date,
      CASE 
          WHEN h.htype IN ('books', 'audiobooks') THEN EXTRACT(DAY FROM CURRENT_DATE - (co.checkout_time + INTERVAL '21 days'))
          WHEN h.htype IN ('movies', 'music', 'magazines and newspapers') THEN EXTRACT(DAY FROM CURRENT_DATE - (co.checkout_time + INTERVAL '7 days'))
      END AS overdue
  FROM 
      library.checkout co
  JOIN library.libraryholding lh ON co.copy = lh.barcode
  JOIN library.holding h ON lh.holding = h.id
  JOIN library.librarybranch lb ON lb.code = lh.library
  LEFT JOIN library.return r ON co.id = r.checkout
  GROUP BY lb.name, co.patron, co.id, lh.library, h.title, h.htype, co.checkout_time,
           co.checkout_time,
           CURRENT_DATE
  HAVING lb.name = 'Downsview' and h.htype = 'books'
),
LessThanFive AS (
  SELECT patron
  FROM CheckOutInfo
  GROUP BY patron
  HAVING (
    COUNT(*) <= 5
  )
),
HasOverDue7 AS (
  SELECT patron
  FROM CheckOutInfo
  GROUP BY patron, overdue
  HAVING (
    overdue > 7
  )
),
NoOverDue7 AS (
  SELECT patron
  FROM CheckOutInfo
  EXCEPT
  SELECT patron
  FROM HasOverDue7
),
TargetPatron AS (
  SELECT patron 
  FROM LessThanFive
  INTERSECT
  SELECT patron 
  FROM NoOverDue7
),
UpdatedInfo AS (
  SELECT id
  FROM CheckOutInfo c
  JOIN TargetPatron t
  ON c.patron = t.patron
)

UPDATE checkout
SET checkout_time = checkout_time + INTERVAL '14 days'
WHERE id in (SELECT id from UpdatedInfo);


