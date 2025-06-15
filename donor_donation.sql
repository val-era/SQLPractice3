--В этом кейсе вы будете работать с данными проекта DonorSearch. Цель проекта — мотивировать людей становиться донорами и делать регулярные донации. 
	--Для этого важно понимать, какие факторы влияют на активность доноров и какими могут быть стратегии для их мотивации.

-- 1) Определить регионы с наибольшим количеством зарегистрированных доноров
SELECT region,
       COUNT(id) AS donor_count
FROM donorsearch.user_anon_data
GROUP BY region
ORDER BY donor_count DESC
LIMIT 5;

region                               | donor_count
-------------------------------------|-------------
                                     | 100574
Россия, Москва                       | 37819
Россия, Санкт-Петербург              | 13137
Россия, Татарстан, Казань            | 6610
Украина, Киевская область, Киев      | 3541

-- Выборка топ городов с наивысшим кол-вом доноров и донаций в клиниках

SELECT 
	city,
	SUM(donor_count) AS donor_count_city,
	SUM(donation_count) AS donation_count_city
FROM donorsearch.bs_data
GROUP BY city
ORDER BY donor_count_city DESC, donation_count_city DESC
LIMIT 10;


city           |donor_count_city|donation_count_city|
---------------+----------------+-------------------+
Москва         |            9142|              42063|
Санкт-Петербург|            4318|              14608|
Казань         |            2784|              16268|
Уфа            |            1350|               6875|
Екатеринбург   |            1046|               5014|
Новосибирск    |             956|               3057|
Краснодар      |             853|               2615|
Красноярск     |             797|               5450|
Ростов-на-Дону |             695|               2484|
Ярославль      |             648|               3401|


-- Выборка общего кол-ва донаций за 2022 и 2023 год

SELECT
	EXTRACT(YEAR FROM donation_date::timestamp) AS donation_year,
	COUNT(id) AS donation_count
FROM donorsearch.donation_anon
GROUP BY donation_year
HAVING EXTRACT(YEAR FROM donation_date::timestamp) IN (2022, 2023);

donation_year|donation_count|
-------------+--------------+
         2022|         34153|
         2023|         28119|
     
         
-- Динамика донаций по месяцам за 2022 и 2023 год

SELECT
	DATE_TRUNC('month', donation_date::timestamp) AS donation_month,
	COUNT(id) AS donation_count
FROM donorsearch.donation_anon
GROUP BY donation_month
HAVING EXTRACT(YEAR FROM DATE_TRUNC('month', donation_date::timestamp)) IN (2022, 2023);

donation_month          |donation_count|
------------------------+--------------+
2022-01-01 00:00:00.000 |          1977|
2022-02-01 00:00:00.000 |          2109|
2022-03-01 00:00:00.000 |          3002|
2022-04-01 00:00:00.000 |          3223|
2022-05-01 00:00:00.000 |          2414|
2022-06-01 00:00:00.000 |          2792|
2022-07-01 00:00:00.000 |          2836|
2022-08-01 00:00:00.000 |          2987|
2022-09-01 00:00:00.000 |          3089|
2022-10-01 00:00:00.000 |          3265|
2022-11-01 00:00:00.000 |          3156|
2022-12-01 00:00:00.000 |          3303|
2023-01-01 00:00:00.000 |          2795|
2023-02-01 00:00:00.000 |          3056|
2023-03-01 00:00:00.000 |          3523|
2023-04-01 00:00:00.000 |          2951|
2023-05-01 00:00:00.000 |          2568|
2023-06-01 00:00:00.000 |          2651|
2023-07-01 00:00:00.000 |          2276|
2023-08-01 00:00:00.000 |          2433|
2023-09-01 00:00:00.000 |          2240|
2023-10-01 00:00:00.000 |          2117|
2023-11-01 00:00:00.000 |          1509|

-- Выборка самых активных доноров с подтвержденными донациями

SELECT
	user_id,
	COUNT(id) AS donation_count
FROM donorsearch.donation_anon
WHERE confirmation = 'true'
GROUP BY user_id
ORDER BY donation_count DESC
LIMIT 10;

