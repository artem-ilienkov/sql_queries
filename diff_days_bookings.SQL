SELECT bookings.user_id,
       booked_users.booked_status_user,
       bookings.event_id,
       bookings.booking_date,
       events.start_date,
       events.format,
       events.type,
       events.author_id,
       booked_authors.booked_status_author,
       DATEDIFF(events.start_date, bookings.booking_date) AS diff_start
  FROM (SELECT userId AS user_id,
               activityId AS event_id,
               DATE(createdAt) AS booking_date,
               withSpacePass AS pass_status
          FROM `krugi-prod-social`.activity_participant
         WHERE DATE(createdAt) >= "2024-12-01"
           AND deletedAt IS NULL
           AND userId NOT IN (SELECT id 
                                FROM `krugi-prod-social`.users
                               WHERE phone IN ('70333377777',
                                               '12640826663333',
                                               '72828203554',
                                               '79160631144',
                                               '78005553535',
                                               '79619919840',
                                               '79833856638',
                                               '79831063666',
                                               '79635088274',
                                               '71111111111',
                                               '78005553535')
                                  OR externalId = "crm")) AS bookings
    LEFT JOIN
    (SELECT id AS event_id,
            DATE(startDate) AS start_date,
            DATE(endDate) AS end_date,
            DATE(createdAt) AS created_date,
            format,
            type,
            authorId AS author_id
       FROM `krugi-prod-social`.activity
      WHERE DATE(createdAt) >= "2024-12-01"
        AND authorId NOT IN (SELECT id 
                               FROM `krugi-prod-social`.users
                              WHERE phone IN ('70333377777',
                                              '12640826663333',
                                              '72828203554',
                                              '79160631144',
                                              '78005553535',
                                              '79619919840',
                                              '79833856638',
                                              '79831063666',
                                              '79635088274',
                                              '71111111111',
                                              '78005553535')
                                  OR externalId = "crm"
                                  OR clubMemberStatus = "MEMBER")) AS events
    ON bookings.event_id = events.event_id
    LEFT JOIN
    (SELECT id AS booked_user,
            clubMemberStatus AS booked_status_user
       FROM `krugi-prod-social`.users) AS booked_users
    ON bookings.user_id = booked_users.booked_user
    LEFT JOIN
    (SELECT id AS booked_author,
            clubMemberStatus AS booked_status_author
       FROM `krugi-prod-social`.users) AS booked_authors
    ON bookings.user_id = booked_authors.booked_author
WHERE events.start_date IS NOT NULL
  AND (DATEDIFF(events.start_date, bookings.booking_date) > 0)
  AND (DATEDIFF(events.end_date, bookings.booking_date) > 0 )
  AND bookings.user_id != events.author_id