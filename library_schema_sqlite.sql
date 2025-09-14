-- Схема базы данных "Библиотека" адаптированная для SQLite
-- Версия 2.0
-- Автор: Jules

-- Включаем поддержку внешних ключей, это важно для SQLite
PRAGMA foreign_keys = ON;

-- 1. Таблица авторов
CREATE TABLE Authors (
    AuthorID INTEGER PRIMARY KEY AUTOINCREMENT,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Biography TEXT,
    DateOfBirth TEXT, -- В SQLite тип DATE хранится как TEXT
    DateOfDeath TEXT,
    Nationality VARCHAR(50)
);

-- 2. Таблица издательств
CREATE TABLE Publishers (
    PublisherID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name VARCHAR(150) NOT NULL UNIQUE,
    Address TEXT,
    PhoneNumber VARCHAR(25),
    Email VARCHAR(100),
    Website VARCHAR(255)
);

-- 3. Таблица категорий
CREATE TABLE Categories (
    CategoryID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Description TEXT,
    ParentCategoryID INTEGER,
    FOREIGN KEY (ParentCategoryID) REFERENCES Categories(CategoryID) ON DELETE SET NULL
);

-- 4. Таблица книг
CREATE TABLE Books (
    BookID INTEGER PRIMARY KEY AUTOINCREMENT,
    Title VARCHAR(255) NOT NULL,
    PublisherID INTEGER,
    CategoryID INTEGER,
    PublicationYear INTEGER,
    ISBN VARCHAR(20) UNIQUE,
    Description TEXT,
    CoverImageURL VARCHAR(255),
    FOREIGN KEY (PublisherID) REFERENCES Publishers(PublisherID) ON DELETE SET NULL,
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID) ON DELETE SET NULL
);

-- 5. Связующая таблица "Книга-Автор"
CREATE TABLE BookAuthors (
    BookAuthorID INTEGER PRIMARY KEY AUTOINCREMENT,
    BookID INTEGER NOT NULL,
    AuthorID INTEGER NOT NULL,
    FOREIGN KEY (BookID) REFERENCES Books(BookID) ON DELETE CASCADE,
    FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID) ON DELETE CASCADE,
    UNIQUE (BookID, AuthorID)
);

-- 6. Таблица читателей
CREATE TABLE Members (
    MemberID INTEGER PRIMARY KEY AUTOINCREMENT,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    PhoneNumber VARCHAR(25),
    Address TEXT,
    RegistrationDate TEXT NOT NULL DEFAULT (date('now')),
    MembershipExpiryDate TEXT,
    Status TEXT NOT NULL DEFAULT 'active' CHECK(Status IN ('active', 'expired', 'banned'))
);

-- 7. Таблица копий книг
CREATE TABLE BookCopies (
    CopyID INTEGER PRIMARY KEY AUTOINCREMENT,
    BookID INTEGER NOT NULL,
    LibraryCode VARCHAR(50) UNIQUE NOT NULL,
    Status TEXT NOT NULL DEFAULT 'available' CHECK(Status IN ('available', 'on_loan', 'lost', 'damaged', 'in_repair')),
    Location VARCHAR(100),
    FOREIGN KEY (BookID) REFERENCES Books(BookID) ON DELETE CASCADE
);

-- 8. Таблица выдачи книг
CREATE TABLE Loans (
    LoanID INTEGER PRIMARY KEY AUTOINCREMENT,
    CopyID INTEGER NOT NULL,
    MemberID INTEGER NOT NULL,
    IssueDate TEXT NOT NULL,
    DueDate TEXT NOT NULL,
    ActualReturnDate TEXT,
    FOREIGN KEY (CopyID) REFERENCES BookCopies(CopyID) ON DELETE RESTRICT,
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID) ON DELETE RESTRICT
);

-- 9. Таблица штрафов
CREATE TABLE Fines (
    FineID INTEGER PRIMARY KEY AUTOINCREMENT,
    LoanID INTEGER NOT NULL,
    MemberID INTEGER NOT NULL,
    Amount REAL NOT NULL, -- DECIMAL заменен на REAL
    DateIssued TEXT NOT NULL,
    Status TEXT NOT NULL DEFAULT 'unpaid' CHECK(Status IN ('unpaid', 'paid')),
    FOREIGN KEY (LoanID) REFERENCES Loans(LoanID) ON DELETE CASCADE,
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID) ON DELETE CASCADE
);

-- 10. Таблица резервирования
CREATE TABLE Reservations (
    ReservationID INTEGER PRIMARY KEY AUTOINCREMENT,
    BookID INTEGER NOT NULL,
    MemberID INTEGER NOT NULL,
    ReservationDate TEXT NOT NULL,
    Status TEXT NOT NULL DEFAULT 'active' CHECK(Status IN ('active', 'fulfilled', 'cancelled')),
    FOREIGN KEY (BookID) REFERENCES Books(BookID) ON DELETE CASCADE,
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID) ON DELETE CASCADE,
    UNIQUE (BookID, MemberID, Status)
);

-- 11. Таблица отзывов и рейтингов
CREATE TABLE Reviews (
    ReviewID INTEGER PRIMARY KEY AUTOINCREMENT,
    BookID INTEGER NOT NULL,
    MemberID INTEGER NOT NULL,
    Rating INTEGER CHECK (Rating >= 1 AND Rating <= 5),
    Comment TEXT,
    ReviewDate TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, -- DATETIME заменен на TEXT
    FOREIGN KEY (BookID) REFERENCES Books(BookID) ON DELETE CASCADE,
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID) ON DELETE CASCADE
);

-- Создание индексов для ускорения поиска (в SQLite это отдельные команды)
CREATE INDEX idx_author_name ON Authors (LastName, FirstName);
CREATE INDEX idx_member_name ON Members (LastName, FirstName);
CREATE INDEX idx_book_title ON Books (Title);

-- Демонстрационные данные (полностью совместимы с SQLite)
INSERT INTO Authors (FirstName, LastName, Biography, DateOfBirth, Nationality) VALUES
('Лев', 'Толстой', 'Великий русский писатель и мыслитель.', '1828-09-09', 'Русский'),
('Джордж', 'Оруэлл', 'Английский писатель и публицист.', '1903-06-25', 'Британец');

INSERT INTO Publishers (Name, Address) VALUES
('Эксмо', 'г. Москва, Россия'),
('Penguin Books', 'London, UK');

INSERT INTO Categories (Name, Description) VALUES
('Классическая литература', 'Произведения, признанные классикой мировой литературы.'),
('Антиутопия', 'Жанр, описывающий тоталитарное общество.');

INSERT INTO Books (Title, PublisherID, CategoryID, PublicationYear, ISBN) VALUES
('Война и мир', 1, 1, 1869, '978-5-699-12828-8'),
('1984', 2, 2, 1949, '978-0-452-28423-4');

INSERT INTO BookAuthors (BookID, AuthorID) VALUES
(1, 1),
(2, 2);

INSERT INTO BookCopies (BookID, LibraryCode, Status, Location) VALUES
(1, 'C-001-1', 'available', 'Зал 1, Стеллаж 5'),
(1, 'C-001-2', 'on_loan', 'На руках'),
(2, 'D-002-1', 'available', 'Зал 2, Стеллаж 3');

INSERT INTO Members (FirstName, LastName, Email, MembershipExpiryDate) VALUES
('Иван', 'Иванов', 'ivanov@email.com', '2025-12-31'),
('Петр', 'Петров', 'petrov@email.com', '2024-10-01');

INSERT INTO Loans (CopyID, MemberID, IssueDate, DueDate) VALUES
(2, 1, '2024-05-10', '2024-05-24');
