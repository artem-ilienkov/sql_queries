SELECT users.cohort,
       users.users AS registrations,
       (users_quests.guests * 100) / users.users AS conv_guest,
       users_quests.guests AS guests,
       (members.memberships * 100) / users.users AS conv_member,
       members.memberships,
       (events.events * 100) / users.users AS conv_eventer,
       events.events,
       (posts.posts * 100) / users.users AS conv_post,
       posts.posts,
       (post_users.post_view * 100) / users.users AS conv_post_view,
       post_users.post_view,
       (posts_like.post_like * 100) / users.users AS conv_like,
       posts_like.post_like,
       (stories.stories * 100) / users.users AS conv_story,
       stories.stories,
       (comments.comments * 100) / users.users AS conv_comm,
       comments.comments,
       (lives.lives * 100) / users.users AS conv_live,
       lives.lives,
       (chats_all.chats * 100) / users.users AS conv_chat,
       chats_all.chats,
       (chat_members.chat_members * 100) / users.users AS conv_m_chat,
       chat_members.chat_members
  FROM
     -- формирование таблицы с кол-вом зарегистрированных Пользователей
    (SELECT cohort,
            COUNT(user_id) AS users 
       FROM (SELECT id AS user_id,
                    clubMemberStatus AS status,
                    DATE_FORMAT(createdAt, '%Y-%m') AS cohort
               FROM `krugi-prod-social`.users AS users) AS t_2
    GROUP BY cohort) AS users
    LEFT JOIN
    -- формирование таблицы с кол-вом Жителей
    (SELECT cohort,
        COUNT(user_id) AS guests
    FROM (SELECT id AS user_id,
                clubMemberStatus AS status,
                DATE_FORMAT(createdAt, '%Y-%m') AS cohort
            FROM `krugi-prod-social`.users AS users
            WHERE clubMemberStatus = 'GUEST') AS t_2
    GROUP BY cohort) AS users_quests
    ON users.cohort = users_quests.cohort
    LEFT JOIN
    -- формирование таблицы с кол-вом вступивших в сообщество
    (SELECT cohorts.cohort AS cohort,
            COUNT(member.user_id) AS memberships  
      FROM (SELECT userId AS user_id
              FROM (SELECT userId,
                           createdAt,
                           ROW_NUMBER() OVER(PARTITION BY userId ORDER BY createdAt ASC) AS rang
                     FROM `krugi-prod-social`.community_memberships AS t_1
             WHERE userId IN (SELECT id AS userId
                                FROM `krugi-prod-social`.users AS users
                               WHERE clubMemberStatus IN ('GUEST'))) AS t_2
     WHERE rang = 1) AS member 
        LEFT JOIN
           (SELECT id AS user_id,
                   DATE_FORMAT(createdAt, '%Y-%m') AS cohort
              FROM `krugi-prod-social`.users AS users) AS cohorts
        ON member.user_id = cohorts.user_id
    GROUP BY cohorts.cohort) AS members
    ON users.cohort = members.cohort
    LEFT JOIN
    -- формирование таблицы с кол-вом участников мероприятия
    (SELECT cohorts.cohort AS cohort,
            COUNT(member.user_id) AS events    
      FROM (SELECT userId AS user_id
              FROM (SELECT userId,
                           createdAt,
                           ROW_NUMBER() OVER(PARTITION BY userId ORDER BY createdAt ASC) AS rang
                      FROM `krugi-prod-social`.activity_participant AS t_1
                     WHERE userId IN (SELECT id AS userId
                                        FROM `krugi-prod-social`.users AS users
                                       WHERE clubMemberStatus IN ('GUEST'))) AS t_1
             WHERE rang = 1) AS member 
        LEFT JOIN
           (SELECT id AS user_id,
                   DATE_FORMAT(createdAt, '%Y-%m') AS cohort
             FROM `krugi-prod-social`.users AS users) AS cohorts
               ON member.user_id = cohorts.user_id
    GROUP BY cohorts.cohort) AS events
    ON users.cohort = events.cohort
    -- формирование таблицы с кол-вом сгенерировавших сторис
    LEFT JOIN
    (SELECT cohorts.cohort AS cohort,
            COUNT(stories.user_id) AS stories    
       FROM (SELECT authorId AS user_id
               FROM (SELECT authorId,
                            createdAt,
                            ROW_NUMBER() OVER(PARTITION BY authorId ORDER BY createdAt ASC) AS rang
                       FROM `krugi-prod-social`.posts AS t_1
              WHERE authorId IN (SELECT id AS authorId
                                   FROM `krugi-prod-social`.users AS users
                                  WHERE clubMemberStatus IN ('GUEST'))
               AND entityType = 'STORIES') AS t_1
             WHERE rang = 1) AS stories 
        LEFT JOIN
            (SELECT id AS user_id,
                    DATE_FORMAT(createdAt, '%Y-%m') AS cohort
               FROM `krugi-prod-social`.users AS users) AS cohorts
            ON stories.user_id = cohorts.user_id
    GROUP BY cohorts.cohort) AS stories
    ON users.cohort = stories.cohort
    LEFT JOIN
    -- формирование таблицы с кол-вом сгенерировавших постов
    (SELECT cohorts.cohort AS cohort,
            COUNT(posts.user_id) AS posts    
       FROM (SELECT authorId AS user_id
               FROM (SELECT authorId,
                            createdAt,
                            ROW_NUMBER() OVER(PARTITION BY authorId ORDER BY createdAt ASC) AS rang
                       FROM `krugi-prod-social`.posts AS t_1
              WHERE authorId IN (SELECT id AS authorId
                                   FROM `krugi-prod-social`.users AS users
                                  WHERE clubMemberStatus IN ('GUEST'))
               AND entityType = 'POST') AS t_1
             WHERE rang = 1) AS posts 
        LEFT JOIN
            (SELECT id AS user_id,
                    DATE_FORMAT(createdAt, '%Y-%m') AS cohort
               FROM `krugi-prod-social`.users AS users) AS cohorts
            ON posts.user_id = cohorts.user_id
    GROUP BY cohorts.cohort) AS posts
    ON users.cohort = posts.cohort
    LEFT JOIN
    -- формирование таблицы с кол-вом сгенерировавших комментариев
    (SELECT cohorts.cohort AS cohort,
            COUNT(comments.user_id) AS comments    
       FROM (SELECT authorId AS user_id
               FROM (SELECT authorId,
                            createdAt,
                            ROW_NUMBER() OVER(PARTITION BY authorId ORDER BY createdAt ASC) AS rang
                       FROM `krugi-prod-social`.posts AS t_1
              WHERE authorId IN (SELECT id AS authorId
                                   FROM `krugi-prod-social`.users AS users
                                  WHERE clubMemberStatus IN ('GUEST'))
               AND entityType = 'POST') AS t_1
             WHERE rang = 1) AS comments 
        LEFT JOIN
            (SELECT id AS user_id,
                    DATE_FORMAT(createdAt, '%Y-%m') AS cohort
               FROM `krugi-prod-social`.users AS users) AS cohorts
            ON comments.user_id = cohorts.user_id
    GROUP BY cohorts.cohort) AS comments
    ON users.cohort = comments.cohort
    LEFT JOIN
    -- формирование таблицы с кол-вом сгенерировавших лайв-трансляции
    (SELECT cohorts.cohort AS cohort,
            COUNT(lives.user_id) AS lives    
       FROM (SELECT authorId AS user_id
               FROM (SELECT authorId,
                            createdAt,
                            ROW_NUMBER() OVER(PARTITION BY authorId ORDER BY createdAt ASC) AS rang
                       FROM `krugi-prod-social`.posts AS t_1
              WHERE authorId IN (SELECT id AS authorId
                                   FROM `krugi-prod-social`.users AS users
                                  WHERE clubMemberStatus IN ('GUEST'))
               AND entityType = 'LIVE') AS t_1
             WHERE rang = 1) AS lives 
        LEFT JOIN
            (SELECT id AS user_id,
                    DATE_FORMAT(createdAt, '%Y-%m') AS cohort
               FROM `krugi-prod-social`.users AS users) AS cohorts
            ON lives.user_id = cohorts.user_id
    GROUP BY cohorts.cohort) AS lives
    ON users.cohort = lives.cohort
    LEFT JOIN
    -- формирование таблицы с кол-вом созданных чатов
    (SELECT cohort,
            COUNT(chat_id) AS chats
       FROM (SELECT chats_admins.chat_id AS chat_id,
                    cohort.cohort AS cohort
              FROM (SELECT chats.chat_id AS chat_id,
                           chats_admin.user_id AS user_id
                      FROM (SELECT chat_id
                              FROM (SELECT id AS chat_id,
                                           createdAt,
                                           ROW_NUMBER() OVER(PARTITION BY communityId ORDER BY createdAt ASC) AS rang
                                     FROM `krugi-prod-social`.users_chats
                                    WHERE communityId IS NOT NULL) AS t_1
                            WHERE rang = 1) AS chats
                LEFT JOIN
                  (SELECT chatId AS chat_id,
                          userId AS user_id
                     FROM `krugi-prod-social`.users_chats_admins
                    WHERE userId IN (SELECT id AS userId
                                       FROM `krugi-prod-social`.users AS users
                                      WHERE clubMemberStatus IN ('GUEST'))) AS chats_admin
                       ON chats.chat_id = chats_admin.chat_id
                    WHERE chats_admin.user_id IS NOT NULL) AS chats_admins
                LEFT JOIN
                (SELECT id AS user_id,
                        DATE_FORMAT(createdAt, '%Y-%m') AS cohort
                FROM `krugi-prod-social`.users) AS cohort
                ON chats_admins.user_id = cohort.user_id
                ) AS t_2
                GROUP BY cohort) AS chats_all
    ON users.cohort = chats_all.cohort
    -- формирование таблицы с кол-вом ставших участниками чата
    LEFT JOIN
    (SELECT cohort.cohort AS cohort,
            COUNT(members_chats.user_id) AS chat_members
       FROM (SELECT user_id
               FROM (SELECT userId AS user_id,
                            createdAt,
                            ROW_NUMBER() OVER(PARTITION BY userId ORDER BY createdAt ASC) AS rang
                       FROM `krugi-prod-social`.users_chats_members
                       WHERE userId IN (SELECT id AS userId
                                          FROM `krugi-prod-social`.users AS users
                                         WHERE clubMemberStatus IN ('GUEST'))) AS t_1
              WHERE rang = 1) AS members_chats
          LEFT JOIN
          (SELECT id AS user_id,
                        DATE_FORMAT(createdAt, '%Y-%m') AS cohort
             FROM `krugi-prod-social`.users) AS cohort
          ON members_chats.user_id = cohort.user_id
          GROUP BY cohort.cohort) AS chat_members
    ON users.cohort = chat_members.cohort
    -- формирование таблицы с кол-вом просмотревших посты
    LEFT JOIN
    (SELECT cohorts.cohort,
            COUNT(posts_users.user_id) AS post_view
      FROM (SELECT user_id
              FROM (SELECT userId AS user_id,
                           id AS post_id,
                           createdAt,
                           ROW_NUMBER() OVER(PARTITION BY userId ORDER BY createdAt ASC) AS rang
                     FROM `krugi-prod-social`.posts_views
                    WHERE userId IN (SELECT id AS userId
                                       FROM `krugi-prod-social`.users AS users
                                      WHERE clubMemberStatus IN ('GUEST'))) AS t_1
            WHERE rang = 1) AS posts_users
           LEFT JOIN
           (SELECT id AS user_id,
                   DATE_FORMAT(createdAt, '%Y-%m') AS cohort
              FROM `krugi-prod-social`.users AS users) AS cohorts
           ON posts_users.user_id = cohorts.user_id
    GROUP BY cohorts.cohort) AS post_users
    ON users.cohort = post_users.cohort
    -- формирование таблицы с кол-вом лайкнувших посты
    LEFT JOIN
    (SELECT cohorts.cohort,
            COUNT(posts_users.user_id) AS post_like
      FROM (SELECT user_id
              FROM (SELECT authorId AS user_id,
                           id AS like_id,
                           createdAt,
                           ROW_NUMBER() OVER(PARTITION BY authorId ORDER BY createdAt ASC) AS rang
                     FROM `krugi-prod-social`.posts_likes
                    WHERE authorId IN (SELECT id AS authorId
                                       FROM `krugi-prod-social`.users AS users
                                      WHERE clubMemberStatus IN ('GUEST'))) AS t_1
            WHERE rang = 1) AS posts_users
           LEFT JOIN
           (SELECT id AS user_id,
                   DATE_FORMAT(createdAt, '%Y-%m') AS cohort
              FROM `krugi-prod-social`.users AS users) AS cohorts
           ON posts_users.user_id = cohorts.user_id
    GROUP BY cohorts.cohort) AS posts_like
    ON users.cohort = posts_like.cohort