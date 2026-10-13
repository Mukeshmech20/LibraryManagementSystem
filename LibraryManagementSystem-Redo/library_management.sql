-- =====================================================
-- PROJECT: Library Management Database System
-- VERSION: REDO
-- DATABASE: MySQL
-- =====================================================

-- Step 1: Create a separate database for the REDO project

CREATE DATABASE IF NOT EXISTS LibraryManagementSystemRedo;

USE LibraryManagementSystemRedo;


-- Step 2: Create Users table

CREATE TABLE IF NOT EXISTS Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(15),

    CONSTRAINT chk_user_name
        CHECK (CHAR_LENGTH(TRIM(name)) >= 2)
);


-- Step 3: Create Books table

CREATE TABLE IF NOT EXISTS Books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(150) NOT NULL,
    author VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    quantity INT NOT NULL DEFAULT 0,
    available_quantity INT NOT NULL DEFAULT 0,

    CONSTRAINT chk_book_quantity
        CHECK (quantity >= 0),

    CONSTRAINT chk_available_quantity
        CHECK (
            available_quantity >= 0
            AND available_quantity <= quantity
        )
);


-- Step 4: Create Transactions table

CREATE TABLE IF NOT EXISTS Transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    book_id INT NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE DEFAULT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Issued',

    CONSTRAINT fk_transaction_user
        FOREIGN KEY (user_id)
        REFERENCES Users(user_id),

    CONSTRAINT fk_transaction_book
        FOREIGN KEY (book_id)
        REFERENCES Books(book_id),

    CONSTRAINT chk_transaction_status
        CHECK (status IN ('Issued', 'Returned')),

    CONSTRAINT chk_transaction_dates
        CHECK (
            due_date >= issue_date
            AND (
                return_date IS NULL
                OR return_date >= issue_date
            )
        ),

    CONSTRAINT chk_transaction_return_status
        CHECK (
            (status = 'Issued' AND return_date IS NULL)
            OR
            (status = 'Returned' AND return_date IS NOT NULL)
        )
);
-- =====================================================
-- Step 5: Insert Sample Users
-- =====================================================

INSERT INTO Users (user_id, name, email, phone)
VALUES
(1, 'Mukesh', 'mukesh.redo@gmail.com', '9876543210'),
(2, 'Arun', 'arun.redo@gmail.com', '9876543211'),
(3, 'Priya', 'priya.redo@gmail.com', '9876543212'),
(4, 'Karthik', 'karthik.redo@gmail.com', '9876543213'),
(5, 'Divya', 'divya.redo@gmail.com', '9876543214')
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    phone = VALUES(phone);


-- =====================================================
-- Step 6: Insert Sample Books
-- =====================================================

INSERT INTO Books
    (book_id, title, author, category, quantity, available_quantity)
VALUES
(1, 'The Alchemist', 'Paulo Coelho', 'Fiction', 5, 5),
(2, 'Atomic Habits', 'James Clear', 'Self Help', 4, 4),
(3, 'Clean Code', 'Robert C. Martin', 'Programming', 3, 3),
(4, 'Harry Potter', 'J.K. Rowling', 'Fantasy', 6, 6),
(5, 'The Psychology of Money', 'Morgan Housel', 'Finance', 4, 4)
ON DUPLICATE KEY UPDATE
    title = VALUES(title),
    author = VALUES(author),
    category = VALUES(category),
    quantity = VALUES(quantity);

    
-- =====================================================
-- Step 7: Create IssueBook Procedure
-- =====================================================

DROP PROCEDURE IF EXISTS IssueBook;

DELIMITER //

CREATE PROCEDURE IssueBook(
    IN p_user_id INT,
    IN p_book_id INT
)
BEGIN
    DECLARE v_available INT DEFAULT NULL;
    DECLARE v_user_exists INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT COUNT(*)
    INTO v_user_exists
    FROM Users
    WHERE user_id = p_user_id;

    IF v_user_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User does not exist';
    END IF;

    SELECT available_quantity
    INTO v_available
    FROM Books
    WHERE book_id = p_book_id
    FOR UPDATE;

    IF v_available IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Book does not exist';
    END IF;

    IF v_available <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Book is not available';
    END IF;

    UPDATE Books
    SET available_quantity = available_quantity - 1
    WHERE book_id = p_book_id;

    INSERT INTO Transactions (
        user_id,
        book_id,
        issue_date,
        due_date,
        status
    )
    VALUES (
        p_user_id,
        p_book_id,
        CURDATE(),
        DATE_ADD(CURDATE(), INTERVAL 14 DAY),
        'Issued'
    );

    COMMIT;
END //

DELIMITER ;

-- =====================================================
-- Step 8: Create ReturnBook Procedure
-- =====================================================

DROP PROCEDURE IF EXISTS ReturnBook;

DELIMITER //

CREATE PROCEDURE ReturnBook(
    IN p_transaction_id INT
)
BEGIN
    DECLARE v_book_id INT DEFAULT NULL;
    DECLARE v_status VARCHAR(20) DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT book_id, status
    INTO v_book_id, v_status
    FROM Transactions
    WHERE transaction_id = p_transaction_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction does not exist';
    END IF;

    IF v_status <> 'Issued' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Book is already returned';
    END IF;

    UPDATE Transactions
    SET return_date = CURDATE(),
        status = 'Returned'
    WHERE transaction_id = p_transaction_id;

    UPDATE Books
    SET available_quantity = available_quantity + 1
    WHERE book_id = v_book_id;

    COMMIT;
END //

DELIMITER ;
-- =====================================================
-- Step 9: Reporting Queries
-- =====================================================

-- Report 1: All Books and Availability

SELECT
    book_id,
    title,
    author,
    quantity,
    available_quantity
FROM Books
ORDER BY title;


-- Report 2: Currently Issued Books

SELECT
    t.transaction_id,
    u.name AS user_name,
    b.title AS book_title,
    t.issue_date,
    t.due_date,
    t.status
FROM Transactions t
JOIN Users u ON t.user_id = u.user_id
JOIN Books b ON t.book_id = b.book_id
WHERE t.status = 'Issued'
ORDER BY t.issue_date DESC;


-- Report 3: Overdue Books

SELECT
    t.transaction_id,
    u.name AS user_name,
    b.title AS book_title,
    t.due_date,
    DATEDIFF(CURDATE(), t.due_date) AS days_overdue
FROM Transactions t
JOIN Users u ON t.user_id = u.user_id
JOIN Books b ON t.book_id = b.book_id
WHERE t.status = 'Issued'
  AND t.due_date < CURDATE()
ORDER BY t.due_date;


-- Report 4: User Borrowing Summary

SELECT
    u.user_id,
    u.name AS user_name,
    COUNT(t.transaction_id) AS total_borrowings,
    SUM(CASE WHEN t.status = 'Issued' THEN 1 ELSE 0 END)
        AS currently_issued,
    SUM(CASE WHEN t.status = 'Returned' THEN 1 ELSE 0 END)
        AS total_returned
FROM Users u
LEFT JOIN Transactions t ON u.user_id = t.user_id
GROUP BY u.user_id, u.name
ORDER BY u.user_id;


-- Report 5: Complete Transaction History

SELECT
    t.transaction_id,
    u.name AS user_name,
    b.title AS book_title,
    t.issue_date,
    t.due_date,
    t.return_date,
    t.status
FROM Transactions t
JOIN Users u ON t.user_id = u.user_id
JOIN Books b ON t.book_id = b.book_id
ORDER BY t.transaction_id;
