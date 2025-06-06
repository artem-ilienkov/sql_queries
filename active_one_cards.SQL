SELECT cards.user_id,
       cards.status,
       cards.start_date,
       cards.expiration_date,
       events.event_id,
       events.start_date_event,
       events.end_date_event,
       events.event_name
  FROM (SELECT user_id,
               status,
               start_date,
               expiration_date
         FROM (SELECT cards.user_id,
                      cards.card_type,
                      cards.status,
                      cards.createdAt,
                      cards.expirationDate AS expiration_date,
                      cards.daysLimit,
                      cards.expirationDate - INTERVAL cards.daysLimit DAY AS start_date,
                      ROW_NUMBER()OVER(PARTITION BY cards.user_id ORDER BY  cards.createdAt) AS num
                 FROM (SELECT userId AS user_id,
                              id AS card_id,
                              type AS card_type,
                              status,
                              createdAt,
                              expirationDate,
                              daysLimit
                         FROM `krugi-prod-social`.space_pass
                        WHERE type = "SPACE_PASS_ONE"
                          AND userId NOT IN (SELECT id AS userId
                                               FROM `krugi-prod-social`.users
                                              WHERE phone IN ('70333377777',
                                                              '12640826663333',
                                                              '72828203554',
                                                              '79160631144',
                                                              '78005553535',
                                                              '79619919840',
                                                              '79833856638',
                                                              '79635088274',
                                                              '71111111111',
                                                              '78005553535'))
                      ) AS cards
                      LEFT JOIN
                      (SELECT id AS user_id,
                              DATE(createdAt) AS reg_date,
                              clubMemberStatus AS user_status
                        FROM `krugi-prod-social`.users
                      ) AS users
                      ON cards.user_id = users.user_id
                      WHERE users.user_status NOT IN ("AMBASSADOR", "MEMBER")
                        AND expirationDate IS NOT NULL
                        AND status != "PENDING"
                      ) AS t_1
        WHERE num = 1
        ) AS cards
        LEFT JOIN
        (SELECT bookings.user_id,
                bookings.event_id,
                events.start_date_event,
                events.end_date_event,
                events.event_name
           FROM
        (SELECT userId AS user_id,
                activityId AS event_id
        FROM `krugi-prod-social`.activity_participant
        WHERE withSpacePass = 1
        ) AS bookings
        LEFT JOIN
        (SELECT id AS event_id,
                DATE(startDate) AS start_date_event,
                DATE(endDate) AS end_date_event,
                name AS event_name
        FROM `krugi-prod-social`.activity
        ) AS events
        ON bookings.event_id = events.event_id
        ) events
        ON cards.user_id = events.user_id
        #WHERE start_date_event BETWEEN start_date AND expiration_date
        WHERE start_date <= start_date_event <= expiration_date