CREATE DATABASE IF NOT EXISTS public_transport;
USE public_transport;

-- TABLES
CREATE TABLE IF NOT EXISTS Passenger (
    PassengerID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(15),
    DOB DATE,
    CardType VARCHAR(20) DEFAULT 'None'
);

CREATE TABLE IF NOT EXISTS Driver (
    DriverID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    LicenseNo VARCHAR(50) UNIQUE NOT NULL,
    ShiftHours INT DEFAULT 8,
    Phone VARCHAR(15)
);

CREATE TABLE IF NOT EXISTS Route (
    RouteID INT AUTO_INCREMENT PRIMARY KEY,
    RouteName VARCHAR(100) NOT NULL,
    Origin VARCHAR(100) NOT NULL,
    Destination VARCHAR(100) NOT NULL,
    Distance DECIMAL(5,2),
    Type VARCHAR(20) DEFAULT 'Bus'
);

CREATE TABLE IF NOT EXISTS Vehicle (
    VehicleID INT AUTO_INCREMENT PRIMARY KEY,
    VehicleNo VARCHAR(20) UNIQUE NOT NULL,
    Type VARCHAR(20) NOT NULL,
    Capacity INT NOT NULL,
    Model VARCHAR(50),
    Status VARCHAR(20) DEFAULT 'Active',
    DriverID INT,
    FOREIGN KEY (DriverID) REFERENCES Driver(DriverID)
);

CREATE TABLE IF NOT EXISTS Schedule (
    ScheduleID INT AUTO_INCREMENT PRIMARY KEY,
    RouteID INT NOT NULL,
    VehicleID INT NOT NULL,
    DepartureTime TIME NOT NULL,
    ArrivalTime TIME NOT NULL,
    Frequency INT,
    FOREIGN KEY (RouteID) REFERENCES Route(RouteID),
    FOREIGN KEY (VehicleID) REFERENCES Vehicle(VehicleID)
);

CREATE TABLE IF NOT EXISTS Ticket (
    TicketID INT AUTO_INCREMENT PRIMARY KEY,
    PassengerID INT NOT NULL,
    ScheduleID INT NOT NULL,
    SeatNo VARCHAR(10) NOT NULL,
    Fare DECIMAL(6,2) NOT NULL,
    BookingDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (PassengerID) REFERENCES Passenger(PassengerID),
    FOREIGN KEY (ScheduleID) REFERENCES Schedule(ScheduleID)
);

CREATE TABLE IF NOT EXISTS Feedback (
    FeedbackID INT AUTO_INCREMENT PRIMARY KEY,
    PassengerID INT NOT NULL,
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    Comments TEXT,
    FeedbackDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (PassengerID) REFERENCES Passenger(PassengerID)
);

-- VIEW FOR DASHBOARD
CREATE OR REPLACE VIEW BookingSummary AS
SELECT T.TicketID, P.Name AS PassengerName, R.RouteName, V.VehicleNo, S.DepartureTime, T.SeatNo, T.Fare
FROM Ticket T
JOIN Passenger P ON T.PassengerID = P.PassengerID
JOIN Schedule S ON T.ScheduleID = S.ScheduleID
JOIN Route R ON S.RouteID = R.RouteID
JOIN Vehicle V ON S.VehicleID = V.VehicleID;

-- PROCEDURE FOR BOOKING
DELIMITER $$
CREATE PROCEDURE BookTicket(IN p_p_id INT, IN p_s_id INT, IN p_seat VARCHAR(10), IN p_fare DECIMAL(6,2))
BEGIN
    INSERT INTO Ticket (PassengerID, ScheduleID, SeatNo, Fare) VALUES (p_p_id, p_s_id, p_seat, p_fare);
END$$
DELIMITER ;

-- TRIGGER FOR SEAT VALIDATION
DELIMITER $$
CREATE TRIGGER PreventDoubleSeat BEFORE INSERT ON Ticket FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM Ticket WHERE ScheduleID = NEW.ScheduleID AND SeatNo = NEW.SeatNo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Seat already booked.';
    END IF;
END$$
DELIMITER ;

-- DATA SEEDING (All passengers included)
INSERT IGNORE INTO Route VALUES (1, 'Route 201', 'Majestic', 'Electronic City', 25.50, 'Bus');
INSERT IGNORE INTO Driver VALUES (1, 'Ravi Kumar', 'KA-01-202401', 8, '9876543210');
INSERT IGNORE INTO Vehicle VALUES (1, 'KA-01-F-1234', 'Bus', 40, 'Tata Starbus', 'Active', 1);
INSERT IGNORE INTO Schedule VALUES (1, 1, 1, '06:00:00', '07:30:00', 30);
INSERT IGNORE INTO Passenger (Name, Email, Phone, DOB, CardType) VALUES
('B M Thanu Sri', 'thanu@gmail.com', '9000000001', '2004-05-10', 'Monthly'),
('Sanvi S', 'sanvi@gmail.com', '9000000002', '2004-08-22', 'Weekly'),
('Akash V', 'akash@gmail.com', '9000000005', '2003-07-20', 'Monthly'),
('Priya Mani', 'priya@gmail.com', '9000000006', '2005-02-14', 'Weekly'),
('Rahul Hegde', 'rahul@gmail.com', '9000000007', '2004-11-30', 'None'),
('Kavya Shree', 'kavya@gmail.com', '9000000008', '2002-05-05', 'Daily'),
('Santhosh Kumar', 'santhosh@gmail.com', '9000000009', '2001-09-12', 'Monthly');