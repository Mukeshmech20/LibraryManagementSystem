# Library Management Database System – REDO

## Project Overview

The Library Management Database System is a MySQL-based project designed to manage library books, users, and book issue and return operations efficiently.

## Technologies Used

* MySQL
* SQL
* MySQL Workbench

## Database Tables

### 1. Users

Stores library user details, including user ID, name, email, and phone number.

### 2. Books

Stores book information, including title, author, category, total quantity, and available quantity.

### 3. Transactions

Tracks book issue and return details, including user ID, book ID, issue date, due date, return date, and transaction status.

## Key Features

* User and book record management
* Primary key and foreign key constraints
* Data validation using CHECK constraints
* Book availability validation before issuing
* Book issue and return operations using stored procedures
* Transaction handling with COMMIT and ROLLBACK
* Automatic 14-day due date calculation
* Overdue book reporting
* User borrowing summary
* Complete transaction history

## Stored Procedures

* `IssueBook`: Checks user existence and book availability before issuing a book.
* `ReturnBook`: Processes book returns and updates available book quantities.

## Reports

1. All books and availability
2. Currently issued books
3. Overdue books
4. User borrowing summary
5. Complete transaction history

## How to Run

1. Open MySQL Workbench.
2. Open the `library_management.sql` file.
3. Execute the SQL script in a MySQL environment.
4. Review the tables, stored procedures, and reporting queries.

## Project Objective

To demonstrate relational database design, SQL queries, data validation, stored procedures, transaction management, and library borrowing operations.
