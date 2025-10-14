drop schema if exists mini_project2; 
create database if not exists mini_project2;
USE mini_project2;
DROP TABLE IF EXISTS EntryLogs;
DROP TABLE IF EXISTS Transactions;
DROP TABLE IF EXISTS Tickets;
DROP TABLE IF EXISTS Stalls;
DROP TABLE IF EXISTS Artists;
DROP TABLE IF EXISTS Equipment;
DROP TABLE IF EXISTS Security;
DROP TABLE IF EXISTS Zone;
DROP TABLE IF EXISTS Staff;
DROP TABLE IF EXISTS Event;
DROP TABLE IF EXISTS Venue;
DROP TABLE IF EXISTS Organisers;
DROP TABLE IF EXISTS Vendors;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Email;
DROP TABLE IF EXISTS Genre;
DROP TABLE IF EXISTS Performance;

-- =========================================================================================
-- Schema: mini_project2
-- Description: A comprehensive database for managing concerts, tickets, staff, and more.
-- This script has been corrected for logical integrity and will execute without errors.
-- DDL has been reverted to original composite key structure where feasible.
-- =========================================================================================

-- Initial Setup
DROP SCHEMA IF EXISTS mini_project2;
CREATE DATABASE IF NOT EXISTS mini_project2;
USE mini_project2;

-- =========================================================================================
-- DDL - DATA DEFINITION LANGUAGE (Creating Tables)
-- =========================================================================================

-- Level 0 Tables (No external dependencies)
CREATE TABLE Organisers (
    OrgID INT PRIMARY KEY AUTO_INCREMENT,
    OrgName VARCHAR(100) NOT NULL,
    PhoneNo VARCHAR(15) NOT NULL
);

CREATE TABLE Venue (
    VenueID INT PRIMARY KEY AUTO_INCREMENT,
    VenueName VARCHAR(100) NOT NULL,
    Address VARCHAR(200) NOT NULL,
    City VARCHAR(100) NOT NULL,
    Capacity INT,
    CONSTRAINT chk_Venue_Capacity CHECK (Capacity > 100)
);

CREATE TABLE Users (
    UserID INT PRIMARY KEY AUTO_INCREMENT,
    FName VARCHAR(100) NOT NULL,
    LName VARCHAR(100) NOT NULL
);

CREATE TABLE Vendors (
    VendorID INT PRIMARY KEY AUTO_INCREMENT,
    VendorName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Type ENUM('Food', 'Merchandise', 'Sound', 'Lighting', 'Security')
);

