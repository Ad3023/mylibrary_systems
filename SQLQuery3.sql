-- Create the database
CREATE DATABASE LibraryDB;
GO

USE LibraryManagement;
GO

-- Create Users table for authentication
CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Password NVARCHAR(100) NOT NULL,
    Role NVARCHAR(20) NOT NULL DEFAULT 'Librarian'
);
GO

-- Create Books table
CREATE TABLE Books (
    BookID INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(100) NOT NULL,
    Author NVARCHAR(100) NOT NULL,
    Year INT NOT NULL,
    ISBN NVARCHAR(20) NULL,
    AvailableCopies INT NOT NULL,
    TotalCopies INT NOT NULL,
    
    CONSTRAINT CHK_Year CHECK (Year BETWEEN 1000 AND YEAR(GETDATE()) + 1),
    CONSTRAINT CHK_Copies CHECK (AvailableCopies >= 0 AND TotalCopies >= 0)
);
GO

-- Create Borrowers table
CREATE TABLE Borrowers (
    BorrowerID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20) NOT NULL,
    RegistrationDate DATE NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT UQ_Email UNIQUE (Email)
);
GO

-- Create IssuedBooks table
CREATE TABLE IssuedBooks (
    IssueID INT IDENTITY(1,1) PRIMARY KEY,
    BookID INT NOT NULL,
    BorrowerID INT NOT NULL,
    IssueDate DATE NOT NULL DEFAULT GETDATE(),
    DueDate DATE NOT NULL,
    ReturnDate DATE NULL,
    FineAmount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    
    FOREIGN KEY (BookID) REFERENCES Books(BookID),
    FOREIGN KEY (BorrowerID) REFERENCES Borrowers(BorrowerID),
    
    CONSTRAINT CHK_DueDate CHECK (DueDate > IssueDate),
    CONSTRAINT CHK_ReturnDate CHECK (ReturnDate IS NULL OR ReturnDate >= IssueDate)
);
GO

-- Create Overdue fines table
CREATE TABLE Fines (
    FineID INT IDENTITY(1,1) PRIMARY KEY,
    IssueID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    Paid BIT NOT NULL DEFAULT 0,
    PaymentDate DATE NULL,
    
    FOREIGN KEY (IssueID) REFERENCES IssuedBooks(IssueID)
);
GO

-- Create indexes for better performance
CREATE INDEX IX_Books_Title ON Books(Title);
CREATE INDEX IX_Books_Author ON Books(Author);
CREATE INDEX IX_Borrowers_Name ON Borrowers(Name);
CREATE INDEX IX_IssuedBooks_DueDate ON IssuedBooks(DueDate);
GO

-- Create stored procedure for issuing books
CREATE PROCEDURE spIssueBook
    @BookID INT,
    @BorrowerID INT,
    @DueDays INT = 14
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check available copies
        DECLARE @Available INT;
        SELECT @Available = AvailableCopies FROM Books WHERE BookID = @BookID;
        
        IF @Available <= 0
            THROW 50001, 'No available copies of this book', 1;
        
        -- Insert issue record
        INSERT INTO IssuedBooks (BookID, BorrowerID, DueDate)
        VALUES (@BookID, @BorrowerID, DATEADD(DAY, @DueDays, GETDATE()));
        
        -- Update available copies
        UPDATE Books 
        SET AvailableCopies = AvailableCopies - 1 
        WHERE BookID = @BookID;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- Create stored procedure for returning books
