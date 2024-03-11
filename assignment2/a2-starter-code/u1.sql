WITH EventSessions AS (
  SELECT es.event, es.edate, TO_CHAR(edate, 'Day') AS day, es.start_time, es.end_time, le.room, le.name, lr.library
  FROM eventschedule es
  JOIN libraryevent le ON es.event = le.id
  JOIN libraryroom lr ON le.room = lr.id
  GROUP BY es.event, es.edate, es.start_time, es.end_time, le.room, le.name, lr.library
  ORDER BY es.event, es.edate, es.start_time, es.end_time, le.room, le.name, lr.library
),
LibraryOperatingHours AS (
    SELECT
      library, 
      CASE 
          WHEN day = 'mon' THEN 'Monday'
          WHEN day = 'tue' THEN 'Tuesday'
          WHEN day = 'wed' THEN 'Wednesday'
          WHEN day = 'thu' THEN 'Thursday'
          WHEN day = 'fri' THEN 'Friday'
          WHEN day = 'sat' THEN 'Saturday'
          WHEN day = 'sun' THEN 'Sunday'
      END as full_day_name,
      start_time, 
      end_time
    FROM libraryhours
),
ExtendedEventSessions AS (
    SELECT 
        es.event,
        es.edate,
        TRIM(es.day) AS day,  -- Trim the day to remove padding spaces
        es.start_time,
        es.end_time,
        es.room,
        es.name,
        es.library,
        COALESCE(lh.start_time) AS library_start_time,
        COALESCE(lh.end_time) AS library_end_time
    FROM EventSessions es
    LEFT JOIN LibraryOperatingHours lh 
    ON es.library = lh.library AND TRIM(es.day) = lh.full_day_name 
    ORDER BY es.event
),
OutOfHoursEvents AS (
  SELECT event, edate, start_time, end_time
  FROM ExtendedEventSessions
  WHERE (start_time < library_start_time OR end_time > library_end_time OR library_start_time IS NULL OR library_end_time IS NULL)
)

DELETE FROM eventschedule
WHERE (event, edate, start_time, end_time) IN (SELECT event, edate, start_time, end_time FROM OutOfHoursEvents);

-- 2. 确认是否有事件由于删除了所有会话而没有剩余会话
CREATE VIEW EventsLeft AS 
    SELECT le.id AS event
    FROM libraryevent le
    LEFT JOIN eventschedule es ON le.id = es.event
    GROUP BY le.id
    HAVING COUNT(es.event) = 0;

-- 3. 删除没有剩余会话的事件
DELETE FROM libraryevent
WHERE id IN (SELECT event FROM EventsLeft);

-- 4. 删除所有与第3步中删除的事件相关联的注册信息
DELETE FROM eventsignup
WHERE event IN (SELECT event FROM EventsLeft);

DROP VIEW  IF EXISTS EventsLeft CASCADE;