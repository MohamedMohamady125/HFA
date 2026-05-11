-- Schema for database: hfa
CREATE TABLE `athletes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  CONSTRAINT `athletes_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `attendance` (
  `id` int NOT NULL AUTO_INCREMENT,
  `athlete_id` int NOT NULL,
  `branch_id` int NOT NULL,
  `session_date` date NOT NULL,
  `status` enum('present','absent','excused') DEFAULT 'present',
  `recorded_by` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_attendance` (`athlete_id`,`session_date`,`branch_id`),
  KEY `branch_id` (`branch_id`),
  KEY `recorded_by` (`recorded_by`),
  KEY `idx_attendance_athlete_date` (`athlete_id`,`session_date`),
  CONSTRAINT `attendance_ibfk_1` FOREIGN KEY (`athlete_id`) REFERENCES `athletes` (`id`),
  CONSTRAINT `attendance_ibfk_2` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT `attendance_ibfk_3` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=112 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `attendance_backup` (
  `id` int NOT NULL DEFAULT '0',
  `athlete_id` int NOT NULL,
  `branch_id` int NOT NULL,
  `session_date` date NOT NULL,
  `status` enum('present','absent','excused') DEFAULT 'present',
  `recorded_by` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `attendance_backup_2` (
  `id` int NOT NULL DEFAULT '0',
  `athlete_id` int NOT NULL,
  `branch_id` int NOT NULL,
  `session_date` date NOT NULL,
  `status` enum('present','absent','excused') DEFAULT 'present',
  `recorded_by` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `branches` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `address` text,
  `latitude` float DEFAULT NULL,
  `longitude` float DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `video_url` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `practice_days` text,
  `practice_time` varchar(255) DEFAULT NULL,
  `practice_times` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `coach_assignments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `branch_id` int NOT NULL,
  `assigned_by` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `branch_id` (`branch_id`),
  KEY `assigned_by` (`assigned_by`),
  CONSTRAINT `coach_assignments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `coach_assignments_ibfk_2` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT `coach_assignments_ibfk_3` FOREIGN KEY (`assigned_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `device_tokens` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `token` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `device_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `health_logs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `athlete_id` int NOT NULL,
  `height_cm` float DEFAULT NULL,
  `weight_kg` float DEFAULT NULL,
  `body_fat_percent` float DEFAULT NULL,
  `muscle_mass_percent` float DEFAULT NULL,
  `water_percent` float DEFAULT NULL,
  `arm_length` float DEFAULT NULL,
  `leg_length` float DEFAULT NULL,
  `notes` text,
  `logged_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `athlete_id` (`athlete_id`),
  CONSTRAINT `health_logs_ibfk_1` FOREIGN KEY (`athlete_id`) REFERENCES `athletes` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `massage_bookings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `athlete_id` int NOT NULL,
  `service_type` varchar(100) DEFAULT NULL,
  `appointment_time` datetime DEFAULT NULL,
  `status` enum('pending','confirmed','completed','cancelled') DEFAULT 'pending',
  `created_by` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `athlete_id` (`athlete_id`),
  KEY `massage_created_by_fk` (`created_by`),
  CONSTRAINT `massage_bookings_ibfk_1` FOREIGN KEY (`athlete_id`) REFERENCES `athletes` (`id`),
  CONSTRAINT `massage_created_by_fk` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `measurement_logs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `athlete_id` int NOT NULL,
  `height` float DEFAULT NULL,
  `weight` float DEFAULT NULL,
  `arm` float DEFAULT NULL,
  `leg` float DEFAULT NULL,
  `fat` float DEFAULT NULL,
  `muscle` float DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `athlete_id` (`athlete_id`),
  CONSTRAINT `measurement_logs_ibfk_1` FOREIGN KEY (`athlete_id`) REFERENCES `athletes` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `notifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `message` text,
  `read_status` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `type` enum('info','reminder','alert') DEFAULT 'info',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `payments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `athlete_id` int NOT NULL,
  `session_date` date DEFAULT NULL,
  `due_date` date NOT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `status` enum('pending','paid','late') DEFAULT 'pending',
  `paid_at` datetime DEFAULT NULL,
  `confirmed_by_coach` tinyint(1) DEFAULT '0',
  `branch_id` int DEFAULT NULL,
  `confirmed_by_user_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `athlete_id` (`athlete_id`),
  KEY `fk_branch` (`branch_id`),
  KEY `fk_confirmed_by_user` (`confirmed_by_user_id`),
  CONSTRAINT `fk_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`),
  CONSTRAINT `fk_confirmed_by_user` FOREIGN KEY (`confirmed_by_user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`athlete_id`) REFERENCES `athletes` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `performance_logs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `athlete_id` int NOT NULL,
  `date_of_birth` date DEFAULT NULL,
  `meet_name` varchar(100) DEFAULT NULL,
  `event_name` varchar(100) DEFAULT NULL,
  `result_time` float DEFAULT NULL,
  `meet_date` date DEFAULT NULL,
  `created_by` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `athlete_id` (`athlete_id`),
  KEY `perf_logs_created_by_fk` (`created_by`),
  CONSTRAINT `perf_logs_created_by_fk` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  CONSTRAINT `performance_logs_ibfk_1` FOREIGN KEY (`athlete_id`) REFERENCES `athletes` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `posts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `thread_id` int NOT NULL,
  `user_id` int NOT NULL,
  `message` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `thread_id` (`thread_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `posts_ibfk_1` FOREIGN KEY (`thread_id`) REFERENCES `threads` (`id`),
  CONSTRAINT `posts_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `practice_sessions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `branch_id` int NOT NULL,
  `day` enum('Mon','Tue','Wed','Thu','Fri','Sat','Sun') DEFAULT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `branch_id` (`branch_id`),
  CONSTRAINT `practice_sessions_ibfk_1` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `registration_requests` (
  `id` int NOT NULL AUTO_INCREMENT,
  `athlete_name` varchar(100) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `submitted_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `approved` tinyint(1) DEFAULT '0',
  `approved_by` int DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `password_hash` varchar(255) DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `branch_name` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `approved_by` (`approved_by`),
  CONSTRAINT `registration_requests_ibfk_1` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `threads` (
  `id` int NOT NULL AUTO_INCREMENT,
  `branch_id` int NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `branch_id` (`branch_id`),
  CONSTRAINT `threads_ibfk_1` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('athlete','coach','head_coach','admin') NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `approved` tinyint(1) DEFAULT '0',
  `branch_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `phone` (`phone`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

