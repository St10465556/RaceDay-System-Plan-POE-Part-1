CREATE DATABASE RaceDay;
USE RaceDay;

-- Table: Users (Base table for all users)

CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Email VARCHAR(100) UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Phone VARCHAR(20),
    Role VARCHAR(20) NOT NULL CHECK (Role IN ('Organiser', 'Participant')),
    DateRegistered DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1,
    LastLogin DATETIME
);

-- Table: Organisers (extends Users)
CREATE TABLE Organisers (
    OrganiserID INT PRIMARY KEY,
    CompanyName VARCHAR(100) NOT NULL,
    CompanyRegistration VARCHAR(50),
    VerificationStatus VARCHAR(20) DEFAULT 'Pending' CHECK (VerificationStatus IN ('Pending', 'Verified', 'Rejected')),
    Website VARCHAR(255),
    Address VARCHAR(255),
    FOREIGN KEY (OrganiserID) REFERENCES Users(UserID) ON DELETE CASCADE
);


-- Table: Participants (extends Users)
CREATE TABLE Participants (
    ParticipantID INT PRIMARY KEY,
    DateOfBirth DATE,
    Gender VARCHAR(10) CHECK (Gender IN ('Male', 'Female', 'Other')),
    EmergencyContact VARCHAR(100),
    EmergencyPhone VARCHAR(20),
    MedicalConditions VARCHAR(MAX),
    ClubAffiliation VARCHAR(100),
    ProfilePicture VARCHAR(255), -- URL to Azure Blob Storage
    FOREIGN KEY (ParticipantID) REFERENCES Users(UserID) ON DELETE CASCADE
);
-- Table: Events

CREATE TABLE Events (
    EventID INT IDENTITY(1,1) PRIMARY KEY,
    OrganiserID INT NOT NULL,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(MAX),
    EventDate DATETIME NOT NULL,
    RegistrationDeadline DATETIME NOT NULL,
    Location VARCHAR(200) NOT NULL,
    MaxParticipants INT DEFAULT 1000,
    Status VARCHAR(20) DEFAULT 'Draft' CHECK (Status IN ('Draft', 'Published', 'Cancelled', 'Completed')),
    BannerImage VARCHAR(255), -- URL to Azure Blob Storage
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (OrganiserID) REFERENCES Organisers(OrganiserID)
);


-- Table: Categories
CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    EventID INT NOT NULL,
    Name VARCHAR(50) NOT NULL, -- e.g., "5km", "10km", "Half Marathon"
    Distance DECIMAL(5,2) NOT NULL, -- in kilometers
    StartTime TIME NOT NULL,
    EntryFee DECIMAL(10,2) NOT NULL DEFAULT 0,
    AgeRestriction VARCHAR(20),
    MaxParticipants INT,
    FOREIGN KEY (EventID) REFERENCES Events(EventID) ON DELETE CASCADE
);

-- Table: Registrations (Enrolments)
CREATE TABLE Registrations (
    RegistrationID INT IDENTITY(1,1) PRIMARY KEY,
    ParticipantID INT NOT NULL,
    EventID INT NOT NULL,
    CategoryID INT NOT NULL,
    RegistrationDate DATETIME DEFAULT GETDATE(),
    Status VARCHAR(20) DEFAULT 'Confirmed' CHECK (Status IN ('Confirmed', 'Waitlist', 'Cancelled')),
    PaymentStatus VARCHAR(20) DEFAULT 'Pending' CHECK (PaymentStatus IN ('Pending', 'Paid', 'Refunded')),
    BibNumber INT UNIQUE, -- Unique race number
    StartTime TIME,
    EmergencyContact VARCHAR(100),
    EmergencyPhone VARCHAR(20),
    MedicalConditions VARCHAR(MAX),
    CONSTRAINT UQ_Participant_Event UNIQUE (ParticipantID, EventID),
    FOREIGN KEY (ParticipantID) REFERENCES Participants(ParticipantID),
    FOREIGN KEY (EventID) REFERENCES Events(EventID),
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);



-- Table: Results
-- ============================================
CREATE TABLE Results (
    ResultID INT IDENTITY(1,1) PRIMARY KEY,
    RegistrationID INT NOT NULL UNIQUE,
    FinishTime TIME NOT NULL, -- Race time
    OverallPosition INT,
    CategoryPosition INT,
    Pace DECIMAL(5,2), -- Minutes per km
    CertificateURL VARCHAR(255), -- Azure Blob Storage URL
    Status VARCHAR(20) DEFAULT 'Pending' CHECK (Status IN ('Pending', 'Verified', 'Disqualified')),
    FOREIGN KEY (RegistrationID) REFERENCES Registrations(RegistrationID) ON DELETE CASCADE
);



