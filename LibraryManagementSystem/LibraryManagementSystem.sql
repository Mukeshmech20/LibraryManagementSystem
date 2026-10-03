-- Library Management Database System
-- Project 2
-- MySQL

DROP DATABASE IF EXISTS LibraryManagementSystem;

CREATE DATABASE LibraryManagementSystem;

USE LibraryManagementSystem;


-- 1. Users Table

CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15)
);


-- 2. Books Table

CREATE TABLE Books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(150) NOT NULL,
    author VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    quantity INT NOT NULL,
    available_quantity INT NOT NULL
);


-- 3. Transactions Table

CREATE TABLE Transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    book_id INT NOT NULL,
    issue_date DATE NOT NULL,
    return_date DATE,
    status VARCHAR(20) DEFAULT 'Issued',

    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (book_id) REFERENCES Books(book_id)
);


-- 4. Insert Users

INSERT INTO Users (name, email, phone)
VALUES
('Mukesh', 'mukesh@gmail.com', '9876543210'),
('Arun', 'arun@gmail.com', '9876543211'),
('Priya', 'priya@gmail.com', '9876543212'),
('Karthik', 'karthik@gmail.com', '9876543213'),
('Divya', 'divya@gmail.com', '9876543214');


-- 5. Insert Books

INSERT INTO Books (title, author, category, quantity, available_quantity)
VALUES
('The Alchemist', 'Paulo Coelho', 'Fiction', 5, 5),
('Atomic Habits', 'James Clear', 'Self Help', 4, 4),
('Clean Code', 'Robert C. Martin', 'Programming', 3, 3),
('Harry Potter', 'J.K. Rowling', 'Fantasy', 6, 6),
('The Psychology of Money', 'Morgan Housel', 'Finance', 4, 4);


-- 6. Issue The Alchemist to Mukesh

INSERT INTO Transactions (user_id, book_id, issue_date, status)
VALUES (1, 1, CURDATE(), 'Issued');

UPDATE Books
SET available_quantity = available_quantity - 1
WHERE book_id = 1;


-- 7. Return The Alchemist

UPDATE Transactions
SET return_date = CURDATE(),
    status = 'Returned'
WHERE transaction_id = 1;

UPDATE Books
SET available_quantity = available_quantity + 1
WHERE book_id = 1;


-- 8. Issue Atomic Habits to Mukesh

INSERT INTO Transactions (user_id, book_id, issue_date, status)
VALUES (1, 2, CURDATE(), 'Issued');

UPDATE Books
SET available_quantity = available_quantity - 1
WHERE book_id = 2;


-- 9. Issue Clean Code to Arun

INSERT INTO Transactions (user_id, book_id, issue_date, status)
VALUES (2, 3, CURDATE(), 'Issued');

UPDATE Books
SET available_quantity = available_quantity - 1
WHERE book_id = 3;


-- 10. View Available Books

SELECT
    book_id,
    title,
    author,
    category,
    available_quantity
FROM Books
WHERE available_quantity > 0;


-- 11. View Currently Issued Books

SELECT
    t.transaction_id,
    u.name AS user_name,
    b.title AS book_title,
    t.issue_date,
    t.status
FROM Transactions t
JOIN Users u ON t.user_id = u.user_id
JOIN Books b ON t.book_id = b.book_id
WHERE t.status = 'Issued';


-- 12. View Complete Transaction History

SELECT
    t.transaction_id,
    u.name AS user_name,
    b.title AS book_title,
    t.issue_date,
    t.return_date,
    t.status
FROM Transactions t
JOIN Users u ON t.user_id = u.user_id
JOIN Books b ON t.book_id = b.book_id
ORDER BY t.transaction_id;


-- 13. User Borrowing Count

SELECT
    u.user_id,
    u.name AS user_name,
    COUNT(t.transaction_id) AS total_borrowed
FROM Users u
LEFT JOIN Transactions t
    ON u.user_id = t.user_id
GROUP BY u.user_id, u.name;


-- 14. Library Summary

SELECT
    COUNT(*) AS total_book_titles,
    SUM(quantity) AS total_copies,
    SUM(available_quantity) AS available_copies,
    SUM(quantity - available_quantity) AS issued_copies
FROM Books;


-- 15. Overdue Books

SELECT
    t.transaction_id,
    u.name AS user_name,
    b.title AS book_title,
    t.issue_date,
    DATEDIFF(CURDATE(), t.issue_date) AS days_borrowed,
    t.status
FROM Transactions t
JOIN Users u ON t.user_id = u.user_id
JOIN Books b ON t.book_id = b.book_id
WHERE t.status = 'Issued'
AND DATEDIFF(CURDATE(), t.issue_date) > 14;