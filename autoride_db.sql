-- AUTORIDE: nâng cấp CSDL legacy theo quy trình thuê và trả xe.
-- Chạy tệp này một lần trên MySQL 8.0+.

CREATE DATABASE IF NOT EXISTS autoride_db;
USE autoride_db;

-- Cấu trúc legacy, chỉ tạo khi chưa có bảng.
CREATE TABLE IF NOT EXISTS Cars (
    car_id INT AUTO_INCREMENT PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    license_plate VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Rentals (
    rental_id INT AUTO_INCREMENT PRIMARY KEY,
    car_id INT,
    customer_name VARCHAR(100) NOT NULL,
    rent_date DATETIME NOT NULL,
    return_date DATETIME,
    status VARCHAR(50) DEFAULT 'BOOKED',
    FOREIGN KEY (car_id) REFERENCES Cars(car_id)
);

-- Chuẩn hóa trạng thái và bổ sung các số tiền cần đối soát.
ALTER TABLE Rentals
    MODIFY COLUMN status ENUM('BOOKED', 'ACTIVE', 'COMPLETED', 'CANCELLED')
        NOT NULL DEFAULT 'BOOKED',
    ADD COLUMN security_deposit DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    ADD COLUMN late_fee DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    ADD COLUMN damage_fee DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    ADD CONSTRAINT CHK_Rental_Fees CHECK (
        security_deposit >= 0 AND late_fee >= 0 AND damage_fee >= 0
    );

-- Một hợp đồng có tối đa một biên bản kiểm tra lúc trả xe.
CREATE TABLE Inspections (
    inspection_id INT AUTO_INCREMENT PRIMARY KEY,
    rental_id INT NOT NULL UNIQUE,
    inspection_date DATETIME NOT NULL,
    damage_description TEXT,
    inspector_name VARCHAR(100) NOT NULL,
    CONSTRAINT FK_Inspection_Rental
        FOREIGN KEY (rental_id) REFERENCES Rentals(rental_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Không cho lập biên bản nếu khách chưa nhận xe.
DELIMITER //
CREATE TRIGGER trg_inspection_requires_active_rental
BEFORE INSERT ON Inspections
FOR EACH ROW
BEGIN
    DECLARE rental_status VARCHAR(20);

    SELECT status INTO rental_status
    FROM Rentals
    WHERE rental_id = NEW.rental_id;

    IF rental_status <> 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Chi lap bien ban khi hop dong dang ACTIVE';
    END IF;
END//
DELIMITER ;

-- Dữ liệu mô phỏng: Nguyễn Văn A thuê xe, cọc 10.000.000 VNĐ.
INSERT INTO Cars (model_name, license_plate)
VALUES ('Toyota Vios', '30A-12345');

INSERT INTO Rentals (
    car_id, customer_name, rent_date, status, security_deposit
) VALUES (
    1, 'Nguyen Van A', '2026-09-21 08:00:00', 'ACTIVE', 10000000.00
);

-- Khi trả xe, nhân viên lập biên bản vỡ đèn pha trái.
INSERT INTO Inspections (
    rental_id, inspection_date, damage_description, inspector_name
) VALUES (
    1, '2026-09-23 10:00:00', 'Vo den pha trai', 'Tran Thi B'
);

UPDATE Rentals
SET
    return_date = '2026-09-23 10:00:00',
    status = 'COMPLETED',
    late_fee = 0.00,
    damage_fee = 2000000.00
WHERE rental_id = 1;

-- Kiểm tra số tiền hoàn cọc thực tế.
SELECT
    r.rental_id,
    r.customer_name,
    c.model_name,
    r.status,
    r.security_deposit,
    r.late_fee,
    r.damage_fee,
    (r.security_deposit - r.late_fee - r.damage_fee) AS refund_amount,
    i.damage_description,
    i.inspector_name
FROM Rentals AS r
JOIN Cars AS c ON c.car_id = r.car_id
LEFT JOIN Inspections AS i ON i.rental_id = r.rental_id;
