-- распределение ролей на платформе по когортам (месяц регистрации)
WITH experts AS (SELECT cohorts.cohort AS cohort,
                        expert.id AS id
                 FROM (SELECT DISTINCT(id) AS id
                       FROM (
        -- пользователи создавшие специалиста с 01-03-2024       
                       SELECT id
                       FROM (SELECT CAST(owner_id AS text) AS id,
                                    CASE published
                                        WHEN TRUE THEN 'TRUE'
                                        WHEN FALSE THEN 'FALSE'
                                        ELSE 'NULL'
                                   END AS published_status
                                FROM public.specialist 
                                WHERE created_at >= '2024-03-01') AS t_1
                WHERE published_status = 'TRUE'
                UNION
        -- пользователи создавшие организацию с 01-03-2024                    
                SELECT id
                FROM (SELECT CAST(owner_id AS text) AS id,
                             CASE published
                                  WHEN TRUE THEN 'TRUE'
                                  WHEN FALSE THEN 'FALSE'
                                  ELSE 'NULL'
                             END AS published_status
                     FROM public.company 
                     WHERE created_at >= '2024-03-01') AS t_2
                WHERE published_status = 'TRUE'                              
                UNION
        -- пользователи создавшие статью с 01-03-2024                    
                SELECT id
                FROM (SELECT CAST(owner_id AS text) AS id,
                             CASE published
                                 WHEN TRUE THEN 'TRUE'
                                 WHEN FALSE THEN 'FALSE'
                                 ELSE 'NULL'
                                 END AS published_status
                     FROM public.article 
                     WHERE created_at >= '2024-03-01') AS t_3
                WHERE published_status = 'TRUE'
                UNION
        -- пользователи создавшие мероприятие с 01-03-2024                    
                SELECT id
                FROM (SELECT CAST(owner_id AS text) AS id,
                             CASE published
                                 WHEN TRUE THEN 'TRUE'
                                 WHEN FALSE THEN 'FALSE'
                                 ELSE 'NULL'
                             END AS published_status
                     FROM public.treatment 
                     WHERE created_at >= '2024-03-01') AS t_4
                WHERE published_status = 'TRUE'
                UNION
        -- пользователи, продукты которых в архиве    
                SELECT id        
                FROM (SELECT CAST(owner_id AS text) AS id
                FROM public.promotion_treatment_history
                WHERE created_at >= '2024-03-01') AS t_5) AS t_6) AS expert 
            RIGHT JOIN
            (SELECT CAST(id AS text) AS id,
                    to_char(created_at, 'YYYY-MM') AS cohort
            FROM public.customer
            WHERE email_confirmed_at IS NOT NULL 
            AND phone IS NOT NULL
            AND first_name IS NOT NULL
            AND status = '1'
            AND created_at IS NOT NULL
            AND created_at >= '2024-03-01') AS cohorts
            ON expert.id = cohorts.id)

-------------------------------------------------------------------
SELECT *
FROM
(
SELECT cohort,
       COUNT(id) AS quantity_experts_without,
       CASE 
           WHEN COUNT(id) > '0' THEN 'Эксперт(не бронировал)'
           WHEN COUNT(id) < '0' THEN 'FALSE'
           ELSE 'NULL'
        END AS status
FROM experts 
WHERE id NOT IN (SELECT id
                 FROM (SELECT DISTINCT(CAST(customer_id AS text)) AS id   
                          FROM public.booking_treatment 
                          WHERE created_at :: date >= '2024-03-01' ) AS t_1
                 WHERE id IN (SELECT CAST(id AS text) AS id
                              FROM public.customer
                              WHERE email_confirmed_at IS NOT NULL 
                              AND phone IS NOT NULL
                              AND first_name IS NOT NULL
                              AND status = '1'
                              AND created_at IS NOT NULL
                              AND created_at >= '2024-03-01'))
GROUP BY cohort
UNION
SELECT cohort,
       COUNT(id) AS quantity_experts_with,
       CASE 
           WHEN COUNT(id) > '0' THEN 'Эксперт(бронировал)'
           WHEN COUNT(id) < '0' THEN 'FALSE'
           ELSE 'NULL'
        END AS status
FROM experts 
WHERE id IN (SELECT id
                 FROM (SELECT DISTINCT(CAST(customer_id AS text)) AS id   
                          FROM public.booking_treatment 
                          WHERE created_at :: date >= '2024-03-01' ) AS t_1
                 WHERE id IN (SELECT CAST(id AS text) AS id
                              FROM public.customer
                              WHERE email_confirmed_at IS NOT NULL 
                              AND phone IS NOT NULL
                              AND first_name IS NOT NULL
                              AND status = '1'
                              AND created_at IS NOT NULL
                              AND created_at >= '2024-03-01'))
GROUP BY cohort                       
UNION
SELECT cohort,
       COUNT(id) AS quantity_booked,
       CASE 
           WHEN COUNT(id) > '0' THEN 'Исследователь'
           WHEN COUNT(id) < '0' THEN 'FALSE'
           ELSE 'NULL'
        END AS status
FROM (SELECT id,
             to_char(created_date, 'YYYY-MM') AS cohort
     FROM (SELECT CAST(customer_id AS text) AS id,
                  created_at AS created_date,
                  ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY created_at ASC) AS rang
           FROM public.booking_treatment 
           WHERE customer_id IS NOT NULL
           AND created_at :: date >= '2024-03-01') AS t_1
           WHERE rang = '1'
           AND id IN (SELECT CAST(id AS text) AS id
                     FROM public.customer
                     WHERE email_confirmed_at IS NOT NULL 
                     AND phone IS NOT NULL
                     AND first_name IS NOT NULL
                     AND status = '1'
                     AND created_at IS NOT NULL
                     AND created_at >= '2024-03-01')) AS t_2                    
GROUP BY cohort
UNION
SELECT cohort,
        COUNT(id) quantity_resistration,
        CASE 
           WHEN COUNT(id) > '0' THEN 'Регистрация(подтверждено)'
           WHEN COUNT(id) < '0' THEN 'FALSE'
           ELSE 'NULL'
        END AS status
FROM (SELECT CAST(id AS text) AS id,
             to_char(created_at, 'YYYY-MM') AS cohort
     FROM public.customer
     WHERE email_confirmed_at IS NOT NULL 
     AND phone IS NOT NULL
     AND first_name IS NOT NULL
     AND status = '1'
     AND created_at IS NOT NULL
     AND created_at >= '2024-03-01') AS t_2
GROUP BY cohort
UNION
SELECT cohort,
        COUNT(id) quantity_resistration,
        CASE 
           WHEN COUNT(id) > '0' THEN 'Регистрация(общая)'
           WHEN COUNT(id) < '0' THEN 'FALSE'
           ELSE 'NULL'
        END AS status
FROM (SELECT CAST(id AS text) AS id,
             to_char(created_at, 'YYYY-MM') AS cohort
     FROM public.customer
     WHERE status <> 99
     AND created_at >= '2024-03-01') AS t_3
GROUP BY cohort
) AS t_1
ORDER BY
cohort ASC,
    CASE status
        WHEN 'Регистрация' THEN 1
        WHEN 'Исследователь' THEN 4
        WHEN 'Эксперт(не бронировал)' THEN 2
        WHEN 'Эксперт(бронировал)' THEN 3
    END ASC