user_id|donation_count|
-------+--------------+
 235391|           361|
 201521|           236|
 211970|           236|
 132946|           227|
 216353|           217|
  53912|           216|
 233686|           215|
 204073|           213|
 267054|           209|
 229012|           204|
 
 
 -- Выборка самых активных доноров с подтвержденными донациями и определение влияния платных донаций
 
 WITH 
	money_donation AS(
		SELECT
			user_id,
			COUNT(id) AS money_donation_count
		FROM donorsearch.donation_anon
		WHERE confirmation = 'true' AND donation_type = 'Платно'
		GROUP BY user_id
),
	free_donation AS(
		SELECT
			user_id,
			COUNT(id) AS free_donation_count
		FROM donorsearch.donation_anon
		WHERE confirmation = 'true' AND donation_type = 'Безвозмездно'
		GROUP BY user_id
),
	total_donation AS(
		SELECT
			user_id,
			COUNT(id) AS total_donation_count
		FROM donorsearch.donation_anon
		WHERE confirmation = 'true'
		GROUP BY user_id
)
SELECT 
	user_id,
	total_donation_count,
	free_donation_count,
	money_donation_count
FROM total_donation
LEFT JOIN free_donation USING(user_id)
LEFT JOIN money_donation USING(user_id)
ORDER BY total_donation_count DESC
LIMIT 10;

user_id|total_donation_count|free_donation_count|money_donation_count|
-------+--------------------+-------------------+--------------------+
 235391|                 361|                264|                  97|
 201521|                 236|                 60|                 176|
 211970|                 236|                236|                    |
 132946|                 227|                227|                    |
 216353|                 217|                170|                  47|
  53912|                 216|                179|                  37|
 233686|                 215|                215|                    |
 204073|                 213|                213|                    |
 267054|                 209|                209|                    |
 229012|                 204|                 54|                 150|


 -- Оценка влияния системы бонусов по топу активных пользователей сайта
 
 SELECT 
	id,
	confirmed_donations,
	COALESCE(donations_before_registration,0) AS donations_before_registrations,
	confirmed_donations-COALESCE(donations_before_registration,0) AS donatios_on_site,
	count_bonuses_taken
FROM donorsearch.user_anon_data
WHERE id IN (SELECT id 
			 FROM donorsearch.user_anon_data 
			 WHERE EXTRACT(YEAR FROM last_activity::TIMESTAMP) >= 2022)
ORDER BY confirmed_donations DESC
LIMIT 10

id    |confirmed_donations|donations_before_registrations|donatios_on_site|count_bonuses_taken|
------+-------------------+------------------------------+----------------+-------------------+
235391|                361|                             0|             361|                  0|
273317|                257|                           190|              67|                  0|
201521|                236|                           200|              36|                  7|
211970|                236|                             0|             236|                  0|
132946|                227|                             0|             227|                  0|
 53912|                217|                           190|              27|                  5|
216353|                216|                           185|              31|                  0|
233686|                215|                             0|             215|                  0|
204073|                213|                           200|              13|                  0|
267054|                209|                           209|               0|                  0|


-- Оценка влияния системы бонусов на всех пользователей

SELECT 
	SUM(confirmed_donations) AS confirmed_donations,
	SUM(COALESCE(donations_before_registration,0)) AS donations_before_registration,
	SUM(confirmed_donations)-SUM(donations_before_registration) AS donatios_on_site,
	SUM(count_bonuses_taken) AS count_bonuses_taken
FROM donorsearch.user_anon_data;

confirmed_donations|donations_before_registration|donatios_on_site|count_bonuses_taken|
-------------------+-----------------------------+----------------+-------------------+
             222877|                       177491|           45386|              21108|
             

-- Оценка, как система бонусов влияет на зарегистрированные в системе донации.
WITH donor_activity AS
  (SELECT u.id,
          u.confirmed_donations,
          COALESCE(b.user_bonus_count, 0) AS user_bonus_count
   FROM donorsearch.user_anon_data u
   LEFT JOIN donorsearch.user_anon_bonus b ON u.id = b.user_id)
SELECT CASE
           WHEN user_bonus_count > 0 THEN 'Получили бонусы'
           ELSE 'Не получали бонусы'
       END AS статус_бонусов,
       COUNT(id) AS количество_доноров,
       AVG(confirmed_donations) AS среднее_количество_донаций
FROM donor_activity
GROUP BY статус_бонусов;

статус_бонусов     | количество_доноров | среднее_количество_донаций 
-------------------|--------------------|----------------------------
Получили бонусы    | 21108              | 13.90
Не получали бонусы | 256491             | 0.53        
             
             

-- Изучение пользователей по каналам и их метрики

SELECT CASE
           WHEN autho_vk THEN 'ВКонтакте'
           WHEN autho_ok THEN 'Одноклассники'
           WHEN autho_tg THEN 'Telegram'
           WHEN autho_yandex THEN 'Яндекс'
           WHEN autho_google THEN 'Google'
           ELSE 'Без авторизации через соцсети'
       END AS социальная_сеть,
       COUNT(id) AS количество_доноров,
       ROUND(AVG(confirmed_donations),2) AS среднее_количество_донаций
