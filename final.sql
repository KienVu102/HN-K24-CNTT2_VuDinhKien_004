CREATE DATABASE IF NOT EXISTS final_test;
USE final_test;

-- PHẦN 1: THIẾT KẾ CSDL & CHÈN DỮ LIỆU

CREATE TABLE Readers (
    reader_id VARCHAR(10) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(15),
    created_at DATE DEFAULT (CURRENT_DATE) 
);

CREATE TABLE Membership_Details (
    card_id VARCHAR(10) PRIMARY KEY,
    reader_id VARCHAR(10) UNIQUE, 
    membership_rank ENUM('Standard', 'VIP'),
    expiry_date DATE,
    citizen_id VARCHAR(20) UNIQUE,
    FOREIGN KEY (reader_id) REFERENCES Readers(reader_id)
);

CREATE TABLE Categories (
    category_id VARCHAR(10) PRIMARY KEY,
    category_name VARCHAR(50),
    description TEXT
);

CREATE TABLE Books (
    book_id VARCHAR(10) PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(100),
    category_id VARCHAR(10),
    price DECIMAL(10, 2) CHECK (price > 0), 
    stock_quantity INT CHECK (stock_quantity >= 0), 
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

CREATE TABLE Loan_Records (
    loan_id VARCHAR(10) PRIMARY KEY,
    reader_id VARCHAR(10),
    book_id VARCHAR(10),
    borrow_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NULL,
    CONSTRAINT chk_dates CHECK (due_date > borrow_date), 
    FOREIGN KEY (reader_id) REFERENCES Readers(reader_id),
    FOREIGN KEY (book_id) REFERENCES Books(book_id)
);

INSERT INTO Readers (reader_id, full_name, email, phone_number, created_at) VALUES
('R001', 'Nguyen Van A', 'anv@gmail.com', '901234567', '2022-01-15'),
('R002', 'Tran Thi B', 'btt@gmail.com', '912345678', '2022-5-20'),
('R003', 'Le Van C', 'cle@yahoo.com', '922334455', '2023-02-10'),
('R004', 'Pham Minh D', 'dpham@hotmail.com', '933445566', '2023-11-05'),
('R005', 'Hoang Anh E', 'ehoang@gmail.com', '944556677', '2024-01-12');

INSERT INTO Categories VALUES 
('C01', 'IT', 'Sách về công nghệ thông tin và lập trình'),
('C02', 'Kinh Te', 'Sách kinh doanh, tài chính, khởi nghiệp'),
('C03', 'Van Hoc', 'Tiểu thuyết, truyện ngắn, thơ'),
('C04', 'Ngoai Ngu', 'Sách học tiếng Anh, Nhật, Hàn'),
('C05', 'Lich Su', 'Sách nghiên cứu lịch sử, văn hóa');

INSERT INTO Books VALUES
('B01', 'Clean Code', 'Robert C. Martin', 'C01', 450000, 10),
('B02', 'Dac nhan tam', 'Dale Carnegie', 'C02', 150000, 50),
('B03', 'Harry Potter 1', 'J.K. Rowling', 'C03', 250000, 5),
('B04', 'IELTS Reading', 'Cambridge', 'C04', 180000, 0),
('B05', 'Dai Viet Su Ky', 'Le Van Huu', 'C05', 300000, 20);

INSERT INTO Membership_Details VALUES
('M01', 'R001', 'Standard', '2025-01-15', '123456789'),
('M02', 'R002', 'VIP', '2025-05-20', '234567890'),
('M03', 'R003', 'Standard', '2024-02-10', '345678901'),
('M04', 'R004', 'VIP', '2025-11-5', '456789012'),
('M05', 'R005', 'Standard', '2026-01-12', '567890123');

INSERT INTO Loan_Records (loan_id, reader_id, book_id, borrow_date, due_date, return_date) VALUES
('L01', 'R001', 'B01', '2023-11-15', '2023-11-22', '2023-11-20'),
('L02', 'R002', 'B02', '2024-12-01', '2024-12-08', '2023-12-05' ),
('L03', 'R001', 'B03', '2023-01-10', '2023-01-17', NULL),
('L04', 'R003', 'B04', '2024-05-20', '2024-05-27', NULL),
('L05', 'R004', 'B01', '2024-01-18', '2024-01-25', NULL);

UPDATE Loan_Records lr
JOIN Books b ON lr.book_id = b.book_id
JOIN Categories c ON b.category_id = c.category_id
SET lr.due_date = DATE_ADD(lr.due_date, INTERVAL 7 DAY)
WHERE c.category_name = 'Van Hoc' AND lr.return_date IS NULL;

DELETE FROM Loan_Records 
WHERE return_date IS NOT NULL AND borrow_date < '2023-10-01';

-- PHẦN 2: TRUY VẤN DỮ LIỆU CƠ BẢN
-- Câu 1: Sách IT > 200k 
SELECT b.book_id, b.title, b.price 
FROM Books b 
JOIN Categories c ON b.category_id = c.category_id
WHERE c.category_name = 'IT' AND b.price > 200000;

-- Câu 2: Độc giả 2022 và Gmail 
SELECT reader_id, full_name, email 
FROM Readers 
WHERE YEAR(created_at) = 2022 AND email LIKE '%@gmail.com';

-- Câu 3: Top 5 sách đắt nhất, bỏ qua 2 cuốn đầu 
SELECT * FROM Books ORDER BY price DESC LIMIT 5 OFFSET 2;

-- PHẦN 3: TRUY VẤN DỮ LIỆU NÂNG CAO
-- Câu 1: Đơn mượn chưa trả 
SELECT lr.loan_id, r.full_name, b.title, lr.borrow_date, lr.return_date
FROM Loan_Records lr
JOIN Readers r ON lr.reader_id = r.reader_id
JOIN Books b ON lr.book_id = b.book_id
WHERE lr.return_date IS NULL;

-- Câu 2: Tổng tồn kho theo danh mục > 10 
SELECT c.category_name, SUM(b.stock_quantity) as total_stock
FROM Categories c
JOIN Books b ON c.category_id = b.category_id
GROUP BY c.category_name
HAVING total_stock > 10;

-- Câu 3: Độc giả VIP chưa từng mượn sách > 300k
SELECT r.full_name
FROM Readers r
JOIN Membership_Details md ON r.reader_id = md.reader_id
WHERE md.membership_rank = 'VIP'
AND r.reader_id NOT IN (
    SELECT lr.reader_id FROM Loan_Records lr
    JOIN Books b ON lr.book_id = b.book_id
    WHERE b.price > 300000
);

-- PHẦN 4: INDEX VÀ VIEW
-- Câu 1: Tạo Composite Index 
CREATE INDEX idx_loan_dates ON Loan_Records(borrow_date, return_date);

-- Câu 2: Overdue View 
CREATE VIEW vw_overdue_loans AS
SELECT lr.loan_id, r.full_name, b.title, lr.borrow_date, lr.due_date
FROM Loan_Records lr
JOIN Readers r ON lr.reader_id = r.reader_id
JOIN Books b ON lr.book_id = b.book_id
WHERE lr.return_date IS NULL AND lr.due_date < CURDATE();

-- PHẦN 5: TRIGGER
-- Câu 1: Update kho hàng
DELIMITER //
CREATE TRIGGER trg_after_loan_insert
AFTER INSERT ON Loan_Records
FOR EACH ROW
BEGIN
    UPDATE Books SET stock_quantity = stock_quantity - 1 
    WHERE book_id = NEW.book_id;
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER trg_prevent_delete_active_reader
BEFORE DELETE ON Readers
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM Loan_Records WHERE reader_id = OLD.reader_id AND return_date IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot delete reader with active loans';
    END IF;
END //
DELIMITER ;