CREATE PROCEDURE spReturnBook
    @IssueID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Get book ID and due date
        DECLARE @BookID INT, @DueDate DATE, @ReturnDate DATE = GETDATE();
        SELECT @BookID = BookID, @DueDate = DueDate 
        FROM IssuedBooks 
        WHERE IssueID = @IssueID;
        
        -- Update return date
        UPDATE IssuedBooks 
        SET ReturnDate = @ReturnDate 
        WHERE IssueID = @IssueID;
        
        -- Update available copies
        UPDATE Books 
        SET AvailableCopies = AvailableCopies + 1 
        WHERE BookID = @BookID;
        
        -- Calculate and record fine if overdue
        DECLARE @DaysOverdue INT = DATEDIFF(DAY, @DueDate, @ReturnDate);
        IF @DaysOverdue > 0
        BEGIN
            DECLARE @Fine DECIMAL(10,2) = @DaysOverdue * 0.50; -- $0.50 per day
            INSERT INTO Fines (IssueID, Amount) 
            VALUES (@IssueID, @Fine);
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- Create view for active issues
CREATE VIEW vwActiveLoans AS
SELECT 
    ib.IssueID,
    b.Title AS BookTitle,
    br.Name AS BorrowerName,
    ib.IssueDate,
    ib.DueDate,
    DATEDIFF(DAY, GETDATE(), ib.DueDate) AS DaysRemaining
FROM IssuedBooks ib
INNER JOIN Books b ON ib.BookID = b.BookID
INNER JOIN Borrowers br ON ib.BorrowerID = br.BorrowerID
WHERE ib.ReturnDate IS NULL;
GO

-- Create view for overdue books
CREATE VIEW vwOverdueBooks AS
SELECT 
    ib.IssueID,
    b.Title AS BookTitle,
    br.Name AS BorrowerName,
    ib.IssueDate,
    ib.DueDate,
    DATEDIFF(DAY, ib.DueDate, GETDATE()) AS DaysOverdue,
    f.Amount AS FineAmount
FROM IssuedBooks ib
INNER JOIN Books b ON ib.BookID = b.BookID
INNER JOIN Borrowers br ON ib.BorrowerID = br.BorrowerID
LEFT JOIN Fines f ON ib.IssueID = f.IssueID
WHERE ib.ReturnDate IS NULL
AND ib.DueDate < GETDATE();
GO

-- Insert sample data
INSERT INTO Users (Username, Password, Role) 
VALUES 
    ('admin', 'admin123', 'Admin'),
    ('librarian1', 'lib123', 'Librarian'),
    ('librarian2', 'lib456', 'Librarian');

INSERT INTO Books (Title, Author, Year, ISBN, AvailableCopies, TotalCopies)
VALUES 
    ('The Great Gatsby', 'F. Scott Fitzgerald', 1925, '9780743273565', 3, 5),
    ('To Kill a Mockingbird', 'Harper Lee', 1960, '9780061120084', 5, 5),
    ('1984', 'George Orwell', 1949, '9780451524935', 2, 3),
    ('Pride and Prejudice', 'Jane Austen', 1813, '9780141439518', 4, 4),
    ('The Hobbit', 'J.R.R. Tolkien', 1937, '9780547928227', 0, 2),
    ('Brave New World', 'Aldous Huxley', 1932, '9780060850524', 3, 3);

INSERT INTO Borrowers (Name, Email, Phone)
VALUES 
    ('John Smith', 'john.smith@example.com', '555-1234'),
    ('Emma Johnson', 'emma.j@example.com', '555-5678'),
    ('Michael Brown', 'm.brown@example.com', '555-9012'),
    ('Sarah Davis', 'sarahd@example.com', '555-3456'),
    ('Robert Wilson', 'rob.wilson@example.com', '555-7890');

-- Issue some books
EXEC spIssueBook @BookID = 1, @BorrowerID = 1;
EXEC spIssueBook @BookID = 1, @BorrowerID = 2;
EXEC spIssueBook @BookID = 3, @BorrowerID = 3;
EXEC spIssueBook @BookID = 5, @BorrowerID = 4;
EXEC spIssueBook @BookID = 5, @BorrowerID = 5;

-- Return some books (with some overdue)
UPDATE IssuedBooks SET ReturnDate = DATEADD(DAY, 5, IssueDate) WHERE IssueID = 1;
UPDATE IssuedBooks SET ReturnDate = DATEADD(DAY, 20, IssueDate) WHERE IssueID = 2; -- Overdue
UPDATE IssuedBooks SET ReturnDate = DATEADD(DAY, 10, IssueDate) WHERE IssueID = 3;

-- Generate fines for overdue returns
INSERT INTO Fines (IssueID, Amount, Paid)
VALUES (2, 3.00, 1); -- $0.50 * 6 days overdue = $3.00
GO