FROM donorsearch.user_anon_data
GROUP BY социальная_сеть;

социальная_сеть              |количество_доноров|среднее_количество_донаций|
-----------------------------+------------------+--------------------------+
Google                       |             14292|                      1.08|
Telegram                     |               481|                      1.17|
Без авторизации через соцсети|            113266|                      0.71|
ВКонтакте                    |            127254|                      0.91|
Одноклассники                |              6410|                      0.56|
Яндекс                       |              4133|                      1.73|
      
-- Сравнение активности однократных доноров с активностью повторных доноров
      
SELECT
	COUNT(id) AS users,
	SUM(confirmed_donations) AS confirmed_donations,
	ROUND(AVG(confirmed_donations),2) AS avg_confirmed_donations,
	ROUND(AVG(count_bonuses_taken),2) AS bonus_using,
	'ONE DONATIONS' AS counting
FROM donorsearch.user_anon_data
WHERE confirmed_donations = 1
GROUP BY counting
UNION
SELECT
	COUNT(id) AS users,
	SUM(confirmed_donations) AS confirmed_donations,
	ROUND(AVG(confirmed_donations),2) AS avg_confirmed_donations,
	ROUND(AVG(count_bonuses_taken),2) AS bonus_using,
	'MANY DONATIONS' AS counting
FROM donorsearch.user_anon_data
WHERE confirmed_donations > 1
GROUP BY counting

users|confirmed_donations|avg_confirmed_donations|bonus_using|counting      |
-----+-------------------+-----------------------+-----------+--------------+
19127|             203367|                  10.63|       0.83|MANY DONATIONS|
19510|              19510|                   1.00|       0.26|ONE DONATIONS |


-- Сравнение с добавлением платных донаций
WITH
	money_trans AS(
		SELECT
			user_id,
			COUNT(id) AS money_donat
		FROM donorsearch.donation_anon
		WHERE donation_type = 'Платно'
		GROUP BY user_id
	)
SELECT
	COUNT(id) AS users,
	SUM(confirmed_donations) AS confirmed_donations,
	ROUND(AVG(confirmed_donations),2) AS avg_confirmed_donations,
	ROUND(AVG(count_bonuses_taken),2) AS bonus_using,
	SUM(money_donat) AS donation_from_money,
	'ONE DONATIONS' AS counting
FROM donorsearch.user_anon_data AS uad
LEFT JOIN money_trans AS mt ON uad.id = mt.user_id
WHERE confirmed_donations = 1
GROUP BY counting
UNION
SELECT
	COUNT(id) AS users,
	SUM(confirmed_donations) AS confirmed_donations,
	ROUND(AVG(confirmed_donations),2) AS avg_confirmed_donations,
	ROUND(AVG(count_bonuses_taken),2) AS bonus_using,
	SUM(money_donat) AS donation_from_money,
	'MANY DONATIONS' AS counting
FROM donorsearch.user_anon_data AS uad
LEFT JOIN money_trans AS mt ON uad.id = mt.user_id
WHERE confirmed_donations > 1
GROUP BY counting

users|confirmed_donations|avg_confirmed_donations|bonus_using|donation_from_money|counting      |
-----+-------------------+-----------------------+-----------+-------------------+--------------+
19127|             203367|                  10.63|       0.83|              13392|MANY DONATIONS|
19510|              19510|                   1.00|       0.26|               2543|ONE DONATIONS |


--Анализ эффективности планирования донаций
WITH planned_donations AS (
  SELECT DISTINCT user_id, donation_date, donation_type
  FROM donorsearch.donation_plan
),
actual_donations AS (
  SELECT DISTINCT user_id, donation_date
  FROM donorsearch.donation_anon
),
planned_vs_actual AS (
  SELECT
    pd.user_id,
    pd.donation_date AS planned_date,
    pd.donation_type,
    CASE WHEN ad.user_id IS NOT NULL THEN 1 ELSE 0 END AS completed
  FROM planned_donations pd
  LEFT JOIN actual_donations ad ON pd.user_id = ad.user_id AND pd.donation_date = ad.donation_date
)
SELECT
  donation_type,
  COUNT(*) AS total_planned_donations,
  SUM(completed) AS completed_donations,
  ROUND(SUM(completed) * 100.0 / COUNT(*), 2) AS completion_rate
FROM planned_vs_actual
GROUP BY donation_type;

    
|donation_type|total_planned_donations|completed_donations|completion_rate|
|-------------|-----------------------|-------------------|---------------|
|Безвозмездно |          22903        |        4950       |      21.61    |
|Платно       |          3299         |        429        |      13.00    |