-- Table: Weather

CREATE TABLE Weather (
    WeatherID INT IDENTITY(1,1) PRIMARY KEY,
    EventID INT NOT NULL,
    Date DATETIME NOT NULL,
    Temperature DECIMAL(5,2), -- Celsius
    Conditions VARCHAR(50), -- Sunny, Rainy, Cloudy, etc.
    WindSpeed DECIMAL(5,2), -- km/h
    Humidity DECIMAL(5,2), -- Percentage
    LastUpdated DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (EventID) REFERENCES Events(EventID) ON DELETE CASCADE
);


-- Table: Routes
-- ============================================
CREATE TABLE Routes (
    RouteID INT IDENTITY(1,1) PRIMARY KEY,
    EventID INT NOT NULL,
    GPXFileURL VARCHAR(255), -- Azure Blob Storage URL
    ElevationGain DECIMAL(8,2), -- Meters
    StartLatitude DECIMAL(10,8),
    StartLongitude DECIMAL(11,8),
    Description VARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    FOREIGN KEY (EventID) REFERENCES Events(EventID) ON DELETE CASCADE
);
-- Table: Notifications

CREATE TABLE Notifications (
    NotificationID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    Type VARCHAR(50) NOT NULL, -- Email, SMS, Push
    Subject VARCHAR(255) NOT NULL,
    Message VARCHAR(MAX) NOT NULL,
    IsRead BIT DEFAULT 0,
    SentDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);
-- Indexes for Performance
CREATE INDEX IX_Events_OrganiserID ON Events(OrganiserID);
CREATE INDEX IX_Events_EventDate ON Events(EventDate);
CREATE INDEX IX_Events_Status ON Events(Status);
CREATE INDEX IX_Categories_EventID ON Categories(EventID);
CREATE INDEX IX_Registrations_ParticipantID ON Registrations(ParticipantID);
CREATE INDEX IX_Registrations_EventID ON Registrations(EventID);
CREATE INDEX IX_Registrations_Status ON Registrations(Status);
CREATE INDEX IX_Results_RegistrationID ON Results(RegistrationID);
CREATE INDEX IX_Weather_EventID ON Weather(EventID);
CREATE INDEX IX_Routes_EventID ON Routes(EventID);


-- INSERT SAMPLE DATA
-- 1. Insert Users
INSERT INTO Users (Email, PasswordHash, FirstName, LastName, Phone, Role, IsActive)
VALUES 
('john@comrades.co.za', 'hash_john_123', 'John', 'Smith', '+2712345678', 'Organiser', 1),
('sarah@capetowncycle.co.za', 'hash_sarah_456', 'Sarah', 'Johnson', '+2787654321', 'Organiser', 1),
('thabo.participant@gmail.com', 'hash_thabo_789', 'Thabo', 'Mokwena', '+2776123456', 'Participant', 1),
('linda.participant@gmail.com', 'hash_linda_321', 'Linda', 'Naidoo', '+2776123789', 'Participant', 1);

-- 2. Insert Organisers
INSERT INTO Organisers (OrganiserID, CompanyName, CompanyRegistration, VerificationStatus, Website)
VALUES 
(1, 'Comrades Marathon Association', 'REG-1234-2024', 'Verified', 'www.comradesmarathon.org.za'),
(2, 'Cape Town Cycle Tour Trust', 'REG-5678-2024', 'Verified', 'www.capetowncycletour.com');

-- 3. Insert Participants
INSERT INTO Participants (ParticipantID, DateOfBirth, Gender, EmergencyContact, EmergencyPhone, MedicalConditions, ClubAffiliation)
VALUES 
(3, '1990-05-15', 'Male', 'Grace Mokwena', '+2776123457', 'None', 'Soweto Athletics Club'),
(4, '1985-12-20', 'Female', 'Kevin Naidoo', '+2776123790', 'Asthma - mild', 'Durban Running Club');

-- 4. Insert Events
INSERT INTO Events (OrganiserID, Name, Description, EventDate, RegistrationDeadline, Location, MaxParticipants, Status, BannerImage)
VALUES 
(1, 'Comrades Marathon 2026', 'The Ultimate Human Race - 90km ultramarathon from Pietermaritzburg to Durban', '2026-06-15 05:30:00', '2026-05-01 23:59:59', 'Pietermaritzburg to Durban', 25000, 'Published', 'comrades_banner.jpg'),
(1, 'Durban 10km Challenge', 'Fast flat 10km road race along Durban beachfront', '2026-03-20 06:00:00', '2026-03-01 23:59:59', 'Durban Beachfront', 5000, 'Published', 'durban10km_banner.jpg'),
(2, 'Cape Town Cycle Tour 2026', 'The largest timed cycling event in the world - 109km around the Cape Peninsula', '2026-03-08 06:00:00', '2026-02-01 23:59:59', 'Cape Town, starting at Grand Parade', 35000, 'Published', 'ctct_banner.jpg');

