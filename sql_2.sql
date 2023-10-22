-- Создание таблицы users
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    birth_date DATE NOT NULL,
    sex VARCHAR(6) NOT NULL CHECK(sex = 'male' OR sex = 'female'),
    age SMALLINT CHECK (age > 0)
);

-- Создание таблицы items
CREATE TABLE items (
    item_id SERIAL PRIMARY KEY,
    description VARCHAR(255) NOT NULL,
    price NUMERIC NOT NULL CHECK (price >= 0),
    category VARCHAR(50) NOT NULL
);

-- Создание таблицы ratings
CREATE TABLE ratings (
    item_id INT,
    user_id INT,
    review VARCHAR(255),
    rating SMALLINT CHECK (rating >= 0 AND rating <= 5),
    FOREIGN KEY (item_id) REFERENCES items(item_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

INSERT INTO users(birth_date, sex)
SELECT
       (DATE '1990-01-01' + INTERVAL '1 day' * random() * 7300) ::DATE AS birth_date,
       CASE WHEN random() < 0.5 THEN 'male' ELSE 'female' END AS sex
FROM generate_series(1, 20);

UPDATE users
  SET age = EXTRACT(YEAR FROM age(birth_date));
  

INSERT INTO items (description, price, category)
VALUES
    ('headphones', 10.95, 'electronics'),
    ('mouse', 4.50, 'electronics'),
    ('watch', 20.50, 'electronics'),
    ('laptop', 899.90, 'electronics'),
    ('lamp', 12.99, 'electronics'),
    ('pot', 8.40, 'dishes'),
    ('frying pan', 9.40, 'dishes'),
    ('plate red', 3.90, 'dishes'),
    ('plate green', 3.90, 'dishes'),
    ('plate yellow', 3.90, 'dishes'),
    ('fork', 2.75, 'dishes'),
    ('spoon', 2.75, 'dishes'),
    ('pen', 0.5, 'chancellery'),
    ('paper', 8.40, 'chancellery'),
    ('copybook', 0.90, 'chancellery'),
    ('pencil box', 1.34, 'chancellery'),
    ('compass', 3.45, 'chancellery'),
    ('milk', 1.40, 'products'),
    ('fish', 3.78, 'products'),
    ('meat', 3.04, 'products');
    
INSERT INTO ratings (item_id, user_id, review, rating)
SELECT 
    items.item_id,
    users.user_id,
    CASE floor(random() * 5)
           WHEN 0 THEN 'Top!'
           WHEN 1 THEN 'Good'
           WHEN 2 THEN 'Nice'
           WHEN 3 THEN 'BAD!'
           WHEN 4 THEN 'Very BAD'
    END as review,
    FLOOR(RANDOM() * 5 + 1) as rating
FROM users, items;