-- Анализ мероприятий по длительности

SELECT
	CASE
		WHEN EXTRACT(DAY FROM AGE(event_end::timestamp, event_begin::timestamp)) = 1
			THEN '1 день'
		WHEN EXTRACT(DAY FROM AGE(event_end::timestamp, event_begin::timestamp)) = 2
			THEN '2 дня'
		WHEN EXTRACT(DAY FROM AGE(event_end::timestamp, event_begin::timestamp)) = 3
			THEN '3 дня'
		WHEN EXTRACT(DAY FROM AGE(event_end::timestamp, event_begin::timestamp)) > 3
			THEN 'Более 3-х дней'
		ELSE 'Меньше дня'
	END AS Длительность_мероприятия,
	COUNT(id) AS Количество_мероприятий,
	ROUND(AVG(reg_count),2) AS Среднее_регистраций,
	MIN(reg_count) AS Минимум_регистраций,
	MAX(reg_count) AS Максимум_регистраций
FROM donorsearch.events
GROUP BY Длительность_мероприятия
ORDER BY Длительность_мероприятия

Длительность_мероприятия|Количество_мероприятий|Среднее_регистраций|Минимум_регистраций|Максимум_регистраций|
------------------------+----------------------+-------------------+-------------------+--------------------+
1 день                  |                   111|               1.60|                  0|                  91|
2 дня                   |                    38|               0.11|                  0|                   3|
3 дня                   |                    23|               0.74|                  0|                   8|
Более 3-х дней          |                    80|               0.54|                  0|                  21|
Меньше дня              |                  1284|               2.27|                  0|                  99|

-- Анализ топ мероприятий

SELECT
	city AS Город,
	id AS Мероприятие,
	EXTRACT(DAY FROM AGE(event_end::timestamp, event_begin::timestamp)) AS Длительность_дней,
	reg_count AS Регистраций
FROM donorsearch.events
ORDER BY reg_count DESC, Длительность_дней DESC, city DESC
LIMIT 10;

Город                         |Мероприятие|Длительность_дней|Регистраций|
------------------------------+-----------+-----------------+-----------+
Россия, Татарстан, Альметьевск|       1676|                0|         99|
Россия, Татарстан, Альметьевск|       1278|                0|         99|
Россия, Татарстан, Казань     |       1594|                0|         98|
Россия,  Москва               |       1624|                0|         95|
Россия,  Москва               |       1561|                1|         91|
Россия, Татарстан, Казань     |       1583|                0|         83|
Россия, Татарстан, Казань     |       1184|                0|         74|
Россия,  Москва               |       1623|                0|         71|
Россия, Татарстан, Казань     |        586|                0|         67|
Россия,  Москва               |        822|                0|         66|

-- Анализ топ организаторов
WITH gr AS(
    SELECT
        event_id,
        COUNT(DISTINCT donor_id) AS unique_donors,
        AVG(donation_count) AS avg_donations
    FROM donorsearch.user_donation
    GROUP BY event_id
)
SELECT
    e.organization_id,
    e.city,
    COUNT(DISTINCT e.id) AS Мероприятий,
    SUM(e.reg_count) AS Регистраций,
    SUM(gr.unique_donors) AS Доноров,
    AVG(gr.avg_donations) AS Среднее_донаций
FROM donorsearch.events AS e
JOIN gr ON e.id = gr.event_id
GROUP BY e.organization_id, e.city
ORDER BY Мероприятий DESC, Регистраций DESC
LIMIT 10

organization_id|city                               |Мероприятий|Регистраций|Доноров|Среднее_донаций        |
---------------+-----------------------------------+-----------+-----------+-------+-----------------------+
            558|Россия, Татарстан, Казань          |         28|        387|    387|     8.0914048576904810|
              5|Россия, Татарстан, Казань          |         12|        517|    517| 4.84800097860842439167|
            146|Россия, Татарстан, Набережные Челны|         10|        158|    158| 1.15752525252525253111|
             36|Россия, Татарстан, Альметьевск     |          8|        438|    438| 1.57378989848505907633|
            331|Россия, Татарстан, Набережные Челны|          6|        161|    161| 0.38420015770580725794|
            557|Россия, Татарстан, Казань          |          6|         46|     46|    12.8558201058201058|
             83|Россия, Карелия, Петрозаводск      |          6|         28|     28| 0.00000000000000000000|
             25|Россия,  Москва                    |          5|        165|    165| 0.55304092459264873915|
            537|Россия, Татарстан, Казань          |          5|         63|     63|12.77222222222222222000|
            267|Россия, Татарстан, Нижнекамск      |          5|         48|     48| 1.71969696969696969333|
