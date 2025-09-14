-- Расширенная схема базы данных "Библиотека"
-- Версия 2.0
-- Автор: Jules

-- Установка кодировки для корректной работы с кириллицей
SET NAMES 'utf8mb4';

-- 1. Таблица авторов
-- Добавлены поля: дата рождения, дата смерти, национальность для более полной информации.
CREATE TABLE Authors (
    AuthorID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Biography TEXT,
    DateOfBirth DATE,
    DateOfDeath DATE,
    Nationality VARCHAR(50),
    INDEX idx_author_name (LastName, FirstName)
);

-- 2. Таблица издательств
-- Добавлены поля: контактная информация для связи.
CREATE TABLE Publishers (
    PublisherID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(150) NOT NULL UNIQUE,
    Address TEXT,
    PhoneNumber VARCHAR(25),
    Email VARCHAR(100),
    Website VARCHAR(255)
);

-- 3. Таблица категорий
-- Добавлено поле ParentCategoryID для создания иерархии (например, "Фантастика" -> "Научная фантастика").
CREATE TABLE Categories (
    CategoryID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Description TEXT,
    ParentCategoryID INT,
    FOREIGN KEY (ParentCategoryID) REFERENCES Categories(CategoryID) ON DELETE SET NULL
);

-- 4. Таблица книг
-- Добавлены поля: краткое описание и URL обложки.
-- PublisherID и CategoryID теперь могут быть NULL, если эта информация неизвестна.
CREATE TABLE Books (
    BookID INT AUTO_INCREMENT PRIMARY KEY,
    Title VARCHAR(255) NOT NULL,
    PublisherID INT,
    CategoryID INT,
    PublicationYear INT,
    ISBN VARCHAR(20) UNIQUE,
    Description TEXT,
    CoverImageURL VARCHAR(255),
    FOREIGN KEY (PublisherID) REFERENCES Publishers(PublisherID) ON DELETE SET NULL,
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID) ON DELETE SET NULL,
    INDEX idx_book_title (Title)
);

-- 5. Связующая таблица "Книга-Автор" (Многие-ко-многим)
-- Остается без изменений, так как это правильный способ реализации такой связи.
CREATE TABLE BookAuthors (
    BookAuthorID INT AUTO_INCREMENT PRIMARY KEY,
    BookID INT NOT NULL,
    AuthorID INT NOT NULL,
    FOREIGN KEY (BookID) REFERENCES Books(BookID) ON DELETE CASCADE,
    FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID) ON DELETE CASCADE,
    UNIQUE KEY uk_book_author (BookID, AuthorID)
);

-- 6. Таблица читателей (членов библиотеки)
-- Добавлены поля: телефон, адрес, дата истечения членства и статус.
CREATE TABLE Members (
    MemberID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    PhoneNumber VARCHAR(25),
    Address TEXT,
    RegistrationDate DATE NOT NULL DEFAULT (CURDATE()),
    MembershipExpiryDate DATE,
    Status ENUM('active', 'expired', 'banned') NOT NULL DEFAULT 'active',
    INDEX idx_member_name (LastName, FirstName)
);

-- 7. Таблица копий книг (НОВАЯ)
-- Позволяет отслеживать каждый физический экземпляр книги.
CREATE TABLE BookCopies (
    CopyID INT AUTO_INCREMENT PRIMARY KEY,
    BookID INT NOT NULL,
    LibraryCode VARCHAR(50) UNIQUE NOT NULL, -- Уникальный инвентарный номер
    Status ENUM('available', 'on_loan', 'lost', 'damaged', 'in_repair') NOT NULL DEFAULT 'available',
    Location VARCHAR(100), -- Например, номер полки или зала
    FOREIGN KEY (BookID) REFERENCES Books(BookID) ON DELETE CASCADE
);

-- 8. Таблица выдачи книг (переименована в Loans)
-- Улучшена: добавлена плановая дата возврата (DueDate) и фактическая (ActualReturnDate).
CREATE TABLE Loans (
    LoanID INT AUTO_INCREMENT PRIMARY KEY,
    CopyID INT NOT NULL,
    MemberID INT NOT NULL,
    IssueDate DATE NOT NULL,
    DueDate DATE NOT NULL, -- Плановая дата возврата
    ActualReturnDate DATE, -- Фактическая дата возврата (NULL, если книга еще не возвращена)
    FOREIGN KEY (CopyID) REFERENCES BookCopies(CopyID) ON DELETE RESTRICT,
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID) ON DELETE RESTRICT
);

-- 9. Таблица штрафов (НОВАЯ)
-- Для отслеживания штрафов за просроченные книги.
CREATE TABLE Fines (
    FineID INT AUTO_INCREMENT PRIMARY KEY,
    LoanID INT NOT NULL,
    MemberID INT NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    DateIssued DATE NOT NULL,
    Status ENUM('unpaid', 'paid') NOT NULL DEFAULT 'unpaid',
    FOREIGN KEY (LoanID) REFERENCES Loans(LoanID) ON DELETE CASCADE,
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID) ON DELETE CASCADE
);

-- 10. Таблица резервирования (НОВАЯ)
-- Позволяет читателям бронировать книги, которых нет в наличии.
CREATE TABLE Reservations (
    ReservationID INT AUTO_INCREMENT PRIMARY KEY,
    BookID INT NOT NULL,
    MemberID INT NOT NULL,
    ReservationDate DATE NOT NULL,
    Status ENUM('active', 'fulfilled', 'cancelled') NOT NULL DEFAULT 'active',
    FOREIGN KEY (BookID) REFERENCES Books(BookID) ON DELETE CASCADE,
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID) ON DELETE CASCADE,
    UNIQUE KEY uk_reservation (BookID, MemberID, Status)
);

-- 11. Таблица отзывов и рейтингов (НОВАЯ)
-- Для сбора обратной связи от читателей.
CREATE TABLE Reviews (
    ReviewID INT AUTO_INCREMENT PRIMARY KEY,
    BookID INT NOT NULL,
    MemberID INT NOT NULL,
    Rating TINYINT CHECK (Rating >= 1 AND Rating <= 5),
    Comment TEXT,
    ReviewDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (BookID) REFERENCES Books(BookID) ON DELETE CASCADE,
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID) ON DELETE CASCADE
);

-- Демонстрационные данные (опционально, для примера)

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
