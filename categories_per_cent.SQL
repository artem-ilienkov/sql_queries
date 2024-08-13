-- распределение ролей на платформе по когортам (месяц регистрации) по процентам
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

--------------------------------------------------------------
SELECT cohort AS "Когорта (месяц регистрации)",
       registration AS "Регистраций (подтв.)",
       CONCAT("Процент экспертов без брон.", '%') AS "Экспертов (не брон.) %",
       CONCAT("Процент Экспертов с брон.", '%') AS "Экспертов (брон.) %",
       CONCAT("Процент Исследователей", '%') AS "Исследователей %"
FROM
(
SELECT registration.cohort AS cohort,
       CASE 
           WHEN registration.quantity_resistration > '0' THEN '100%'
           ELSE 'NULL'
        END AS registration,
       experts_without.quantity_experts_without * 100 / registration.quantity_resistration AS "Процент экспертов без брон.",
       experts_with.quantity_experts_with * 100 / registration.quantity_resistration AS "Процент Экспертов с брон.",
       booked.quantity_booked * 100 / registration.quantity_resistration AS "Процент Исследователей"
FROM
(SELECT cohort,
        COUNT(id) quantity_resistration
FROM (SELECT CAST(id AS text) AS id,
             to_char(created_at, 'YYYY-MM') AS cohort
     FROM public.customer
     WHERE email_confirmed_at IS NOT NULL 
     AND phone IS NOT NULL
     AND first_name IS NOT NULL
     AND status = '1'
     AND created_at IS NOT NULL
     AND created_at >= '2024-03-01') AS t_2
GROUP BY cohort) AS registration
LEFT JOIN 
(SELECT cohort,
       COUNT(id) AS quantity_experts_without
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
GROUP BY cohort) AS experts_without
ON registration.cohort = experts_without.cohort
LEFT JOIN
(SELECT cohort,
       COUNT(id) AS quantity_experts_with
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
GROUP BY cohort) AS experts_with
ON registration.cohort = experts_with.cohort
LEFT JOIN
(SELECT cohort,
       COUNT(id) AS quantity_booked
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
GROUP BY cohort) AS booked 
ON registration.cohort = booked.cohort
) AS t_3