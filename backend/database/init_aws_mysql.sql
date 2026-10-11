-- Auto-generated MySQL Dump from Azure for AWS Local MySQL
CREATE DATABASE IF NOT EXISTS skin_disease_db;
USE skin_disease_db;

CREATE DATABASE IF NOT EXISTS skin_disease_db;
USE skin_disease_db;

CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT UNIQUE,
    user_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) PRIMARY KEY ,
    password VARCHAR(255) NOT NULL,
    profile_picture VARCHAR(255) DEFAULT NULL,
    reset_code VARCHAR(6),
    reset_code_expires DATETIME
);

CREATE TABLE IF NOT EXISTS images (
    image_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    capture_method ENUM('Camera','Gallery') NOT NULL,
    image_path VARCHAR(255) NOT NULL,
    upload_date DATE NOT NULL,
    upload_time TIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS diseases (
    disease_id INT PRIMARY KEY,
    disease_name VARCHAR(100) NOT NULL UNIQUE
);

INSERT INTO diseases (disease_id, disease_name) VALUES
(0, 'Other'),
(1, 'Tinea Corporis'),
(2, 'Tinea Cruris'),
(3, 'Tinea Versicolor')
ON DUPLICATE KEY UPDATE disease_name=VALUES(disease_name);

CREATE TABLE IF NOT EXISTS detections (
    detection_id INT AUTO_INCREMENT PRIMARY KEY,
    image_id INT NOT NULL UNIQUE,
    disease_id INT NOT NULL,
    disease_class VARCHAR(100) NOT NULL,
    confidence_score DECIMAL(5,2) NOT NULL,
    detection_date DATE NOT NULL,
    detection_time TIME NOT NULL,
    FOREIGN KEY (image_id) REFERENCES images(image_id) ON DELETE CASCADE,
    FOREIGN KEY (disease_id) REFERENCES diseases(disease_id)
);

CREATE TABLE IF NOT EXISTS heatmaps (
    heatmap_id INT AUTO_INCREMENT PRIMARY KEY,
    detection_id INT NOT NULL UNIQUE,
    heat_map_status ENUM('Generated','Pending','Failed') DEFAULT 'Pending',
    heatmap_path VARCHAR(255),
    generated_date DATE,
    generated_time TIME,
    FOREIGN KEY (detection_id) REFERENCES detections(detection_id) ON DELETE CASCADE
);


-- Data for users
INSERT IGNORE INTO `users` (`user_id`, `user_name`, `email`, `password`, `profile_picture`, `reset_code`, `reset_code_expires`) VALUES ('2', 'Aathif', 'mohamedthaslim@gmail.com', '3730d3b80da802fe7e127f51f0480202a492fb900d3b6fa19e38b7268ccc0706', NULL, '585554', '2026-09-27 10:55:21');
INSERT IGNORE INTO `users` (`user_id`, `user_name`, `email`, `password`, `profile_picture`, `reset_code`, `reset_code_expires`) VALUES ('1', 'TestUser', 'testuser_1790520085003@example.com', 'd85fb61a933e0b8a45f88c89888502573a3d318657a576ef5529bf948b98882c', NULL, NULL, NULL);

-- Data for images
INSERT IGNORE INTO `images` (`image_id`, `user_id`, `capture_method`, `image_path`, `upload_date`, `upload_time`) VALUES ('2', '2', 'Gallery', '/uploads/image-1790523120929-561057091.jpg', '2026-09-26 18:30:00', '15:32:01');
INSERT IGNORE INTO `images` (`image_id`, `user_id`, `capture_method`, `image_path`, `upload_date`, `upload_time`) VALUES ('3', '2', 'Gallery', '/uploads/image-1790523140903-20552362.jpg', '2026-09-26 18:30:00', '15:32:21');
INSERT IGNORE INTO `images` (`image_id`, `user_id`, `capture_method`, `image_path`, `upload_date`, `upload_time`) VALUES ('4', '2', 'Gallery', '/uploads/image-1790523159643-502412920.jpg', '2026-09-26 18:30:00', '15:32:46');
INSERT IGNORE INTO `images` (`image_id`, `user_id`, `capture_method`, `image_path`, `upload_date`, `upload_time`) VALUES ('5', '2', 'Gallery', '/uploads/image-1790523191213-234131782.jpg', '2026-09-26 18:30:00', '15:33:11');
INSERT IGNORE INTO `images` (`image_id`, `user_id`, `capture_method`, `image_path`, `upload_date`, `upload_time`) VALUES ('6', '2', 'Gallery', '/uploads/image-1790523206744-586637637.jpg', '2026-09-26 18:30:00', '15:33:26');

-- Data for diseases
INSERT IGNORE INTO `diseases` (`disease_id`, `disease_name`) VALUES ('0', 'Other');
INSERT IGNORE INTO `diseases` (`disease_id`, `disease_name`) VALUES ('1', 'Tinea Corporis');
INSERT IGNORE INTO `diseases` (`disease_id`, `disease_name`) VALUES ('2', 'Tinea Cruris');
INSERT IGNORE INTO `diseases` (`disease_id`, `disease_name`) VALUES ('3', 'Tinea Versicolor');

-- Data for detections
INSERT IGNORE INTO `detections` (`detection_id`, `image_id`, `disease_id`, `disease_class`, `confidence_score`, `detection_date`, `detection_time`) VALUES ('1', '2', '0', 'Other', '46.82', '2026-09-26 18:30:00', '15:32:01');
INSERT IGNORE INTO `detections` (`detection_id`, `image_id`, `disease_id`, `disease_class`, `confidence_score`, `detection_date`, `detection_time`) VALUES ('2', '3', '1', 'Tinea Corporis', '84.35', '2026-09-26 18:30:00', '15:32:21');
INSERT IGNORE INTO `detections` (`detection_id`, `image_id`, `disease_id`, `disease_class`, `confidence_score`, `detection_date`, `detection_time`) VALUES ('3', '4', '0', 'Other', '86.27', '2026-09-26 18:30:00', '15:32:46');
INSERT IGNORE INTO `detections` (`detection_id`, `image_id`, `disease_id`, `disease_class`, `confidence_score`, `detection_date`, `detection_time`) VALUES ('4', '5', '3', 'Tinea Versicolor', '98.35', '2026-09-26 18:30:00', '15:33:11');
INSERT IGNORE INTO `detections` (`detection_id`, `image_id`, `disease_id`, `disease_class`, `confidence_score`, `detection_date`, `detection_time`) VALUES ('5', '6', '1', 'Tinea Corporis', '71.37', '2026-09-26 18:30:00', '15:33:26');

-- Data for heatmaps
INSERT IGNORE INTO `heatmaps` (`heatmap_id`, `detection_id`, `heat_map_status`, `heatmap_path`, `generated_date`, `generated_time`) VALUES ('1', '1', 'Generated', '/heatmaps/heatmap-1-1790523124938.jpg', '2026-09-26 18:30:00', '15:32:01');
INSERT IGNORE INTO `heatmaps` (`heatmap_id`, `detection_id`, `heat_map_status`, `heatmap_path`, `generated_date`, `generated_time`) VALUES ('2', '2', 'Generated', '/heatmaps/heatmap-2-1790523144413.jpg', '2026-09-26 18:30:00', '15:32:21');
INSERT IGNORE INTO `heatmaps` (`heatmap_id`, `detection_id`, `heat_map_status`, `heatmap_path`, `generated_date`, `generated_time`) VALUES ('3', '3', 'Generated', '/heatmaps/heatmap-3-1790523171570.jpg', '2026-09-26 18:30:00', '15:32:46');
INSERT IGNORE INTO `heatmaps` (`heatmap_id`, `detection_id`, `heat_map_status`, `heatmap_path`, `generated_date`, `generated_time`) VALUES ('4', '4', 'Generated', '/heatmaps/heatmap-4-1790523194412.jpg', '2026-09-26 18:30:00', '15:33:11');
INSERT IGNORE INTO `heatmaps` (`heatmap_id`, `detection_id`, `heat_map_status`, `heatmap_path`, `generated_date`, `generated_time`) VALUES ('5', '5', 'Generated', '/heatmaps/heatmap-5-1790523209480.jpg', '2026-09-26 18:30:00', '15:33:26');

