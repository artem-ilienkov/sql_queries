-- рассчет разницы в процентах кол-ва бронирований в выбранном периоде по сравнению с предыдущим периодо, равному кол-ву дней в периоде, выбранном в селекторе.
-- исключая бронирования, админом, кругами, тестером
SELECT percentage_change  AS "Изменение по сравнению с прошлым периодом (брон.всего)"
 FROM (SELECT now_created.booked_now,
              before_created.booked_before,
              CASE 
                  WHEN before_created.booked_before = 0 THEN "Нет данных" -- чтобы неделить на ноль
                  ELSE CONCAT(ROUND(((now_created.booked_now - before_created.booked_before) * 100.0 / before_created.booked_before), 1), "%%")
              END AS percentage_change
        FROM (-- пользователи за выбранный период в селекторе
              (SELECT COUNT(member_id) AS booked_now,
                      CASE 
                          WHEN COUNT(member_id) >= 0 THEN 'period'
                          WHEN COUNT(member_id) < 0 THEN 'period'
                          ELSE 'не определено'
                      END AS status    
                FROM (SELECT userId AS member_id,
                             DATE(createdAt) AS created_date
                        FROM `krugi-prod-social`.activity_participant
                       WHERE {{interval_from}} <= DATE(createdAt) AND DATE(createdAt) <= {{interval_to}}
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
                                                              '79635088274',
                                                              '71111111111',
                                                              '78005553535',
                                                              'crm'))
                         -- исключим бронирования организатора на свое мероприятие
                         AND id NOT IN (SELECT bookings.booking_id AS booking_id
                                          FROM (SELECT id AS booking_id,
                                                       userId AS member_id,
                                                       activityId AS activity_id,
                                                       DATE(createdAt) AS created_date
                                                  FROM `krugi-prod-social`.activity_participant
                                                 WHERE {{interval_from}} <= DATE(createdAt) AND DATE(createdAt) <= {{interval_to}}
                                                ) AS bookings
                                                LEFT JOIN
                                                (SELECT authorId AS author,
                                                        id AS activityid,
                                                        DATE(createdAt) AS created_date
                                                   FROM `krugi-prod-social`.activity
                                                  WHERE {{interval_from}} <= 
                                                  DATE(createdAt) AND DATE(createdAt) <= {{interval_to}}) AS events
                                                ON bookings.activity_id = events.activityid
                                            WHERE bookings.member_id = events.author)) AS t_1) AS now_created
              LEFT JOIN
              -- пользователи за предыдущий период равный кол-ву дней в селекторе
              (SELECT COUNT(member_id) AS booked_before,
                      CASE 
                          WHEN COUNT(member_id) >= 0 THEN 'period'
                          WHEN COUNT(member_id) < 0 THEN 'period'
                          ELSE 'не определено'
                      END AS status    
                FROM (SELECT userId AS member_id,
                             DATE(createdAt) AS created_date
                        FROM `krugi-prod-social`.activity_participant
                        WHERE DATE(createdAt) BETWEEN DATE_SUB({{interval_from}}, INTERVAL DATEDIFF({{interval_to}}, {{interval_from}}) + 1 DAY) AND DATE_SUB({{interval_to}}, INTERVAL DATEDIFF({{interval_to}}, {{interval_from}}) + 1 DAY)
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
                                           '79635088274',
                                           '71111111111',
                                           '78005553535',
                                           'crm'))
                          -- исключим бронирования организатора на свое мероприятие
                          AND id NOT IN (SELECT bookings.booking_id AS booking_id
                                           FROM (SELECT id AS booking_id,
                                                        userId AS member_id,
                                                        activityId AS activity_id,
                                                        DATE(createdAt) AS created_date
                                                  FROM `krugi-prod-social`.activity_participant
                                                 WHERE {{interval_from}} <= DATE(createdAt) AND DATE(createdAt) <= {{interval_to}}
                                                ) AS bookings
                                                LEFT JOIN
                                                (SELECT authorId AS author,
                                                        id AS activityid,
                                                        DATE(createdAt) AS created_date
                                                  FROM `krugi-prod-social`.activity
                                                 WHERE {{interval_from}} <= DATE(createdAt) AND DATE(createdAt) <= {{interval_to}}) AS events
                                        ON bookings.activity_id = events.activityid
                                    WHERE bookings.member_id = events.author)) AS t_2) AS before_created
                            ON now_created.status = before_created.status)
) AS main_tab

