SELECT created_date,
       COUNT(member_id) AS Кол-во,
       CASE 
           WHEN created_date IS NOT NULL  THEN 'Бронирований всего'
           ELSE 'не определено'
       END AS type
FROM (SELECT userId AS member_id,
             DATE(createdAt) AS created_date
        FROM `krugi-prod-social`.activity_participant
        WHERE {{interval_from}} = DATE(createdAt) AND DATE(createdAt) = {{interval_to}}
        AND userId NOT IN (SELECT id AS authorId
                                FROM `krugi-prod-social`.users
                                WHERE phone IN ('70333377777',
                                                '12640826663333',
                                                '72828203554',
                                                '79160631144',
                                                '78005553535',
                                                '79619919840',
                                                '79833856638',
                                                '79831063666',
                                                '79635088274'))
        -- исключим бронирования организатора на свое мероприятие
        AND id NOT IN (SELECT bookings.booking_id AS booking_id
                        FROM (SELECT id AS booking_id,
                                     userId AS member_id,
                                     activityId AS activity_id,
                                     DATE(createdAt) AS created_date
                                FROM `krugi-prod-social`.activity_participant
                                WHERE {{interval_from}} = DATE(createdAt) AND DATE(createdAt) = {{interval_to}}
                                ) AS bookings
                                LEFT JOIN
                                (SELECT authorId AS author,
                                        id AS activityid,
                                        DATE(createdAt) AS created_date
                                FROM `krugi-prod-social`.activity
                                WHERE {{interval_from}} = DATE(createdAt) AND DATE(createdAt) = {{interval_to}}) AS events
                          ON bookings.activity_id = events.activityid
                       WHERE bookings.member_id = events.author)) AS t_1
GROUP BY created_date
UNION ALL
SELECT created_date,
       COUNT(member_id) AS Кол-во,
       CASE 
           WHEN created_date IS NOT NULL  THEN 'Бронирований с картой'
           ELSE 'не определено'
       END AS type
FROM (SELECT userId AS member_id,
             DATE(createdAt) AS created_date
        FROM `krugi-prod-social`.activity_participant
        WHERE {{interval_from}} = DATE(createdAt) AND DATE(createdAt) = {{interval_to}}
        AND userId NOT IN (SELECT id AS authorId
                                FROM `krugi-prod-social`.users
                                WHERE phone IN ('70333377777',
                                                '12640826663333',
                                                '72828203554',
                                                '79160631144',
                                                '78005553535',
                                                '79619919840',
                                                '79833856638',
                                                '79831063666',
                                                '79635088274'))
        AND withSpacePass = 1
        -- исключим бронирования организатора на свое мероприятие
        AND id NOT IN (SELECT bookings.booking_id AS booking_id
                        FROM (SELECT id AS booking_id,
                                     userId AS member_id,
                                     activityId AS activity_id,
                                     DATE(createdAt) AS created_date
                                FROM `krugi-prod-social`.activity_participant
                                WHERE {{interval_from}} = DATE(createdAt) AND DATE(createdAt) = {{interval_to}}
                                ) AS bookings
                                LEFT JOIN
                                (SELECT authorId AS author,
                                        id AS activityid,
                                        DATE(createdAt) AS created_date
                                FROM `krugi-prod-social`.activity
                                WHERE {{interval_from}} = DATE(createdAt) AND DATE(createdAt) = {{interval_to}}) AS events
                          ON bookings.activity_id = events.activityid
                       WHERE bookings.member_id = events.author)) AS t_1
GROUP BY created_date
UNION ALL
SELECT created_date,
       COUNT(member_id) AS Кол-во,
       CASE 
           WHEN created_date IS NOT NULL  THEN 'Бронирований без карты'
           ELSE 'не определено'
       END AS type
FROM (SELECT userId AS member_id,
             DATE(createdAt) AS created_date
        FROM `krugi-prod-social`.activity_participant
        WHERE {{interval_from}} = DATE(createdAt) AND DATE(createdAt) = {{interval_to}}
        AND userId NOT IN (SELECT id AS authorId
                                FROM `krugi-prod-social`.users
                                WHERE phone IN ('70333377777',
                                                '12640826663333',
                                                '72828203554',
                                                '79160631144',
                                                '78005553535',
                                                '79619919840',
                                                '79833856638',
                                                '79831063666',
                                                '79635088274'))
        AND withSpacePass = 0
        -- исключим бронирования организатора на свое мероприятие
        AND id NOT IN (SELECT bookings.booking_id AS booking_id
                        FROM (SELECT id AS booking_id,
                                     userId AS member_id,
                                     activityId AS activity_id,
                                     DATE(createdAt) AS created_date
                                FROM `krugi-prod-social`.activity_participant
                                WHERE {{interval_from}} = DATE(createdAt) AND DATE(createdAt) = {{interval_to}}
                                ) AS bookings
                                LEFT JOIN
                                (SELECT authorId AS author,
                                        id AS activityid,
                                        DATE(createdAt) AS created_date
                                FROM `krugi-prod-social`.activity
                                WHERE {{interval_from}} = DATE(createdAt) AND DATE(createdAt) = {{interval_to}}) AS events
                          ON bookings.activity_id = events.activityid
                       WHERE bookings.member_id = events.author)) AS t_1
GROUP BY created_date