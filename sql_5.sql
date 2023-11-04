-- Задание 1

SELECT 
    c.customer_id, 
    c.name, 
    MAX(date(o.shipment_date) - date(o.order_date)) AS max_wait_time
FROM customers_new_3 c
JOIN orders_new_3 o ON c.customer_id = o.customer_id
where o.order_status = 'Approved'
GROUP BY c.customer_id, c.name
ORDER BY max_wait_time DESC, name
limit 1;





-- Задание 2
-- В подзапросе t1 для каждого customer'a формируем количество заказов, среднее время доставки и сумму заказов
-- В основном запросе выбираем клиентов с наибольшим количетсвом заказов

with t1 as (
    SELECT 
        c.customer_id,
        c.name, 
        COUNT(o.order_id) AS order_count, 
        AVG(date(o.shipment_date) - date(o.order_date)) AS average_delivery_time,
        SUM(order_ammount) AS amount
    FROM customers_new_3 c
    LEFT JOIN orders_new_3 o ON c.customer_id = o.customer_id
    GROUP BY C.customer_id, c.name
    ORDER BY order_count DESC
    )

select * from t1
where t1.order_count = (select max(order_count) from t1)
order by amount;

-- Задание 3
-- Запрос, естетсвенно, не оптимальный, но должен работать :)
-- Здесь для каждого customer'a из таблицы customers_new_3 находим:
-- а) количество заказов, с доставкой от 5 дней delayed_orders_count(с помощью первого LEFT JOIN)
-- б) количество отмененных заказов canceled_orders_count (с помощью второго LEFT JOIN) 
-- в) общую сумма заказов total_order_amount (с помощью третьего LEFT JOIN)
-- после этого в объединенной таблице выбираем только таких пользователей, для которых хотябы одно из колнок
-- delayed_orders_count или anceled_orders_count больше нуля
-- p.s. все, что в LEFT JOIN'ax собирается быть NULL, заменяем на нули с помощью COALESCE


SELECT 
    c.customer_id, 
    c.name, 
    COALESCE(delayed_orders.count, 0) AS delayed_orders_count, 
    COALESCE(canceled_orders.count, 0) AS canceled_orders_count, 
    COALESCE(total_order_amount.amount, 0) AS total_order_amount
FROM customers_new_3 c
LEFT JOIN (
    SELECT 
        customer_id, 
        COUNT(*) AS count
    FROM orders_new_3
    WHERE date(shipment_date) - date(order_date) > 5
    GROUP BY customer_id
    ) AS delayed_orders ON c.customer_id= delayed_orders.customer_id
LEFT JOIN (
    SELECT 
         customer_id, 
         COUNT(*) AS count
     FROM orders_new_3
     WHERE order_status = 'Cancel'
     GROUP BY customer_id
     ) AS canceled_orders ON c.customer_id = canceled_orders.customer_id
LEFT JOIN (
    SELECT 
        customer_id, 
        SUM(order_ammount) AS amount
    FROM orders_new_3
    GROUP BY customer_id
    ) AS total_order_amount ON c.customer_id = total_order_amount.customer_id
where COALESCE(canceled_orders.count, 0) > 0 or COALESCE(delayed_orders.count, 0) > 0
ORDER BY total_order_amount DESC;
    

-- Задание 4
-- Здесь используются три подзапроса:
-- t1) В этом запросе с помощью оператора JOIN объединяем таблицы orders_2 и products_3 по идентификатору продукта. 
-- Затем используем функцию SUM для вычисления общей суммы продаж (order_ammount) для каждой категории продуктов.

-- t2) В этом запросе сначала выполняется подзапрос, который вычисляет общую сумму продаж для каждого продукта
-- и с использованием оконной функции ROW_NUMBER() нумерует строки для каждой категории товара, упорядочивая их по убыванию total_sales.
-- Затем внешний запрос выбирает строки с rn = 1, то есть строки с наивысшими значениями total_sales для каждой категории.

-- t3) Этот запрос определит категорию продукта с наибольшей общей суммой продаж.

-- И в основном запросе осталось объединить все эти подзапросы, добавив колонку max_total_size_category с элементом из t3-подазпроса.

with 
t1 as (
    SELECT 
        p.product_category, 
        SUM(o.order_ammount) AS total_sales
    FROM orders_2 o
    JOIN products_3 p ON o.product_id = p.product_id
    GROUP BY p.product_category
    ORDER BY total_sales DESC
), 

t2 as (
    SELECT 
        product_category, 
        product_name, 
        total_sales
    FROM (
        SELECT 
            p.product_category, 
            p.product_name, 
            o.total_sales,
            ROW_NUMBER() OVER(PARTITION BY p.product_category ORDER BY o.total_sales DESC) AS rn
        FROM products_3 p
        JOIN (
            SELECT 
                product_id, 
                SUM(order_ammount) AS total_sales
            FROM orders_2
            GROUP BY product_id
        ) o ON p.product_id = o.product_id
    ) subquery
    WHERE rn = 1
),

t3 as (
    SELECT 
        product_category
    FROM t1 
    WHERE total_sales = (SELECT MAX(total_sales) FROM t1)
)


select t1.product_category, t1.total_sales, t2.product_name, (select product_category from t3) as max_total_size_category
from t1
join t2 on t1.product_category = t2.product_category
FULL join (
    SELECT 
        product_category
    FROM t1 
    WHERE total_sales = (SELECT MAX(total_sales) FROM t1)
    ) max_total_sales on max_total_sales.product_category = t1.product_category



