-- =============================================================
-- UniGreen database (MySQL 8) - schema + sample data
-- Run in MySQL Workbench, then: Database > Reverse Engineer
-- All sample accounts use password: password123
-- =============================================================
DROP DATABASE IF EXISTS unigreen;
CREATE DATABASE unigreen CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE unigreen;

-- Students and admins (matches models.py -> User)
CREATE TABLE users (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  full_name     VARCHAR(100) NOT NULL,
  email         VARCHAR(120) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role          ENUM('student','admin') NOT NULL DEFAULT 'student',
  green_points  INT NOT NULL DEFAULT 0,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Recycling bins placed around campus
CREATE TABLE bins (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  bin_code   VARCHAR(20) NOT NULL UNIQUE,
  location   VARCHAR(150) NOT NULL,
  bin_type   ENUM('plastic','paper','metal','mixed') NOT NULL,
  status     ENUM('active','full','maintenance') NOT NULL DEFAULT 'active',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Green events created by admins (bonus points during the event)
CREATE TABLE green_events (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  title            VARCHAR(120) NOT NULL,
  description      TEXT,
  start_date       DATE NOT NULL,
  end_date         DATE NOT NULL,
  bonus_multiplier DECIMAL(3,1) NOT NULL DEFAULT 2.0,
  created_by       INT NOT NULL,
  CONSTRAINT fk_event_admin FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- Each time a student recycles items at a bin
CREATE TABLE recycle_logs (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  user_id        INT NOT NULL,
  bin_id         INT NOT NULL,
  event_id       INT NULL,
  item_type      ENUM('plastic_bottle','can','paper','glass') NOT NULL,
  quantity       INT NOT NULL,
  points_awarded INT NOT NULL DEFAULT 0,
  photo_proof    VARCHAR(255) NULL,
  status         ENUM('pending','verified','rejected') NOT NULL DEFAULT 'pending',
  verified_by    INT NULL,
  logged_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_log_user     FOREIGN KEY (user_id)     REFERENCES users(id),
  CONSTRAINT fk_log_bin      FOREIGN KEY (bin_id)      REFERENCES bins(id),
  CONSTRAINT fk_log_event    FOREIGN KEY (event_id)    REFERENCES green_events(id),
  CONSTRAINT fk_log_verifier FOREIGN KEY (verified_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- Cafe rewards students can buy with Green Points
CREATE TABLE rewards (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  title       VARCHAR(120) NOT NULL,
  cafe_name   VARCHAR(100) NOT NULL,
  points_cost INT NOT NULL,
  stock       INT NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- A reward redeemed by a student -> coupon code shown at the cafe
CREATE TABLE redemptions (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  user_id      INT NOT NULL,
  reward_id    INT NOT NULL,
  coupon_code  VARCHAR(20) NOT NULL UNIQUE,
  points_spent INT NOT NULL,
  status       ENUM('issued','used','expired') NOT NULL DEFAULT 'issued',
  confirmed_by INT NULL,
  redeemed_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  used_at      DATETIME NULL,
  CONSTRAINT fk_red_user   FOREIGN KEY (user_id)      REFERENCES users(id),
  CONSTRAINT fk_red_reward FOREIGN KEY (reward_id)    REFERENCES rewards(id),
  CONSTRAINT fk_red_admin  FOREIGN KEY (confirmed_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- Students report a full / damaged bin
CREATE TABLE bin_reports (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  user_id     INT NOT NULL,
  bin_id      INT NOT NULL,
  issue       ENUM('full','damaged','misplaced','other') NOT NULL,
  description VARCHAR(255),
  status      ENUM('open','resolved') NOT NULL DEFAULT 'open',
  resolved_by INT NULL,
  reported_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at DATETIME NULL,
  CONSTRAINT fk_rep_user  FOREIGN KEY (user_id)     REFERENCES users(id),
  CONSTRAINT fk_rep_bin   FOREIGN KEY (bin_id)      REFERENCES bins(id),
  CONSTRAINT fk_rep_admin FOREIGN KEY (resolved_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- Pickup requests for the recycling partner to empty a bin
CREATE TABLE pickup_requests (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  bin_id       INT NOT NULL,
  requested_by INT NOT NULL,
  partner_name VARCHAR(100) NOT NULL,
  status       ENUM('requested','scheduled','completed') NOT NULL DEFAULT 'requested',
  pickup_date  DATE NULL,
  requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pick_bin  FOREIGN KEY (bin_id)       REFERENCES bins(id),
  CONSTRAINT fk_pick_user FOREIGN KEY (requested_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- ---------- sample data ----------
INSERT INTO users (full_name,email,password_hash,role,green_points,created_at) VALUES
  ('Ali Raza','ali.raza@uet.edu.pk','$2b$12$N/ej5YaLpPJHw6kGD9VtJ.YWQ0XBNa/feVM1M8qQcJCUte17BNYcK','admin',0,'2026-08-23 09:00:00'),
  ('Sana Malik','sana.malik@uet.edu.pk','$2b$12$N/ej5YaLpPJHw6kGD9VtJ.YWQ0XBNa/feVM1M8qQcJCUte17BNYcK','admin',0,'2026-08-24 09:00:00'),
  ('Fizza Fatima','fizza.fatima@student.uet.edu.pk','$2b$12$N/ej5YaLpPJHw6kGD9VtJ.YWQ0XBNa/feVM1M8qQcJCUte17BNYcK','student',60,'2026-08-25 09:00:00'),
  ('Charisma Angel','charisma.angel@student.uet.edu.pk','$2b$12$N/ej5YaLpPJHw6kGD9VtJ.YWQ0XBNa/feVM1M8qQcJCUte17BNYcK','student',20,'2026-08-26 09:00:00'),
  ('Irta Rehman','irta.rehman@student.uet.edu.pk','$2b$12$N/ej5YaLpPJHw6kGD9VtJ.YWQ0XBNa/feVM1M8qQcJCUte17BNYcK','student',50,'2026-08-27 09:00:00'),
  ('Ahmed Khan','ahmed.khan@student.uet.edu.pk','$2b$12$N/ej5YaLpPJHw6kGD9VtJ.YWQ0XBNa/feVM1M8qQcJCUte17BNYcK','student',0,'2026-08-28 09:00:00'),
  ('Ayesha Siddiqui','ayesha.siddiqui@student.uet.edu.pk','$2b$12$N/ej5YaLpPJHw6kGD9VtJ.YWQ0XBNa/feVM1M8qQcJCUte17BNYcK','student',120,'2026-08-29 09:00:00'),
  ('Hamza Tariq','hamza.tariq@student.uet.edu.pk','$2b$12$N/ej5YaLpPJHw6kGD9VtJ.YWQ0XBNa/feVM1M8qQcJCUte17BNYcK','student',160,'2026-08-30 09:00:00'),
  ('Zainab Hussain','zainab.hussain@student.uet.edu.pk','$2b$12$N/ej5YaLpPJHw6kGD9VtJ.YWQ0XBNa/feVM1M8qQcJCUte17BNYcK','student',60,'2026-08-31 09:00:00'),
  ('Usman Ali','usman.ali@student.uet.edu.pk','$2b$12$N/ej5YaLpPJHw6kGD9VtJ.YWQ0XBNa/feVM1M8qQcJCUte17BNYcK','student',25,'2026-08-22 09:00:00'),
  ('Maryam Iqbal','maryam.iqbal@student.uet.edu.pk','$2b$12$N/ej5YaLpPJHw6kGD9VtJ.YWQ0XBNa/feVM1M8qQcJCUte17BNYcK','student',95,'2026-08-23 09:00:00'),
  ('Bilal Ahmed','bilal.ahmed@student.uet.edu.pk','$2b$12$N/ej5YaLpPJHw6kGD9VtJ.YWQ0XBNa/feVM1M8qQcJCUte17BNYcK','student',160,'2026-08-24 09:00:00'),
  ('Hira Javed','hira.javed@student.uet.edu.pk','$2b$12$N/ej5YaLpPJHw6kGD9VtJ.YWQ0XBNa/feVM1M8qQcJCUte17BNYcK','student',60,'2026-08-25 09:00:00'),
  ('Saad Qureshi','saad.qureshi@student.uet.edu.pk','$2b$12$N/ej5YaLpPJHw6kGD9VtJ.YWQ0XBNa/feVM1M8qQcJCUte17BNYcK','student',40,'2026-08-26 09:00:00');

INSERT INTO bins (bin_code,location,bin_type,status) VALUES
  ('UG-B01','Main Cafeteria entrance','plastic','active'),
  ('UG-B02','Main Cafeteria back side','mixed','full'),
  ('UG-B03','Computer Engineering Dept. ground floor','plastic','active'),
  ('UG-B04','Central Library lobby','paper','active'),
  ('UG-B05','Electrical Engineering Dept. corridor','metal','active'),
  ('UG-B06','Girls Hostel gate','plastic','maintenance'),
  ('UG-B07','Sports Complex','plastic','active'),
  ('UG-B08','Admin Block parking','mixed','active'),
  ('UG-B09','Mechanical Engineering Dept. lawn','plastic','active'),
  ('UG-B10','Student Service Centre','paper','active');

INSERT INTO green_events (title,description,start_date,end_date,bonus_multiplier,created_by) VALUES
  ('Clean Campus Week','Double points on every verified recycling entry.','2026-10-05','2026-10-11',2.0,1),
  ('Earth Hour Drive','Bonus points for plastic bottles and cans.','2026-11-02','2026-11-04',1.5,2);

INSERT INTO recycle_logs (user_id,bin_id,event_id,item_type,quantity,points_awarded,photo_proof,status,verified_by,logged_at) VALUES
  (12,1,NULL,'plastic_bottle',1,10,NULL,'verified',2,'2026-09-02 09:08:00'),
  (11,2,NULL,'glass',5,75,'uploads/proof_018.jpg','verified',2,'2026-09-02 10:55:00'),
  (10,9,NULL,'plastic_bottle',6,60,'uploads/proof_060.jpg','verified',2,'2026-09-02 17:43:00'),
  (8,3,NULL,'plastic_bottle',6,60,'uploads/proof_001.jpg','verified',1,'2026-09-04 10:52:00'),
  (14,6,NULL,'plastic_bottle',3,0,'uploads/proof_044.jpg','pending',NULL,'2026-09-04 11:27:00'),
  (9,8,NULL,'paper',6,0,'uploads/proof_028.jpg','rejected',2,'2026-09-06 11:10:00'),
  (7,7,NULL,'plastic_bottle',1,10,NULL,'verified',1,'2026-09-06 15:55:00'),
  (11,2,NULL,'plastic_bottle',2,20,NULL,'verified',1,'2026-09-07 10:16:00'),
  (10,5,NULL,'can',2,20,NULL,'verified',1,'2026-09-07 14:47:00'),
  (11,8,NULL,'can',4,40,NULL,'verified',2,'2026-09-07 15:42:00'),
  (4,10,NULL,'paper',3,15,'uploads/proof_005.jpg','verified',1,'2026-09-07 17:45:00'),
  (8,10,NULL,'paper',4,20,NULL,'verified',2,'2026-09-08 10:54:00'),
  (4,4,NULL,'paper',2,10,'uploads/proof_017.jpg','verified',1,'2026-09-08 14:38:00'),
  (10,10,NULL,'paper',5,25,'uploads/proof_032.jpg','verified',2,'2026-09-09 17:09:00'),
  (14,5,NULL,'can',4,40,'uploads/proof_053.jpg','verified',2,'2026-09-12 11:17:00'),
  (5,10,NULL,'paper',2,10,'uploads/proof_033.jpg','verified',1,'2026-09-12 11:30:00'),
  (5,5,NULL,'can',2,20,NULL,'verified',2,'2026-09-13 13:40:00'),
  (10,6,NULL,'plastic_bottle',1,10,'uploads/proof_025.jpg','verified',2,'2026-09-15 10:14:00'),
  (5,5,NULL,'can',4,0,'uploads/proof_039.jpg','pending',NULL,'2026-09-15 10:25:00'),
  (5,2,NULL,'can',2,20,'uploads/proof_014.jpg','verified',2,'2026-09-15 12:00:00'),
  (9,2,NULL,'can',6,60,NULL,'verified',2,'2026-09-20 10:57:00'),
  (11,6,NULL,'plastic_bottle',1,10,'uploads/proof_054.jpg','verified',1,'2026-09-20 12:22:00'),
  (12,1,NULL,'plastic_bottle',1,10,'uploads/proof_056.jpg','verified',1,'2026-09-20 13:40:00'),
  (11,5,NULL,'can',2,0,NULL,'pending',NULL,'2026-09-22 12:53:00'),
  (10,9,NULL,'plastic_bottle',3,30,'uploads/proof_048.jpg','verified',1,'2026-09-23 09:16:00'),
  (13,3,NULL,'plastic_bottle',6,60,'uploads/proof_029.jpg','verified',1,'2026-09-23 11:35:00'),
  (13,2,NULL,'glass',5,75,'uploads/proof_022.jpg','verified',2,'2026-09-24 11:22:00'),
  (11,1,NULL,'plastic_bottle',5,50,'uploads/proof_021.jpg','verified',2,'2026-09-24 11:44:00'),
  (10,9,NULL,'plastic_bottle',4,40,'uploads/proof_016.jpg','verified',1,'2026-09-26 15:06:00'),
  (7,3,NULL,'plastic_bottle',4,40,'uploads/proof_012.jpg','verified',2,'2026-09-26 16:05:00'),
  (11,4,NULL,'paper',2,10,'uploads/proof_037.jpg','verified',1,'2026-09-27 10:25:00'),
  (12,6,NULL,'plastic_bottle',5,0,'uploads/proof_031.jpg','pending',NULL,'2026-09-27 11:03:00'),
  (3,9,NULL,'plastic_bottle',3,30,'uploads/proof_004.jpg','verified',1,'2026-09-27 11:34:00'),
  (5,7,NULL,'plastic_bottle',6,0,NULL,'pending',NULL,'2026-09-27 14:43:00'),
  (9,4,NULL,'paper',2,0,NULL,'pending',NULL,'2026-09-28 14:05:00'),
  (11,4,NULL,'paper',1,5,'uploads/proof_002.jpg','verified',1,'2026-09-28 15:04:00'),
  (13,4,NULL,'paper',6,30,'uploads/proof_040.jpg','verified',2,'2026-09-28 17:25:00'),
  (11,8,NULL,'plastic_bottle',1,0,NULL,'rejected',1,'2026-09-29 14:39:00'),
  (7,7,NULL,'plastic_bottle',1,10,'uploads/proof_011.jpg','verified',1,'2026-09-30 14:10:00'),
  (10,9,NULL,'plastic_bottle',3,30,NULL,'verified',1,'2026-09-30 16:23:00'),
  (4,10,NULL,'paper',5,25,NULL,'verified',1,'2026-10-02 14:46:00'),
  (10,5,NULL,'can',2,20,'uploads/proof_055.jpg','verified',2,'2026-10-03 09:05:00'),
  (7,1,1,'plastic_bottle',4,80,NULL,'verified',1,'2026-10-05 14:39:00'),
  (14,5,1,'can',5,0,NULL,'rejected',2,'2026-10-05 16:32:00'),
  (8,9,1,'plastic_bottle',1,20,'uploads/proof_034.jpg','verified',1,'2026-10-06 09:15:00'),
  (4,6,1,'plastic_bottle',3,60,'uploads/proof_041.jpg','verified',2,'2026-10-06 16:28:00'),
  (3,2,1,'glass',1,30,'uploads/proof_045.jpg','verified',1,'2026-10-09 12:04:00'),
  (8,9,1,'plastic_bottle',3,60,'uploads/proof_046.jpg','verified',1,'2026-10-10 11:02:00'),
  (12,2,1,'can',6,120,'uploads/proof_003.jpg','verified',1,'2026-10-11 09:36:00'),
  (12,10,NULL,'paper',4,20,NULL,'verified',1,'2026-10-12 14:51:00'),
  (4,5,NULL,'can',6,60,'uploads/proof_010.jpg','verified',2,'2026-10-13 10:03:00'),
  (11,10,NULL,'paper',3,15,NULL,'verified',1,'2026-10-15 14:38:00'),
  (3,9,NULL,'plastic_bottle',6,0,NULL,'pending',NULL,'2026-10-15 17:08:00'),
  (13,10,NULL,'paper',3,15,NULL,'verified',1,'2026-10-17 16:09:00'),
  (4,9,NULL,'plastic_bottle',2,0,'uploads/proof_008.jpg','rejected',1,'2026-10-19 14:09:00'),
  (10,6,NULL,'plastic_bottle',1,10,NULL,'verified',2,'2026-10-21 13:30:00'),
  (11,3,NULL,'plastic_bottle',2,20,'uploads/proof_030.jpg','verified',1,'2026-10-23 12:01:00'),
  (7,3,NULL,'plastic_bottle',6,60,NULL,'verified',2,'2026-10-23 13:25:00'),
  (13,4,NULL,'paper',2,0,'uploads/proof_023.jpg','pending',NULL,'2026-10-23 15:47:00'),
  (5,7,NULL,'plastic_bottle',1,0,NULL,'pending',NULL,'2026-10-24 11:00:00');

INSERT INTO rewards (title,cafe_name,points_cost,stock) VALUES
  ('10% off any drink','Main Cafeteria',50,100),
  ('Free tea','Main Cafeteria',80,60),
  ('Free samosa plate','Main Cafeteria',120,40),
  ('25% off lunch combo','Food Court',200,30),
  ('Free fries','Food Court',150,25),
  ('Free coffee','Library Cafe',180,20);

INSERT INTO redemptions (user_id,reward_id,coupon_code,points_spent,status,confirmed_by,redeemed_at,used_at) VALUES
  (11,5,'UGC-0001H',150,'used',2,'2026-10-03 17:00:00','2026-10-03 22:00:00'),
  (4,5,'UGC-0004E',150,'used',1,'2026-10-05 14:00:00','2026-10-05 15:00:00'),
  (10,3,'UGC-0007D',120,'expired',NULL,'2026-10-13 13:00:00',NULL),
  (10,1,'UGC-0005B',50,'expired',NULL,'2026-10-16 14:00:00',NULL),
  (10,1,'UGC-0006B',50,'used',2,'2026-10-18 13:00:00','2026-10-18 15:00:00'),
  (7,2,'UGC-0002H',80,'used',2,'2026-10-24 18:00:00','2026-10-25 19:00:00'),
  (13,3,'UGC-0003D',120,'issued',NULL,'2026-10-25 12:00:00',NULL);

INSERT INTO bin_reports (user_id,bin_id,issue,description,status,resolved_by,reported_at,resolved_at) VALUES
  (3,2,'full','Bin overflowing after lunch.','resolved',1,'2026-10-14 13:20:00','2026-10-14 17:00:00'),
  (6,6,'damaged','Lid is broken.','open',NULL,'2026-10-20 10:05:00',NULL),
  (9,1,'full','Bottles lying around the bin.','resolved',2,'2026-10-22 14:40:00','2026-10-22 16:10:00'),
  (5,8,'misplaced','Bin moved behind the parking shed.','open',NULL,'2026-10-25 09:30:00',NULL),
  (4,2,'full','Full again before evening.','open',NULL,'2026-10-26 15:45:00',NULL);

INSERT INTO pickup_requests (bin_id,requested_by,partner_name,status,pickup_date,requested_at) VALUES
  (2,1,'GreenCycle Lahore','completed','2026-10-15','2026-10-14 17:05:00'),
  (1,2,'GreenCycle Lahore','completed','2026-10-23','2026-10-22 16:15:00'),
  (4,1,'PaperBack Recyclers','scheduled','2026-10-29','2026-10-26 11:00:00'),
  (2,2,'GreenCycle Lahore','requested',NULL,'2026-10-27 09:10:00');
