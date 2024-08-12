-- каждому пользователю присвоим когорту (ГГГГ-ММ) по дате первого визита
WITH cohorts AS (SELECT client_id,
                        formatDateTime(visit_date, '%Y-%m') AS cohort,
                        visit_date :: date AS reg_date
                FROM (SELECT CAST("ym:pv:clientID" AS text) AS client_id,
                             "ym:pv:dateTime" AS visit_date,
                             ROW_NUMBER() OVER(PARTITION BY "ym:pv:clientID" ORDER BY "ym:pv:dateTime" ASC) AS visit_rang
                     FROM masterspace.ym_logs_hits
                     WHERE "ym:pv:date" :: date >= '2024-02-01'
                     --LIMIT 100
                     ) AS t_1
                WHERE visit_rang = '1'),

-- уникальных пользователей в когорте
cohorts_quantity AS (SELECT cohort,
                            COUNT(DISTINCT client_id) AS quantity
                     FROM cohorts
                     GROUP BY cohort),

-- уникальные визиты в день каждого пользователя
visit_date AS (SELECT client_id,
                      visit_date,
                      visit_rang
               FROM (SELECT CAST("ym:pv:clientID" AS text) AS client_id,
                            "ym:pv:dateTime" :: date AS visit_date,
                            ROW_NUMBER() OVER(PARTITION BY "ym:pv:clientID", "ym:pv:dateTime" ::date ORDER BY "ym:pv:dateTime" ASC) AS visit_rang
                     FROM masterspace.ym_logs_hits
                     WHERE "ym:pv:date" :: date >= '2024-02-01'
                     --LIMIT 100
                     ) AS t_1
                WHERE visit_rang = '1'
                ORDER BY visit_date),

-- пользователи, когорта, дата регистрации, дата визита, дней между регистрацией и визитом
agregation AS (SELECT visit_date.client_id AS client_id,
                      cohorts.cohort AS cohort,
                      cohorts_quantity.quantity AS quantity,
                      cohorts.reg_date AS reg_date,
                      visit_date.visit_date AS visit_date,
                      visit_date.visit_date - cohorts.reg_date AS diff
               FROM visit_date
               LEFT JOIN cohorts ON visit_date.client_id = cohorts.client_id
               LEFT JOIN cohorts_quantity ON cohorts.cohort = cohorts_quantity.cohort
               --WHERE visit_date.client_id = '166861314486801'
               )

SELECT cohort,
       quantity,
       diff,
       COUNT(client_id) AS quantity_users,
       (COUNT(client_id) * 100) / quantity AS per_cent
FROM agregation
WHERE diff <= '100'
GROUP BY cohort, quantity, diff
ORDER BY cohort,quantity,diff