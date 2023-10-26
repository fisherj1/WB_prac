/*=====================================================================================*/

-- Задание 1 (в этом задании я привел в пример 5 вариантов запросов: a, b, c, d, e) 

/* 
a)  Группируем user'ов по ИМЕЮЩИМСЯ возрастным категориям для каждого города.
В ответе будут ИМЕЮЩИЕСЯ в таблице возрастные категории и количество user'ов в таких категориях для 
каждого города.
*/

select count(age), age, city
from users
group by (city, age) order by age;

/* 
b)  Вариант, когда группируем по всем возможным возрастам от 0 до 100.
*/

SELECT 
  cities.city, 
  age_group.age, 
  count(users.age)
FROM (SELECT DISTINCT city FROM users) AS cities
CROSS JOIN generate_series(0, 100) AS age_group(age)
LEFT JOIN users ON cities.city = users.city AND age_group.age = users.age
GROUP BY cities.city, age_group.age
ORDER BY cities.city, age_group.age;

/* 
c)  Группируем по ИМЕЮЩИМСЯ В ТАБЛИЦЕ возрастным категориям для каждого город.
*/

SELECT city, 
       CASE 
           WHEN age < 21 THEN 'young'
           WHEN age >= 21 AND age < 50 THEN 'adult'
           ELSE 'old'
       END AS age_category,
       COUNT(*)
FROM users
GROUP BY city, age_category

/* 
d)  Вариант, когда считаем количество user'ов каждой возрастной категории для каждого города:
*/

SELECT city,
       COUNT(CASE WHEN age >= 0 AND age <= 20 THEN 1 END) AS young,
       COUNT(CASE WHEN age >= 21 AND age <= 49 THEN 1 END) AS adult,
       COUNT(CASE WHEN age >= 50 THEN 1 END) AS old
FROM users
GROUP BY city 
order by city;


/* 
e)  Используем подзапрос для разделения каждого user'a по категории возраста
   Для каждого города создаем три возрастных категории джойним с возрастами из подзапроса t2
*/
 
with t2 as (
SELECT city, 
       CASE 
           WHEN age < 21 THEN 'young'
           WHEN age >= 21 AND age < 50 THEN 'adjunt'
           ELSE 'old'
       END AS age_category
FROM users)

SELECT 
  cities.city, 
  groups.age_groups,
  count(t2.age_category)
FROM (select DISTINCT city from users) as cities
CROSS JOIN (VALUES ('young'), ('adjunt'), ('old')) AS groups(age_groups)
left join (select * from t2) as t2 on cities.city = t2.city and groups.age_groups = t2.age_category
GROUP by cities.city, groups.age_groups
order by cities.city, groups.age_groups;

/*==============================================================================================================*/

-- Задание 2

select 
  CAST(avg(price) as DEC(12,2)), 
  category 
from products
where products.name ILIKE '%hair%' OR products.name ILIKE '%home%' 
GROUP by (category);

/*==============================================================================================================*/

-- Задание 3
select 
	seller_id, 
	count(category) as total_categ, 
  round(avg(rating), 2) as avg_rating, 
  sum(revenue) as total_revenue, 
  CASE
    when (sum(revenue) >= 50000 and count(category) >= 2)
      THEN 'rich'
      ELSE 'poor'
  END as seller_type
from sellers 
WHERE category <> 'Bedding'
GROUP by (seller_id)
order by seller_id;

/*==============================================================================================================*/

-- Задание 4
-- Обернем запрос из задания 3 в подзапрос t3 для дальнейшего seller'ов c seller_type = 'poor'
with t3 as (
select 
	seller_id, 
	count(category) as total_categ, 
  round(avg(rating), 2) as avg_rating, 
  sum(revenue) as total_revenue, 
  CASE
    when (sum(revenue) >= 50000 and count(category) >= 2)
      THEN 'rich'
      ELSE 'poor'
  END as seller_type
from sellers 
WHERE category <> 'Bedding'
GROUP by (seller_id)
)

-- Выберем seller'ов, которые в подзапросе t3 имеют seller_type = 'poor'
-- для каждого из них считаем количетсво полных месяцев со дня ПЕРВОЙ регистрации
-- (из всех date_reg выбираем ПЕРВОЕ ("минимальное") для конкретного seller_id) 
-- разницу max(delivery_days) - min(delivery_days) среди этих выбранных seller'ов

select 
	DISTINCT seller_id, 
    div(date_part('day', (now()- min(TO_DATE(date_reg, 'DD/MM/YYYY'))))::INT, 30) as month_from_registration,
    (select  
     	max(delivery_days) - min(delivery_days)
     from sellers 
     where seller_id in (select seller_id from t3 where t3.seller_type = 'poor')) as max_delivery_difference
from sellers
where seller_id in (select seller_id from t3 where t3.seller_type = 'poor') 
group by seller_id
order by 1;

/*==============================================================================================================*/

-- Задание 5

-- В подзапросе считаем количество категорий и выручку за 2022 год для каждого seller'a
with t1 as (
  select 
    seller_id,
    count(category) as total_categ, 
    sum(CASE 
          WHEN RIGHT(date, 4) = '2022' THEN revenue
          ELSE 0 
        END) as total_revenue
  from sellers
  GROUP by (seller_id)
)

-- Используем подзапрос для выбора seller_id таких, чтобы они продавали только 2 категории товаров 
-- и чтобы выручка за 2022 год была больше 75000,
-- группируем таких по категории твоаровю
select 
	seller_id, 
    string_agg(category, '-' ORDER BY category) as category_pair
from sellers 
where seller_id in (
  		                select seller_id 
  					          from t1 
  					          where total_categ = 2 AND total_revenue > 75000
					        )
GROUP by (seller_id)
order by seller_id;

/*==============================================================================================================*/