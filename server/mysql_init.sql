-- AICam Coach MySQL 数据库初始化脚本
-- 数据库: aicam_db
-- 字符集: utf8mb4 (支持emoji和中文)

CREATE DATABASE IF NOT EXISTS aicam_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE aicam_db;

-- ============================================
-- 1. 用户表 (users)
-- ============================================
DROP TABLE IF EXISTS `usage_logs`;
DROP TABLE IF EXISTS `user_templates`;
DROP TABLE IF EXISTS `templates`;
DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
  `id` VARCHAR(36) NOT NULL COMMENT 'UUID主键',
  `username` VARCHAR(50) NOT NULL COMMENT '用户名',
  `email` VARCHAR(100) NOT NULL COMMENT '邮箱',
  `password` VARCHAR(255) NOT NULL COMMENT 'bcrypt加密密码',
  `role` ENUM('admin', 'user') DEFAULT 'user' COMMENT '角色',
  `avatar` VARCHAR(500) DEFAULT NULL COMMENT '头像URL',
  `is_active` TINYINT(1) DEFAULT 1 COMMENT '是否启用: 1=启用, 0=禁用',
  `usage_count` INT DEFAULT 0 COMMENT '累计使用次数',
  `last_login_at` DATETIME DEFAULT NULL COMMENT '最后登录时间',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  UNIQUE KEY `uk_email` (`email`),
  KEY `idx_role` (`role`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- ============================================
-- 2. 服务端模板表 (templates)
-- ============================================
CREATE TABLE `templates` (
  `id` VARCHAR(36) NOT NULL COMMENT 'UUID主键',
  `name` VARCHAR(100) NOT NULL COMMENT '模板名称',
  `category` VARCHAR(30) NOT NULL COMMENT '分类: portrait/landscape/food/pet/street/still_life/custom',
  `thumbnail_url` VARCHAR(500) NOT NULL COMMENT '缩略图路径 /uploads/xxx.png',
  `tags` JSON DEFAULT NULL COMMENT '标签数组 JSON格式',
  `composition_rules` JSON DEFAULT NULL COMMENT '构图规则 JSON格式',
  `camera_params` JSON DEFAULT NULL COMMENT '相机参数建议 JSON格式',
  `uploaded_by` VARCHAR(36) NOT NULL COMMENT '上传者用户ID',
  `is_active` TINYINT(1) DEFAULT 1 COMMENT '是否启用: 1=启用, 0=已删除',
  `usage_count` INT DEFAULT 0 COMMENT '被使用次数',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_category` (`category`),
  KEY `idx_uploaded_by` (`uploaded_by`),
  KEY `idx_is_active` (`is_active`),
  KEY `idx_usage_count` (`usage_count`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务端参考模板表';

-- ============================================
-- 3. 用户自定义模板表 (user_templates)
-- ============================================
CREATE TABLE `user_templates` (
  `id` VARCHAR(36) NOT NULL COMMENT 'UUID主键',
  `user_id` VARCHAR(36) NOT NULL COMMENT '所属用户ID',
  `custom_name` VARCHAR(100) DEFAULT '自定义参考图' COMMENT '自定义名称',
  `image_url` VARCHAR(500) NOT NULL COMMENT '图片路径 /uploads/xxx.png',
  `category` VARCHAR(30) DEFAULT 'custom' COMMENT '分类',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户自定义参考图表';

-- ============================================
-- 4. 使用日志表 (usage_logs)
-- ============================================
CREATE TABLE `usage_logs` (
  `id` VARCHAR(36) NOT NULL COMMENT 'UUID主键',
  `user_id` VARCHAR(36) NOT NULL COMMENT '操作用户ID',
  `action` VARCHAR(50) NOT NULL COMMENT '操作类型: LOGIN/REGISTER/UPLOAD_TEMPLATE/DELETE_TEMPLATE/AI_ANALYSIS等',
  `details` JSON DEFAULT NULL COMMENT '操作详情 JSON格式',
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT '客户端IP',
  `user_agent` VARCHAR(500) DEFAULT NULL COMMENT '客户端UA',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_action` (`action`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_user_action` (`user_id`, `action`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户操作日志表';

-- ============================================
-- 插入默认管理员账号
-- 密码: admin123 (bcrypt hash)
-- ============================================
INSERT INTO `users` (`id`, `username`, `email`, `password`, `role`, `is_active`) VALUES
('admin-default-001', 'admin', 'admin@aicam.com', '$2a$10$ZMNGE.1eN8qHr1zK/K3pBesXowMLb7MdA0lpgVjgJ4A9jVAjCNe9C', 'admin', 1);

-- ============================================
-- 插入测试用户账号
-- 密码: test123 (bcrypt hash)
-- ============================================
INSERT INTO `users` (`id`, `username`, `email`, `password`, `role`, `is_active`) VALUES
('test-user-001', 'test', 'test@aicam.com', '$2a$10$xdxptH8KmR4Lic.qUSlOO.rpHPOLrMa03kjg/GlgZwGCMBAL61/9i', 'user', 1);

-- 迁移现有数据（如果有）
-- INSERT INTO templates SELECT * FROM ...;
