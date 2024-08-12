-- основной запрос для анализа частоты использования продукта 

SELECT cohort,
       status,
       per_cent
  FROM (SELECT *,
               LAG(per_cent) OVER(PARTITION BY cohort, status) AS condition
          FROM (SELECT cohort,
                       status,
                       COUNT(id) OVER(PARTITION BY cohort, status) * 100 / count AS per_cent
                  FROM (SELECT id,
                        to_char(reg_date, 'YYYY-MM') AS cohort,
                        COUNT(id) OVER(PARTITION BY to_char(reg_date, 'YYYY-MM')) AS Count,
                        sales_rang,
                        date - reg_date AS day_diff,
                        CASE 
                            WHEN date - reg_date >= '0' AND date - reg_date < '4' THEN 'Первые 4 дня (%)'
                            WHEN date - reg_date >= '4' AND date - reg_date <= '10' THEN 'От 5 до 10 дней (%)'
                            WHEN date - reg_date >= '11' AND date - reg_date <= '31' THEN 'От 11 до 31 дня (%)'
                            WHEN date - reg_date >= '32' THEN 'От 32 и более дней (%)'
                            ELSE 'NULL'
                            END AS status
                         FROM (SELECT *,
                        /* избавление от ситуации, когда по факту мероприятие одно, но разные id, просто Эксперт менял названия,
                        для этого уберем те, где между мероприятиями 0 дней */
                                      date - previous_date AS date_diff,
                                      ROW_NUMBER() OVER(PARTITION BY id ORDER BY date ASC) AS sales_rang
                                 FROM (SELECT registration.id AS id,
                                              registration.reg_date AS reg_date,
                                              events.date,
                                              LAG(events.date) OVER (PARTITION BY registration.id ORDER BY events.date) AS previous_date
                                        FROM (SELECT CAST(id AS text) AS id,
                                                    CAST(created_at AS date) AS reg_date
                                                FROM public.customer
                                                WHERE email_confirmed_at IS NOT NULL 
                                                AND created_at >= '2024-03-01') AS registration
        LEFT JOIN
        (SELECT id,
                event_id,
                date
           FROM (SELECT CAST(owner_id AS text) AS id,
                        CAST(id AS text) AS event_id,
                        created_at::date AS date,
                        CASE published
                             WHEN TRUE THEN 'TRUE'
                             WHEN FALSE THEN 'FALSE'
                             ELSE 'NULL'
                        END AS published_status
                   FROM public.treatment 
                   WHERE created_at::date >= '2024-03-01') AS events_real
           WHERE published_status = 'TRUE') AS events
        ON registration.id = events.id
        WHERE events.event_id IS NOT NULL) AS t_1) AS t_2
 WHERE (date_diff != 0 OR date_diff IS NULL)
   AND sales_rang = 1
       ) AS t_3
    ) AS t_4
) AS t_5
WHERE condition IS NULL