-- 5. Insert Categories for Events
-- Comrades Marathon Categories
INSERT INTO Categories (EventID, Name, Distance, StartTime, EntryFee, AgeRestriction, MaxParticipants)
VALUES 
(1, 'Up Run', 90.00, '05:30:00', 800.00, 'Age 20+', 15000),
(1, 'Down Run', 90.00, '05:30:00', 800.00, 'Age 20+', 10000);

-- Durban 10km Categories
INSERT INTO Categories (EventID, Name, Distance, StartTime, EntryFee, AgeRestriction, MaxParticipants)
VALUES 
(2, '10km Open', 10.00, '06:00:00', 150.00, 'Age 16+', 3000),
(2, '10km Junior', 10.00, '06:30:00', 75.00, 'Age 10-15', 2000);

-- Cape Town Cycle Tour Categories
INSERT INTO Categories (EventID, Name, Distance, StartTime, EntryFee, AgeRestriction, MaxParticipants)
VALUES 
(3, 'Standard', 109.00, '06:00:00', 550.00, 'Age 16+', 30000),
(3, 'Elite', 109.00, '05:45:00', 1000.00, 'Age 18+', 1000),
(3, 'Charity', 109.00, '06:15:00', 1200.00, 'Age 16+', 4000);
G

-- 6. Insert Registrations
INSERT INTO Registrations (ParticipantID, EventID, CategoryID, Status, PaymentStatus, BibNumber, EmergencyContact, EmergencyPhone, MedicalConditions)
VALUES 
(3, 1, 1, 'Confirmed', 'Paid', 1001, 'Grace Mokwena', '+2776123457', 'None'),
(4, 1, 2, 'Confirmed', 'Paid', 1002, 'Kevin Naidoo', '+2776123790', 'Asthma - mild'),
(3, 2, 3, 'Confirmed', 'Paid', 2001, 'Grace Mokwena', '+2776123457', 'None'),
(4, 3, 5, 'Confirmed', 'Pending', 3001, 'Kevin Naidoo', '+2776123790', 'Asthma - mild');

-- 7. Insert Results
INSERT INTO Results (RegistrationID, FinishTime, OverallPosition, CategoryPosition, Pace, Status)
VALUES 
(1, '07:45:32', 1234, 567, 5.10, 'Verified'),
(2, '08:12:15', 2345, 890, 5.47, 'Verified'),
(3, '00:42:30', 45, 12, 4.25, 'Verified');

-- 8. Insert Weather Data
INSERT INTO Weather (EventID, Date, Temperature, Conditions, WindSpeed, Humidity)
VALUES 
(1, '2026-06-15 05:00:00', 18.5, 'Cloudy', 12.0, 75.0),
(2, '2026-03-20 06:00:00', 22.0, 'Sunny', 5.0, 65.0),
(3, '2026-03-08 06:00:00', 19.0, 'Partly Cloudy', 15.0, 70.0);

-- 9. Insert Routes
INSERT INTO Routes (EventID, GPXFileURL, ElevationGain, StartLatitude, StartLongitude, Description)
VALUES 
(1, 'comrades_2026_route.gpx', 850.00, -29.6167, 30.3833, 'Up Run route from Pietermaritzburg to Durban'),
(2, 'durban_10km_route.gpx', 50.00, -29.8587, 31.0218, 'Flat beachfront route'),
(3, 'ctct_2026_route.gpx', 1200.00, -33.9249, 18.4241, 'Classic Cape Peninsula route including Chapmans Peak');

-- 10. Insert Notifications
INSERT INTO Notifications (UserID, Type, Subject, Message)
VALUES 
(3, 'Email', 'Race Day Reminder', 'Your race day is tomorrow! Please arrive 1 hour before start time.'),
(4, 'Email', 'Registration Confirmed', 'Your registration for Comrades Marathon 2026 has been confirmed. Your bib number is #1002');

SELECT * FROM Users;
SELECT * FROM Organisers;
SELECT * FROM Participants;
SELECT * FROM Events;
SELECT * FROM Categories;
SELECT * FROM Registrations;
SELECT * FROM Results;
SELECT * FROM Weather;
SELECT * FROM Routes;
SELECT * FROM Notifications;