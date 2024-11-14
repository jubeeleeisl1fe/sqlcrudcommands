-- Database and Tables Setup

-- Drop existing database if it exists, then create a new one
DROP DATABASE IF EXISTS bank1;
CREATE DATABASE bank1;
USE bank1;

-- Drop tables if they exist
DROP TABLE IF EXISTS transaction_logs, employee_login, accounts, customers, account_closures, customer_login, loan;

-- Create customers table
CREATE TABLE customers (
    customer_id VARCHAR(12) PRIMARY KEY,
    branch_code VARCHAR(6) NOT NULL,
    full_name VARCHAR(50) NOT NULL,
    overdraft_limit DECIMAL(20, 2),
    email VARCHAR(100),                
    phone_number VARCHAR(15),          
    address VARCHAR(255),              
    date_of_birth DATE,                
    nationality VARCHAR(50),           
    fathers_name VARCHAR(50),
    UNIQUE KEY (branch_code, customer_id)
);

-- Create accounts table
CREATE TABLE accounts (
    account_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id VARCHAR(12),
    account_balance DECIMAL(18, 2) DEFAULT 0,
    account_status VARCHAR(15) NOT NULL CHECK (account_status IN ('Active', 'Dormant', 'Closed')),
    reason_for_closure VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Create transaction_logs table
CREATE TABLE transaction_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT,
    transaction_type VARCHAR(10),
    amount DECIMAL(18, 2),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- Create employee_login table
CREATE TABLE employee_login (
    employee_id VARCHAR(12) PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(50) NOT NULL,
    branch_code VARCHAR(6),
    position VARCHAR(40),
    phno VARCHAR(10)
);

-- Create loan table
CREATE TABLE loan (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id VARCHAR(12),
    loan_amount DECIMAL(18, 2),
    loan_to_be_paid DECIMAL(18, 2),
    interest DECIMAL(5, 2),
    duration INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Create account_closures table
CREATE TABLE account_closures (
    closure_id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT,
    closure_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason VARCHAR(50)
);

-- Create customer_login table
CREATE TABLE customer_login (
    customer_id VARCHAR(12) PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(50) NOT NULL,
    branch_code VARCHAR(6),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Stored Procedures

-- Drop procedures if they exist
DROP PROCEDURE IF EXISTS AddCustomer;
DROP PROCEDURE IF EXISTS AddAccount;
DROP PROCEDURE IF EXISTS DepositMoney;
DROP PROCEDURE IF EXISTS WithdrawMoney;

-- Procedure to add a new customer
CREATE PROCEDURE AddCustomer(
    IN customerID VARCHAR(12), 
    IN branchCode VARCHAR(6), 
    IN fullName VARCHAR(50), 
    IN overdraftLimit DECIMAL(20, 2)
)
BEGIN
    INSERT INTO customers (customer_id, branch_code, full_name, overdraft_limit)
    VALUES (customerID, branchCode, fullName, overdraftLimit);
END;

-- Procedure to add an account and loan
CREATE PROCEDURE AddAccount(
    IN custID VARCHAR(12), 
    IN accBalance DECIMAL(18, 2),
    IN accStatus VARCHAR(15), 
    IN loanAmount DECIMAL(18, 2), 
    IN interestRate DECIMAL(5, 2), 
    IN loanDuration INT
)
BEGIN
    DECLARE loanToBePaid DECIMAL(18, 2);
    SET loanToBePaid = loanAmount * (1 + interestRate / 100);
    INSERT INTO accounts (customer_id, account_balance, account_status)
    VALUES (custID, accBalance, accStatus);
    INSERT INTO loan (customer_id, loan_amount, loan_to_be_paid, interest, duration)
    VALUES (custID, loanAmount, loanToBePaid, interestRate, loanDuration);
END;

-- Procedure to deposit money
CREATE PROCEDURE DepositMoney(IN accID INT, IN depositAmount DECIMAL(18, 2))
BEGIN
    UPDATE accounts SET account_balance = account_balance + depositAmount WHERE account_id = accID;
    INSERT INTO transaction_logs (account_id, transaction_type, amount) VALUES (accID, 'Deposit', depositAmount);
END;

-- Procedure to withdraw money with insufficient funds check
CREATE PROCEDURE WithdrawMoney(IN accID INT, IN withdrawAmount DECIMAL(18, 2))
BEGIN
    DECLARE currentBalance DECIMAL(18, 2);
    SELECT account_balance INTO currentBalance FROM accounts WHERE account_id = accID;
    IF currentBalance >= withdrawAmount THEN
        UPDATE accounts SET account_balance = account_balance - withdrawAmount WHERE account_id = accID;
        INSERT INTO transaction_logs (account_id, transaction_type, amount) VALUES (accID, 'Withdrawal', withdrawAmount);
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient funds';
    END IF;
END;

-- Trigger to log account closures
DROP TRIGGER IF EXISTS AfterAccountClosure;
CREATE TRIGGER AfterAccountClosure
AFTER UPDATE ON accounts
FOR EACH ROW
BEGIN
    IF NEW.account_status = 'Closed' AND OLD.account_status != 'Closed' THEN
        INSERT INTO account_closures (account_id, reason) 
        VALUES (NEW.account_id, NEW.reason_for_closure);
    END IF;
END;

-- Sample Queries

-- 1. Join query to retrieve customer details with their account status
SELECT c.full_name, a.account_id, a.account_balance, a.account_status 
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id;

-- 2. Aggregate function query to find total deposits for each account
SELECT account_id, SUM(amount) AS total_deposits
FROM transaction_logs
WHERE transaction_type = 'Deposit'
GROUP BY account_id;

-- 3. Nested query to find accounts with balance greater than the average balance
SELECT account_id, account_balance
FROM accounts
WHERE account_balance > (SELECT AVG(account_balance) FROM accounts);

-- 4. Update account status and log the closure reason
UPDATE accounts
SET account_status = 'Closed', reason_for_closure = 'Customer Request'
WHERE account_id = 1;

-- DML Statements

-- Adding sample data for customers and employee login

SELECT feedback_id
        FROM employee_feedback
        WHERE employee_id = %s
        ORDER BY feedback_id DESC
        LIMIT 1

SELECT e.name AS employee_name, b.branch_name, b.branch_address
            FROM employee_login e
            JOIN branches b ON e.branch_code = b.branch_code
            WHERE b.branch_code = %s
            ORDER BY e.employee_id
JOIN

SELECT COUNT(*) AS employee_count
            FROM employee_login
            WHERE branch_code = %s

UPDATE accounts 
                SET account_status = %s, reason_for_closure = %s 
                WHERE customer_id = %s AND account_status = 'Active'

INSERT INTO account_closures (account_id, reason)
                SELECT account_id, %s
                FROM accounts
                WHERE customer_id = %s AND account_status = 'Closed'

SELECT feedback_id
        FROM employee_feedback
        WHERE employee_id = %s
        ORDER BY feedback_id DESC
        LIMIT 1

SELECT * FROM transaction_logs
            WHERE account_id IN (%s)
            ORDER BY transaction_date DESC

SELECT account_id FROM accounts
            WHERE customer_id = %s


SELECT * FROM transaction_logs
                WHERE account_id IN (%s)
                ORDER BY transaction_date DESC