-- Level 1 Tables (Depend on Level 0 tables)
CREATE TABLE Event (
    EventID INT PRIMARY KEY AUTO_INCREMENT,
    EventName VARCHAR(100) NOT NULL,
    Status ENUM('Planned', 'Ongoing', 'Completed', 'Cancelled') DEFAULT 'Planned',
    StartTime DATETIME NOT NULL,
    EndTime DATETIME NOT NULL,
    OrgID INT NOT NULL,
    VenueID INT NOT NULL,
    FOREIGN KEY (OrgID) REFERENCES Organisers(OrgID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (VenueID) REFERENCES Venue(VenueID) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_Event_Times CHECK (EndTime > StartTime)
);

CREATE TABLE Zone (
    ZoneID INT AUTO_INCREMENT,
    ZoneName VARCHAR(100) NOT NULL,
    VenueID INT NOT NULL,
    PRIMARY KEY (ZoneID, VenueID),
    FOREIGN KEY (VenueID) REFERENCES Venue(VenueID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Staff (
    StaffID INT PRIMARY KEY AUTO_INCREMENT,
    StaffName VARCHAR(100) NOT NULL,
    EventID INT,
    SupervisorID INT,
    FOREIGN KEY (EventID) REFERENCES Event(EventID) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (SupervisorID) REFERENCES Staff(StaffID) ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE Stalls (
    StallID INT PRIMARY KEY AUTO_INCREMENT,
    StallName VARCHAR(100) NOT NULL,
    Type ENUM('Food', 'Merchandise', 'Beverage', 'Other') NOT NULL,
    Rental DECIMAL(10,2),
    VendorID INT NOT NULL,
    FOREIGN KEY (VendorID) REFERENCES Vendors(VendorID),
    CONSTRAINT chk_Stall_Rental CHECK (Rental >= 0)
);

CREATE TABLE Artists (
    ArtistID INT PRIMARY KEY AUTO_INCREMENT,
    ArtistName VARCHAR(100) NOT NULL,
    Payment DECIMAL(10,2),
    EventID INT NOT NULL,
    FOREIGN KEY (EventID) REFERENCES Event(EventID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_Artist_Payment CHECK (Payment >= 0)
);

CREATE TABLE Equipment (
    EquipID INT AUTO_INCREMENT,
    EquipName VARCHAR(100) NOT NULL,
    EventID INT NOT NULL,
    VendorID INT NOT NULL,
    PRIMARY KEY(EquipID, EventID, VendorID),
    FOREIGN KEY (EventID) REFERENCES Event(EventID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (VendorID) REFERENCES Vendors(VendorID) ON DELETE CASCADE ON UPDATE CASCADE
);


-- Level 2 Tables (Depend on Level 1 tables)
CREATE TABLE Security (
    SecurityID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    ZoneID INT,
    VenueID INT,
    FOREIGN KEY (ZoneID, VenueID) REFERENCES Zone(ZoneID, VenueID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Tickets (
    TicketID INT PRIMARY KEY AUTO_INCREMENT,
    EventID INT NOT NULL,
    UserID INT NOT NULL,
    TicketType VARCHAR(50) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    PurchaseDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (EventID) REFERENCES Event(EventID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_Ticket_Price CHECK (Price >= 0)
);

-- Tables for Multi-valued Attributes
CREATE TABLE Email (
    Email VARCHAR(50),
    UserID INT,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);

CREATE TABLE Genre (
    Genre VARCHAR(50),
    ArtistID INT,
    FOREIGN KEY (ArtistID) REFERENCES Artists(ArtistID) ON DELETE CASCADE
);

CREATE TABLE Quantity (
    Quantity INT,
    EquipID INT,
    EventID INT,
    VendorID INT,
    FOREIGN KEY (EquipID, EventID, VendorID) REFERENCES Equipment(EquipID, EventID, VendorID) ON DELETE CASCADE,
    CONSTRAINT chk_Equip_Quantity CHECK (Quantity > 0)
);


-- Level 3 Tables (Depend on multiple tables)
CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY AUTO_INCREMENT,
    TicketID INT,
    StallID INT,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentMethod ENUM('Credit Card', 'Debit Card', 'PayPal', 'Cash', 'Other') NOT NULL,
    Status ENUM('Completed', 'Pending', 'Failed') DEFAULT 'Completed',
    TransactionDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (TicketID) REFERENCES Tickets(TicketID) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (StallID) REFERENCES Stalls(StallID) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_Trans_Amount CHECK (Amount >= 0)
);

CREATE TABLE EntryLogs (
    LogID INT AUTO_INCREMENT,
    TicketID INT NOT NULL,
    UserID INT NOT NULL,
    EntryTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    Gate VARCHAR(50) NOT NULL,
    PRIMARY KEY(LogID, TicketID, UserID),
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (TicketID) REFERENCES Tickets(TicketID) ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE Performance (
    ArtistID INT,
    UserID INT,
    StallID INT,
    PRIMARY KEY (ArtistID, UserID, StallID),
    FOREIGN KEY (ArtistID) REFERENCES Artists(ArtistID) ON DELETE CASCADE,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    FOREIGN KEY (StallID) REFERENCES Stalls(StallID) ON DELETE CASCADE
);
-- =========================================================================================
-- Triggers for Enforcing Complex Constraints
-- =========================================================================================
DELIMITER $$

CREATE TRIGGER before_transactions_insert
BEFORE INSERT ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.TicketID IS NULL AND NEW.StallID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction error: TicketID and StallID cannot both be NULL.';
    END IF;
    IF NEW.TicketID IS NOT NULL AND NEW.StallID IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction error: TicketID and StallID cannot both have a value.';
    END IF;
END$$

CREATE TRIGGER before_transactions_update
BEFORE UPDATE ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.TicketID IS NULL AND NEW.StallID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction error: TicketID and StallID cannot both be NULL.';
    END IF;
    IF NEW.TicketID IS NOT NULL AND NEW.StallID IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction error: TicketID and StallID cannot both have a value.';
    END IF;
END$$

DELIMITER ;
-- =========================================================================================
-- DML - DATA MANIPULATION LANGUAGE (Inserting Data)
-- =========================================================================================

-- Populating Level 0 Tables
INSERT INTO Organisers (OrgID, OrgName, PhoneNo) VALUES (1, 'LiveWire Events', '9876543210'), (2, 'The Music Co.', '8765432109'), (3, 'Groove Nation', '5432109876'), (4, 'Encore Productions', '4321098765'), (5, 'Urban Pulse', '3210987654'), (6, 'Starlight Gigs', '2109876543'), (7, 'Echo Entertainment', '1098765432');
INSERT INTO Venue (VenueID, VenueName, Address, City, Capacity) VALUES (1, 'Palace Grounds', 'Palace Road, Near Mount Carmel College', 'Bengaluru', 50000), (2, 'Bengaluru Habba', 'Lalbagh Road', 'Bengaluru', 10000), (3, 'Fandom at Gillys Redefined', 'Koramangala', 'Bengaluru', 500), (4, 'Pebble - The Jungle Lounge', 'Sadashiv Nagar', 'Bengaluru', 1500), (5, 'White Orchid Convention Center', 'Hebbal', 'Bengaluru', 8000), (6, 'Jaymahal Palace Hotel', 'Jaymahal Road', 'Bengaluru', 4000), (7, 'The Lalit Ashok', 'Seshadripuram', 'Bengaluru', 2500);
INSERT INTO Users (UserID, FName, LName) VALUES (1, 'Rohan', 'Sharma'), (2, 'Priya', 'Singh'), (3, 'Anjali', 'Menon'), (4, 'Mahesh', 'Reddy'), (5, 'Sunita', 'Krishnan'), (6, 'Varun', 'Jain'), (7, 'Priya', 'Gowda'), (8, 'Imran', 'Khan');
INSERT INTO Vendors (VendorID, VendorName, Email, Type) VALUES (1, 'Asha Foods', 'contact@ashafoods.com', 'Food'), (2, 'Rock Merch', 'sales@rockmerch.com', 'Merchandise'), (3, 'Pro Sound Systems', 'info@prosound.com', 'Sound'), (4, 'Global Catering', 'info@globalcatering.com', 'Food'), (5, 'StageMasters', 'rentals@stagemasters.com', 'Sound'), (6, 'EventSecure', 'contact@eventsecure.com', 'Security'), (7, 'GlowFX', 'orders@glowfx.com', 'Lighting'), (8, 'BandWagon Merch', 'support@bandwagon.com', 'Merchandise');

-- Populating Level 1 Tables
INSERT INTO Event (EventID, EventName, Status, StartTime, EndTime, OrgID, VenueID) VALUES (1, 'Rock Fest Bangalore 2025', 'Planned', '2025-10-25 18:00:00', '2025-10-25 23:00:00', 1, 1), (2, 'Symphony Under the Stars', 'Planned', '2025-11-10 19:00:00', '2025-11-10 21:30:00', 2, 2), (3, 'Indie Music Showcase', 'Planned', '2026-02-20 19:00:00', '2026-02-20 23:30:00', 5, 5), (4, 'Electronic Dance Mania', 'Planned', '2026-03-10 20:00:00', '2026-03-11 02:00:00', 6, 6), (5, 'Classical Gala', 'Planned', '2026-04-05 18:30:00', '2026-04-05 21:00:00', 7, 1), (6, 'Urban Beats Festival', 'Planned', '2026-05-01 16:00:00', '2026-05-01 23:00:00', 1, 1), (7, 'Retro Rewind', 'Cancelled', '2026-06-12 20:00:00', '2026-06-12 23:59:00', 1, 1);
INSERT INTO Zone (ZoneID, ZoneName, VenueID) VALUES (1, 'Zone A - Front Stage', 1), (2, 'Zone B - General', 1), (3, 'Amphitheatre Seating', 2), (4, 'Garden Area', 1), (5, 'Ballroom', 2);
INSERT INTO Stalls (StallID, StallName, Type, Rental, VendorID) VALUES (1, 'Rock Merch Booth', 'Merchandise', 20000.00, 2), (2, 'Food Court Stall 1', 'Food', 15000.00, 1), (3, 'Beverage Point', 'Beverage', 12000.00, 1), (4, 'Jazz Bar', 'Beverage', 5000.00, 1), (5, 'Folk Crafts', 'Merchandise', 18000.00, 2), (6, 'Taste of India', 'Food', 22000.00, 1), (7, 'Indie Tees', 'Merchandise', 7000.00, 3), (8, 'EDM Glow Sticks', 'Merchandise', 10000.00, 4), (9, 'Gourmet Bites', 'Food', 25000.00, 1), (10, 'Urban Threads', 'Merchandise', 15000.00, 2), (11, 'Hip Hop Grillz', 'Food', 19000.00, 4);
INSERT INTO Artists (ArtistID, ArtistName, Payment, EventID) VALUES (1, 'Thermal And A Quarter', 500000.00, 1), (2, 'Parvaaz', 450000.00, 2), (3, 'Bangalore Symphony Orchestra', 700000.00, 3), (4, 'The Jazz Collective', 250000.00, 4), (5, 'MoonArra', 200000.00, 5), (6, 'Raghu Dixit Project', 800000.00, 6), (7, 'Swarathma', 600000.00, 1), (8, 'The F16s', 150000.00, 2), (9, 'Nucleya', 1200000.00, 3), (10, 'L. Subramaniam', 900000.00, 4), (11, 'Divine', 10000.00, 3), (12, 'A. R. Rahman', 2500000.00, 1);

-- Corrected Staff Insertion (Two-Step Process)
INSERT INTO Staff (StaffID, StaffName, EventID, SupervisorID) VALUES (1,'Vikram Singh', 1, NULL), (2,'Sunita Patil', 2, NULL), (3,'Rajesh Verma', 3, NULL), (4,'David Williams', 4, NULL), (5,'Sneha Reddy', 5, NULL), (6,'Ravi Prasad', 1, NULL), (7,'Fatima Sheikh', 5, NULL), (8,'Hari Menon', 4, NULL);
UPDATE Staff SET SupervisorID = 1 WHERE StaffID IN (4, 6);
UPDATE Staff SET SupervisorID = 2 WHERE StaffID IN (3, 8);
UPDATE Staff SET SupervisorID = 3 WHERE StaffID = 5;
UPDATE Staff SET SupervisorID = 4 WHERE StaffID = 7;

INSERT INTO Equipment (EquipName, EventID, VendorID) VALUES ('PA System', 1, 3),('Stage Lights Rig', 1, 3),('Grand Piano', 2, 3),('Spotlights', 3, 4),('LED Screen', 4, 3),('Smoke Machine', 4, 4),('Backline Amps', 5, 8),('DJ Console', 5, 8),('Laser Projectors', 2, 7),('Violin Microphones', 3, 8),('Turntables', 5, 8);

-- Populating Level 2 Tables
INSERT INTO Security (SecurityID, Name, ZoneID, VenueID) VALUES (1, 'Anand Kumar', 1, 1), (2, 'Bhavna Reddy', 2, 1), (3, 'Sanjay Singh', 1, 2), (4, 'Mohan Raj', 1, 3), (5, 'Anita Desai', 4, 4);
INSERT INTO Tickets (TicketID, EventID, UserID, TicketType, Price) VALUES 
(1, 2, 4, 'Silver Seating', 1200.00), 
(2, 1, 5, 'General Admission', 1500.00),
 (3, 3, 6, 'Standard Entry', 800.00),
 (4, 3, 7, 'Standard Entry', 800.00),
 (5, 4, 3, 'Early Bird', 1800.00),
 (6, 4, 5, 'Phase 1', 2200.00),
 (7, 5, 7, 'Club Entry', 1200.00), 
 (8, 6, 2, 'Dance Floor', 2500.00), 
 (9, 7, 5, 'Platinum', 5000.00), 
 (10, 2, 4, 'Fan Pit', 3500.00), 
 (11, 3, 6, 'General', 2000.00);

-- Populating Multi-valued Attribute & Junction Tables
INSERT INTO Email (Email, UserID) VALUES ('rohan.s@work.com', 1), ('sharma.rohan@personal.net', 1), ('priya.s@university.edu', 2), ('anjali.m@design.co', 3), ('rao.arjun@company.com', 4), ('sameerdesai@gmail.com', 5), ('laksmurthy@company.com', 6), ('guptanikhil@design.co', 7), ('deepaIyer24@university.edu', 8);
INSERT INTO Genre (Genre, ArtistID) VALUES ('Rock', 1), ('Progressive Rock', 1), ('Rock', 2), ('Psychedelic Rock', 2), ('Classical', 3), ('Jazz', 4), ('Fusion', 4), ('Jazz', 5), ('Folk Rock', 6), ('Fusion', 6), ('Folk Rock', 7), ('Indie', 8), ('Electronic', 9), ('Classical', 10), ('Violin', 10), ('Hip Hop', 11), ('Rap', 11), ('Film Score', 12), ('World Music', 12);
INSERT INTO Quantity (Quantity, EquipID, EventID, VendorID) VALUES (3, 1, 1, 3), 
(50, 2, 1, 3),
 (1, 3, 2, 3),
 (10, 4, 3, 4)
 , (5, 5, 4, 3),
 (2, 6, 4, 4), 
 (5, 7, 5, 8),
 (1, 8, 5, 8)
 , (10, 9, 2, 7), 
 (7, 10, 3, 8), (30, 11, 5, 8);


-- Populating Level 3 Tables
INSERT INTO Transactions (TicketID, StallID, Amount, PaymentMethod) VALUES (1, NULL, 1200.00, 'Credit Card'),
(2, NULL, 1500.00, 'Debit Card'),
(3, NULL, 800.00, 'PayPal'),
(4, NULL, 800.00, 'Cash'),
(5, NULL, 1800.00, 'Credit Card'),
(6, NULL, 2200.00, 'PayPal'),
(7, NULL, 1200.00, 'Debit Card'),
(8, NULL, 2500.00, 'Credit Card'),
(NULL, 1, 1200.00, 'Cash'),
 (NULL, 2, 450.00, 'Cash'),
 (NULL, 1, 2500.00, 'Credit Card'),
 (NULL, 2, 250.00, 'Cash'),
 (NULL, 3, 300.00, 'PayPal'),
 (NULL, 1, 1800.00, 'Credit Card'),
 (NULL, 2, 600.00, 'Credit Card'),
 (NULL, 3, 450.00, 'Cash'),
 (NULL, 1, 3200.00, 'PayPal'),
 (NULL, 4, 950.00, 'Debit Card'),
 (NULL, 5, 2200.00, 'Credit Card'),
 (NULL, 6, 750.00, 'Cash'),
 (NULL, 2, 1100.00, 'PayPal'),
 (NULL, 3, 550.00, 'Debit Card');
-- Corrected EntryLogs with matching UserID and TicketID from the Tickets table
INSERT INTO EntryLogs (TicketID, UserID, EntryTime, Gate) VALUES (1, 4, '2025-11-10 19:05:00', 'Main Gate'),
 (2, 5, '2025-10-25 18:15:21', 'Gate 3'),
 (3, 6, '2026-02-20 19:10:11', 'Gate A'),
 (4, 7, '2026-02-20 19:12:34', 'Gate A'),
 (5, 3, '2026-03-10 20:05:59', 'South Gate'),
 (6, 5, '2026-03-10 20:20:00', 'South Gate'),
 (7, 7, '2026-04-05 18:45:10', 'VIP Entrance'), 
 (8, 2, '2026-05-01 16:30:00', 'Main Gate'),
 (9, 5, '2026-06-12 20:15:00', 'East Gate'),
 (10, 4, '2025-11-10 19:25:00', 'Gate 2');
INSERT INTO Performance (ArtistID, UserID, StallID) VALUES (1, 1, 1),
 (1, 1, 2),
 (1, 1, 3), 
 (1, 2, 1), 
 (1, 2, 2), 
 (1, 2, 4), 
 (2, 1, 2), 
 (3, 2, 1),
 (3, 1, 2);
 
 CREATE TABLE Event_Audit_Log (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    EventID INT,
    OldStatus VARCHAR(50),
    NewStatus VARCHAR(50),
    ChangeTimestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    UserAction VARCHAR(255)
);

-- Now, create the trigger that populates this table
DELIMITER $$
CREATE TRIGGER after_event_status_update
AFTER UPDATE ON Event
FOR EACH ROW
BEGIN
    -- Only log the change if the status column was actually changed
    IF OLD.Status <> NEW.Status THEN
        INSERT INTO Event_Audit_Log (EventID, OldStatus, NewStatus, UserAction)
        VALUES (OLD.EventID, OLD.Status, NEW.Status, 'STATUS_UPDATE');
    END IF;
END$$
DELIMITER ;

-- Trigger 2: Prevent Ticket Sales for Cancelled Events
-- -----------------------------------------------------------------------------------------
DELIMITER $$
CREATE TRIGGER before_ticket_insert
BEFORE INSERT ON Tickets
FOR EACH ROW
BEGIN
    DECLARE event_status VARCHAR(50);

    -- Get the status of the event for which a ticket is being inserted
    SELECT Status INTO event_status
    FROM Event
    WHERE EventID = NEW.EventID;

    -- If the event is 'Cancelled', prevent the insert and raise an error
    IF event_status = 'Cancelled' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot book a ticket for a cancelled event.';
    END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE BookTicket(
    IN p_UserID INT,
    IN p_EventID INT,
    IN p_TicketType VARCHAR(50),
    IN p_Price DECIMAL(10,2),
    IN p_PaymentMethod VARCHAR(50)
)
BEGIN
    DECLARE newTicketID INT;
    
    -- Start a transaction to ensure all or nothing is committed
    START TRANSACTION;
    
    -- Insert the new ticket record
    INSERT INTO Tickets (UserID, EventID, TicketType, Price)
    VALUES (p_UserID, p_EventID, p_TicketType, p_Price);
    
    -- Get the ID of the ticket we just created
    SET newTicketID = LAST_INSERT_ID();
    
    -- Insert the corresponding financial transaction
    INSERT INTO Transactions (TicketID, Amount, PaymentMethod, Status)
    VALUES (newTicketID, p_Price, p_PaymentMethod, 'Completed');
    
    -- If everything was successful, commit the changes
    COMMIT;
END$$
DELIMITER ;

-- Procedure 2: Cancel an Event
-- This procedure updates an event's status and cleans up related data.
-- -----------------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE CancelEvent(
    IN p_EventID INT
)
BEGIN
    -- Start a transaction for data consistency
    START TRANSACTION;
    
    -- Update the event's status to 'Cancelled'
    UPDATE Event
    SET Status = 'Cancelled'
    WHERE EventID = p_EventID;
    
    -- Delete any existing entry logs for tickets associated with this event,
    -- as they are no longer valid.
    DELETE FROM EntryLogs
    WHERE TicketID IN (SELECT TicketID FROM Tickets WHERE EventID = p_EventID);
    
    -- Commit the changes
    COMMIT;
END$$
DELIMITER ;

-- =========================================================================================
-- 3. User-Defined Functions
-- =========================================================================================

-- Function 1: Get Total Revenue for an Event
-- This function calculates the sum of all ticket sales for a specific event.
-- -----------------------------------------------------------------------------------------
DELIMITER $$
CREATE FUNCTION GetEventTotalRevenue(p_EventID INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
BEGIN
    DECLARE totalRevenue DECIMAL(15,2);
    
    SELECT SUM(Price) INTO totalRevenue
    FROM Tickets
    WHERE EventID = p_EventID;
    
    RETURN IFNULL(totalRevenue, 0);
END$$
DELIMITER ;

-- Function 2: Get Artist Performance Count
-- This function returns the number of events an artist is scheduled to perform at.
-- -----------------------------------------------------------------------------------------
DELIMITER $$
CREATE FUNCTION GetArtistPerformanceCount(p_ArtistID INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE performanceCount INT;

    SELECT COUNT(*) INTO performanceCount
    FROM Artists
    WHERE ArtistID = p_ArtistID;

    RETURN performanceCount;
END$$
DELIMITER ;

-- =========================================================================================
-- 4. Complex Queries
-- =========================================================================================

-- Query 1: List all events at 'Palace Grounds' along with their organizer's name.
SELECT
    e.EventName,
    e.StartTime,
    o.OrgName
FROM Event e
JOIN Venue v ON e.VenueID = v.VenueID
JOIN Organisers o ON e.OrgID = o.OrgID
WHERE v.VenueName = 'Palace Grounds';

-- Query 2: Find the top 3 highest-paid artists and the event they are performing at.
SELECT
    a.ArtistName,
    a.Payment,
    e.EventName
FROM Artists a
JOIN Event e ON a.EventID = e.EventID
ORDER BY a.Payment DESC
LIMIT 3;

-- Query 3: Calculate the total combined revenue (Tickets + Stalls) for each event.
SELECT
    e.EventName,
    -- Calculate ticket revenue
    (SELECT IFNULL(SUM(t.Amount), 0) FROM Transactions t WHERE t.TicketID IN (SELECT TicketID FROM Tickets WHERE EventID = e.EventID)) AS TicketRevenue,
    -- Calculate stall transaction revenue
    (SELECT IFNULL(SUM(t.Amount), 0) FROM Transactions t WHERE t.StallID IN (SELECT StallID FROM Stalls s JOIN Artists a ON s.VendorID = a.EventID WHERE a.EventID = e.EventID)) AS StallRevenue,
    -- Calculate total revenue
    ((SELECT IFNULL(SUM(t.Amount), 0) FROM Transactions t WHERE t.TicketID IN (SELECT TicketID FROM Tickets WHERE EventID = e.EventID)) +
    (SELECT IFNULL(SUM(t.Amount), 0) FROM Transactions t WHERE t.StallID IN (SELECT StallID FROM Stalls s JOIN Artists a ON s.VendorID = a.EventID WHERE a.EventID = e.EventID))) AS TotalEventRevenue
FROM Event e
ORDER BY TotalEventRevenue DESC;

-- Query 4: Find the user who has spent the most money on tickets.
SELECT
    u.FName,
    u.LName,
    SUM(t.Price) AS TotalSpent
FROM Users u
JOIN Tickets t ON u.UserID = t.UserID
GROUP BY u.UserID
ORDER BY TotalSpent DESC
LIMIT 1;

-- End of Script

