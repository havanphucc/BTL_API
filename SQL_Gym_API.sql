CREATE DATABASE GymManagement;
GO

USE GymManagement;
GO

-- 1. USERS (Thêm CHECK 3 vai trò, Soft-delete cho NFR)
CREATE TABLE Users
(
    UserID NVARCHAR(20) PRIMARY KEY,
    Username NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    RoleUser NVARCHAR(50) NOT NULL CHECK (RoleUser IN ('Admin', 'Member', 'Trainer'))
);

-- 2. MEMBERS
CREATE TABLE Members
(
    MemberID NVARCHAR(20) PRIMARY KEY,
    UserID NVARCHAR(20) UNIQUE,
    Name_M NVARCHAR(200) NOT NULL,
    Phone_M NVARCHAR(15),
    Email_M NVARCHAR(200) NOT NULL,
    Status_M NVARCHAR(20) DEFAULT 'Active', -- Active, Inactive
    CONSTRAINT FK_Members_Users FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- 3. MEMBERSHIP PLANS
CREATE TABLE MemberShipPlans
(
    PlanID NVARCHAR(20) PRIMARY KEY,
    PlanName NVARCHAR(100) UNIQUE NOT NULL,
    Duration INT NOT NULL,
    DurationType NVARCHAR(50) NOT NULL, -- Days, Months, Years
    Plan_price DECIMAL(18,2) NOT NULL
);

-- 4. MEMBERSHIPS
CREATE TABLE MemberShips
(
    MemberShipID NVARCHAR(20) PRIMARY KEY,
    MemberID NVARCHAR(20) NOT NULL,
    PlanID NVARCHAR(20) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    Status_MS NVARCHAR(20) DEFAULT 'Active', -- Active, Expired, Cancelled
    CONSTRAINT FK_MemberShips_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
    CONSTRAINT FK_MemberShips_Plans FOREIGN KEY (PlanID) REFERENCES MemberShipPlans(PlanID)
);

-- 5. TRAINERS
CREATE TABLE Trainers
(
    TrainerID NVARCHAR(20) PRIMARY KEY,
    UserID NVARCHAR(20) UNIQUE,
    Name_T NVARCHAR(200) NOT NULL,
    Gender_T NVARCHAR(20) NOT NULL,
    Phone_T NVARCHAR(15) NOT NULL,
    Email_T NVARCHAR(200) NOT NULL,
    Expertise NVARCHAR(100) NOT NULL,
    CONSTRAINT FK_Trainers_Users FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- 6. FACILITIES
CREATE TABLE Facilities
(
    FacilityID NVARCHAR(20) PRIMARY KEY,
    Name_F NVARCHAR(100) NOT NULL,
    Address_F NVARCHAR(500)
);

-- 7. SCHEDULES
CREATE TABLE Schedules
(
    ScheduleID NVARCHAR(20) PRIMARY KEY,
    MemberID NVARCHAR(20) NOT NULL,
    TrainerID NVARCHAR(20) NOT NULL,
    FacilityID NVARCHAR(20) NOT NULL,
    StartTime DATETIME2 NOT NULL,
    EndTime DATETIME2 NOT NULL,
    Status_SCH NVARCHAR(20) DEFAULT 'Scheduled', -- Scheduled, Completed, Cancelled
    CONSTRAINT FK_Schedules_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
    CONSTRAINT FK_Schedules_Trainers FOREIGN KEY (TrainerID) REFERENCES Trainers(TrainerID),
    CONSTRAINT FK_Schedules_Facilities FOREIGN KEY (FacilityID) REFERENCES Facilities(FacilityID)
);

-- 8. SESSIONS
CREATE TABLE Sessions_S
(
    SessionID NVARCHAR(20) PRIMARY KEY,
    ScheduleID NVARCHAR(20) NOT NULL,
    Notes_S NVARCHAR(MAX), -- PT ghi chú thông tin buổi tập
    CONSTRAINT FK_Sessions_Schedules FOREIGN KEY (ScheduleID) REFERENCES Schedules(ScheduleID)
);

-- 9. CHECKINS (Hỗ trợ QR Code)
CREATE TABLE Checkins
(
    CheckID NVARCHAR(20) PRIMARY KEY,
    MemberID NVARCHAR(20) NOT NULL,
    SessionID NVARCHAR(20) NOT NULL,
    CheckInTime DATETIME2 NOT NULL DEFAULT GETDATE(),
    CheckOutTime DATETIME2,
    CONSTRAINT FK_Checkins_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
    CONSTRAINT FK_Checkins_Sessions FOREIGN KEY (SessionID) REFERENCES Sessions_S(SessionID)
);

-- 10. INVOICES
CREATE TABLE Invoices
(
    InvoiceID NVARCHAR(20) PRIMARY KEY,
    MemberID NVARCHAR(20) NOT NULL,
    MemberShipID NVARCHAR(20) NOT NULL,
    OriginalAmount DECIMAL(18,2) NOT NULL,
    DiscountAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    TotalAmount DECIMAL(18,2) NOT NULL,
    Status_INV NVARCHAR(20) DEFAULT 'Unpaid', -- Unpaid, Paid, Cancelled
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Invoices_Members FOREIGN KEY (MemberID) REFERENCES Members(MemberID),
    CONSTRAINT FK_Invoices_MemberShips FOREIGN KEY (MemberShipID) REFERENCES MemberShips(MemberShipID)
);

-- 11. PAYMENTS
CREATE TABLE Payments
(
    PaymentID NVARCHAR(20) PRIMARY KEY,
    InvoiceID NVARCHAR(20) NOT NULL,
    Payment_Date DATETIME2 NOT NULL DEFAULT GETDATE(),
    Amount DECIMAL(18,2) NOT NULL,
    Payment_Methods NVARCHAR(100) NOT NULL, -- Cash, Transfer, CreditCard
    CONSTRAINT FK_Payments_Invoices FOREIGN KEY (InvoiceID) REFERENCES Invoices(InvoiceID)
);

-- 12. AUDIT LOGS (Nhật ký thay đổi gói dịch vụ)
CREATE TABLE Auditlogs
(
    AuditlogID NVARCHAR(20) PRIMARY KEY,
    UserID NVARCHAR(20) NOT NULL,
    MemberShipID NVARCHAR(20) NOT NULL,
    OldPlanID NVARCHAR(20) NOT NULL,
    NewPlanID NVARCHAR(20) NOT NULL,
    Action_AL NVARCHAR(100),
    ChangeAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Auditlogs_Users FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_Auditlogs_MemberShips FOREIGN KEY (MemberShipID) REFERENCES MemberShips(MemberShipID),
    CONSTRAINT FK_Auditlogs_OldPlan FOREIGN KEY (OldPlanID) REFERENCES MemberShipPlans(PlanID),
    CONSTRAINT FK_Auditlogs_NewPlan FOREIGN KEY (NewPlanID) REFERENCES MemberShipPlans(PlanID)
);
GO



drop database GymManagement

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE sp_Insert_user (@UserID NVARCHAR(20),@Username NVARCHAR(100),@PasswordHash NVARCHAR(255)
,@RoleUser NVARCHAR(50))
AS
	BEGIN
		INSERT INTO Users(UserID,Username,PasswordHash,RoleUser)
		VALUES (@UserID,@Username,@PasswordHash,@RoleUser);
	END;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE sp_Delete_user (@UserID NVARCHAR(20))
AS
BEGIN
DELETE Users WHERE UserID = @UserID;
END;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE sp_Update_user (@UserID NVARCHAR(20),@Username NVARCHAR(100),@PasswordHash NVARCHAR(255),@RoleUser NVARCHAR(50))
AS
	BEGIN
	  UPDATE Users
	  set
	  Username = @Username,
	  PasswordHash = @PasswordHash,
	  RoleUser = @RoleUser
	  where UserID = @UserID	
	End
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE sp_user_get_by_username_password (@Username NVARCHAR(100),@PasswordHash NVARCHAR(255))
AS
BEGIN
 SELECT UserID,Username,RoleUser,IsDeleted
 FROM Users
 WHERE Username = @Username and PasswordHash = @PasswordHash;
END
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE sp_user_get_by_id(@UserID NVARCHAR(20))
AS
BEGIN
SELECT *
FROM Users
where UserID = @UserID
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE sp_Search_user
(
    @page_index INT,
    @page_size  INT,
    @username   NVARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RecordCount BIGINT;

    -- 1. Đếm tổng số bản ghi thỏa mãn điều kiện lọc
    SELECT @RecordCount = COUNT(*)
    FROM Users
    WHERE IsDeleted = 0
      AND RoleUser <> 'Admin' -- Bỏ qua tài khoản Admin (giữ lại logic của bạn)
      AND (@username IS NULL OR @username = '' OR Username LIKE '%' + @username + '%');

    -- 2. Truy vấn phân trang
    IF (@page_size > 0)
    BEGIN
        SELECT 
            UserID,
            Username,
            PasswordHash,
            RoleUser,
            IsDeleted,
            @RecordCount AS RecordCount
        FROM Users
        WHERE IsDeleted = 0
          AND RoleUser <> 'Admin'
          AND (@username IS NULL OR @username = '' OR Username LIKE '%' + @username + '%')
        ORDER BY UserID ASC
        OFFSET (@page_index - 1) * @page_size ROWS
        FETCH NEXT @page_size ROWS ONLY;
    END
    ELSE
    BEGIN
        -- Nếu @page_size = 0 thì lấy toàn bộ
        SELECT 
            UserID,
            Username,
            PasswordHash,
            RoleUser,
            IsDeleted,
            @RecordCount AS RecordCount
        FROM Users
        WHERE IsDeleted = 0
          AND RoleUser <> 'Admin'
          AND (@username IS NULL OR @username = '' OR Username LIKE '%' + @username + '%')
        ORDER BY UserID ASC;
    END
END;
GO


EXEC sp_Insert_user 
    @UserID = 'USR004', 
    @Username = 'm_gym4', 
    @PasswordHash = '123456', 
    @RoleUser = 'Member';

EXEC sp_Delete_user
@UserID = 'USR003'
DELETE Users
SELECT * FROM Users
DROP PROCEDURE sp_Insert_user
DROP PROCEDURE sp_Delete_user
Drop PROCEDURE sp_Search_user

EXEC sp_Update_user
 @Username = 'Member_Gym',
 @PasswordHash = '456789',
 @RoleUser = 'Member',
 @UserID = 'USR002'

SELECT 
    m.MemberID,
    m.Name_M AS MemberName,
    m.Phone_M,
    sch.ScheduleID,
    sch.StartTime,
    sch.EndTime,
    sch.Status_SCH,
    ss.SessionID,
    ss.Notes_S
FROM Members m
INNER JOIN Schedules sch ON m.MemberID = sch.MemberID
INNER JOIN Sessions_S ss ON sch.ScheduleID = ss.ScheduleID;

Select * From Users
Select * from Members





SELECT MemberID,UserID,Name_M,Phone_M,Email_M,Status_M FROM Members