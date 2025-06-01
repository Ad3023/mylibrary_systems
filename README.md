
Name: [Addisu Guche]

Student ID: [1500959]

MyLibrary Desktop Application
Name: [Addisu Guche]

Student ID: [1500959]

Overview
"MyLibrary" is a desktop application developed in C# using WinForms, designed to manage a small library's book inventory and member borrowing records. This application demonstrates core event-driven programming concepts, UI design, and robust database connectivity using ADO.NET. It allows library staff to manage books, borrowers, and handle book issuance and returns.

Features
The application provides the following key functionalities:

Login System
Secure Authentication: Users log in with a username and password, authenticated against a Users table in the database.
Error Handling: Displays an appropriate error message on authentication failure.
Main Window (Dashboard)
Tabbed Interface: Organized into two main sections: Books Management and Borrowers Management for intuitive navigation.
📖 Books Management
View Books: Displays all books in a DataGridView with details such as BookID, Title, Author, Year, and AvailableCopies.
Add Book: A dedicated form to input and save new book details.
Edit Book: Select a book from the list to open an editing form pre-populated with its current details.
Delete Book: Safely remove a book record with a confirmation prompt.
Input Validation: Ensures all required fields are filled and numeric inputs (like Year, Copies) are within valid ranges.
👥 Borrowers Management
View Borrowers: Lists all registered borrowers in a DataGridView showing BorrowerID, Name, Email, and Phone.
Add Borrower: A form to register new library members.
Edit Borrower: Similar to books, edit existing borrower details.
Delete Borrower: Remove borrower records with a confirmation prompt.
Input Validation: Validates fields like Name (not empty), Email (format), and Phone.
Issue & Return Books
Issue Book:
Allows selection of a borrower and an available book.
Automatically decrements AvailableCopies for the issued book.
Records the transaction in an IssuedBooks table with IssueID, BookID, BorrowerID, IssueDate, and DueDate.
Return Book:
Facilitates selection of an issued record.
Automatically increments AvailableCopies for the returned book.
Removes or flags the issued record as returned in the IssuedBooks table.
Reports/Filtering (Bonus)
Book Filtering: Filter the books list by author or year range.
Overdue Books Report: Generate a simple report of books that are currently overdue (DueDate < today).
Technical Specifications
Language & Framework: C# with .NET Framework (Windows Forms).
Database: SQL Server LocalDB.
Data Access: ADO.NET, utilizing parameterized queries for security and performance.
Event Handling: Extensive use of event handlers for UI controls (e.g., Click, SelectionChanged, TextChanged).
Exception Handling: try-catch blocks are implemented around all database operations and critical logic to ensure graceful error handling and user-friendly error messages.
Input Validation: Comprehensive validation is applied to user input fields to maintain data integrity.
Deliverables
This repository contains the complete Visual Studio solution for the "MyLibrary" application, including:

MyLibrary.sln: The Visual Studio solution file.
Database Script: database_setup.sql in the root directory.
Screenshots: Located in the /docs/screenshots/ folder.
Setup and Installation
Follow these steps to get the application up and running on your local machine:

Prerequisites:

Visual Studio 2019 or later (with .NET desktop development workload installed).
SQL Server Express LocalDB (usually installed with Visual Studio or available as a standalone download).
Clone the Repository:

git clone [https://github.com/YourGitHubUsername/MyLibrary.git](https://github.com/YourGitHubUsername/MyLibrary.git)
cd MyLibrary
(Replace YourGitHubUsername with your actual GitHub username)

Database Setup:

Verify LocalDB: Open Command Prompt and run sqllocaldb info. Ensure MSSQLLocalDB is listed and its state is Running. If not, run sqllocaldb start MSSQLLocalDB or follow the troubleshooting steps from previous discussions to create/start it.
Execute SQL Script:
Open SQL Server Management Studio (SSMS) or use Visual Studio's SQL Server Object Explorer.
Connect to (localdb)\MSSQLLocalDB.
Open the database_setup.sql file located in the root of the cloned repository.
Execute the script to create the MyLibrary database and its tables (Users, Books, Borrowers, IssuedBooks), and seed initial data.
Open in Visual Studio:

Double-click on MyLibrary.sln to open the project in Visual Studio.
Build the Solution:

In Visual Studio, go to Build > Build Solution (or press Ctrl+Shift+B). This will compile the application.
Run the Application:

Press F5 or click the Start button in Visual Studio to run the application in debug mode.
Default Login Credentials
Username: admin
Password: password
UI Screenshots
(Create a folder named docs/screenshots in your repository and place your images there. Then update these links.)

Database Script (database_setup.sql)
-- This script creates the MyLibrary database and its tables.
-- It also seeds initial data for testing.

-- Check if the database exists, if so, drop and recreate it
IF EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = N'MyLibrary')
DROP DATABASE MyLibrary;
GO

CREATE DATABASE MyLibrary;
GO

USE MyLibrary;
GO

-- 1. Users Table for Login
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Password NVARCHAR(255) NOT NULL -- Store hashed passwords in a real app!
);

-- 2. Books Table
CREATE TABLE Books (
    BookID INT PRIMARY KEY IDENTITY(1,1),
    Title NVARCHAR(255) NOT NULL,
    Author NVARCHAR(255) NOT NULL,
    PublicationYear INT,
    TotalCopies INT NOT NULL,
    AvailableCopies INT NOT NULL
);

-- 3. Borrowers Table (Library Members)
CREATE TABLE Borrowers (
    BorrowerID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(255) NOT NULL,
    Email NVARCHAR(255) UNIQUE,
    Phone NVARCHAR(20)
);

-- 4. IssuedBooks Table (Records of borrowed books)
CREATE TABLE IssuedBooks (
    IssueID INT PRIMARY KEY IDENTITY(1,1),
    BookID INT NOT NULL,
    BorrowerID INT NOT NULL,
    IssueDate DATE NOT NULL,
    DueDate DATE NOT NULL,
    ReturnDate DATE NULL, -- Null if not yet returned
    IsReturned BIT NOT NULL DEFAULT 0, -- 0 for not returned, 1 for returned
    FOREIGN KEY (BookID) REFERENCES Books(BookID),
    FOREIGN KEY (BorrowerID) REFERENCES Borrowers(BorrowerID)
);

-- Seed initial data

-- Seed Users
INSERT INTO Users (Username, Password) VALUES
('admin', 'password'), -- For a real app, hash this!
('librarian', 'pass123');

-- Seed Books
INSERT INTO Books (Title, Author, PublicationYear, TotalCopies, AvailableCopies) VALUES
('The Hitchhiker''s Guide to the Galaxy', 'Douglas Adams', 1979, 5, 5),
('Pride and Prejudice', 'Jane Austen', 1813, 3, 3),
('1984', 'George Orwell', 1949, 4, 4),
('To Kill a Mockingbird', 'Harper Lee', 1960, 6, 6),
('The Great Gatsby', 'F. Scott Fitzgerald', 1925, 2, 2);

-- Seed Borrowers
INSERT INTO Borrowers (Name, Email, Phone) VALUES
('Alice Smith', 'alice.s@example.com', '111-222-3333'),
('Bob Johnson', 'bob.j@example.com', '444-555-6666'),
('Charlie Brown', 'charlie.b@example.com', '777-888-9999');

-- Example of an Issued Book (optional, for testing issue/return logic)
-- Note: Manually adjust AvailableCopies in Books if you add initial issued books
-- For example, if 'The Hitchhiker''s Guide to the Galaxy' is issued, its AvailableCopies should be 4.
-- INSERT INTO IssuedBooks (BookID, BorrowerID, IssueDate, DueDate, IsReturned) VALUES
-- (1, 1, '2025-05-20', '2025-06-03', 0);
-- UPDATE Books SET AvailableCopies = 4 WHERE BookID = 1;
