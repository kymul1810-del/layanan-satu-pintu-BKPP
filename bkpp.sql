-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 31, 2026 at 12:39 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `bkpp`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ticket_accept_fo` (IN `p_code` VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci, IN `p_fo_user_id` BIGINT UNSIGNED, IN `p_target_bidang_id` INT UNSIGNED)   BEGIN
  -- isi body procedure tetap sama seperti sebelumnya
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ticket_assign_to_petugas` (IN `p_code` VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci, IN `p_petugas_user_id` BIGINT UNSIGNED, IN `p_by_user` BIGINT UNSIGNED)   BEGIN
    DECLARE v_tid BIGINT UNSIGNED;
    DECLARE v_old VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

    SELECT id, status
      INTO v_tid, v_old
    FROM tickets
    WHERE code = p_code COLLATE utf8mb4_unicode_ci
    FOR UPDATE;

    INSERT INTO assignments(
        ticket_id,
        assigned_to_user_id,
        assigned_by_user_id,
        status,
        note,
        assigned_at
    )
    VALUES (
        v_tid,
        p_petugas_user_id,
        p_by_user,
        'IN_PROGRESS',
        'Diproses petugas',
        NOW()
    );

    UPDATE tickets
    SET status = 'DALAM_PROSES',
        updated_at = NOW()
    WHERE id = v_tid;

    INSERT INTO status_history(ticket_id, old_status, new_status, changed_by, comment)
    VALUES (v_tid, v_old, 'DALAM_PROSES', p_by_user, 'Penugasan ke petugas');
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ticket_request_more_data` (IN `p_code` VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci, IN `p_user` BIGINT UNSIGNED, IN `p_comment` TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci)   BEGIN
    CALL sp_ticket_update_status(
        p_code,
        'MENUNGGU_DATA',
        p_user,
        p_comment
    );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_ticket_update_status` (IN `p_code` VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci, IN `p_new_status` VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci, IN `p_changed_by` BIGINT UNSIGNED, IN `p_comment` TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci)   BEGIN
    DECLARE v_tid BIGINT UNSIGNED;
    DECLARE v_old VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    DECLARE v_applicant BIGINT UNSIGNED;

    SELECT id, status, applicant_id
      INTO v_tid, v_old, v_applicant
    FROM tickets
    WHERE code = p_code COLLATE utf8mb4_unicode_ci
    FOR UPDATE;

    UPDATE tickets
    SET status = p_new_status COLLATE utf8mb4_unicode_ci,
        updated_at = NOW()
    WHERE id = v_tid;

    INSERT INTO status_history(ticket_id, old_status, new_status, changed_by, comment)
    VALUES (v_tid, v_old, p_new_status, p_changed_by, p_comment);

    IF p_new_status COLLATE utf8mb4_unicode_ci IN ('MENUNGGU_DATA','SELESAI','DITOLAK') THEN
        INSERT INTO notifications(recipient_applicant_id, type, ref_ticket_id, message)
        VALUES (
            v_applicant,
            'STATUS_CHANGE',
            v_tid,
            CONCAT('Status tiket ', p_new_status,
                   IFNULL(CONCAT(': ', LEFT(p_comment, 200)), ''))
        );
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `applicants`
--

CREATE TABLE `applicants` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `nik` varchar(32) DEFAULT NULL,
  `name` varchar(128) NOT NULL,
  `email` varchar(191) DEFAULT NULL,
  `phone` varchar(64) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `applicants`
--

INSERT INTO `applicants` (`id`, `nik`, `name`, `email`, `phone`, `address`, `created_at`) VALUES
(1, '3201xxxxxxxxxxxx', 'Budi Pemohon', 'budi@example.local', '0812xxxx', 'Jl. Contoh No. 1', '2025-10-29 08:44:41'),
(2, NULL, 'kymul', 'kymul1810@gmail.com', '085158815848', 'sigambal', '2025-10-29 08:54:34'),
(3, NULL, 'rizky mulia', 'ranrogore69@gmail.com', '085158815848', 'sigambal', '2025-10-29 09:53:40'),
(4, NULL, 'rizal', 'fo1@example.local', '08467475547', 'papua', '2025-10-30 02:33:48'),
(5, NULL, 'rizky mulia', '', '082134535467', 'aektapa', '2026-03-05 15:24:13'),
(6, NULL, 'rizky mulia', 'kor-a@example.local', '082134535467', 'aektapa', '2026-04-10 14:25:07');

-- --------------------------------------------------------

--
-- Table structure for table `assignments`
--

CREATE TABLE `assignments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ticket_id` bigint(20) UNSIGNED NOT NULL,
  `assigned_to_user_id` int(10) UNSIGNED DEFAULT NULL,
  `assigned_by_user_id` int(10) UNSIGNED DEFAULT NULL,
  `status` varchar(16) NOT NULL,
  `note` varchar(255) DEFAULT NULL,
  `assigned_at` datetime NOT NULL DEFAULT current_timestamp(),
  `unassigned_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `assignments`
--

INSERT INTO `assignments` (`id`, `ticket_id`, `assigned_to_user_id`, `assigned_by_user_id`, `status`, `note`, `assigned_at`, `unassigned_at`) VALUES
(1, 1, NULL, 1, 'DONE', 'Menunggu penugasan koordinator', '2025-10-29 15:44:41', '2025-10-29 15:44:41'),
(2, 1, 3, 2, 'DONE', 'Diproses petugas', '2025-10-29 15:44:41', '2025-10-29 16:03:32'),
(3, 2, NULL, 1, 'DONE', 'Menunggu penugasan koordinator', '2025-10-29 15:58:00', '2025-10-29 15:59:26'),
(4, 2, 3, 2, 'DONE', 'Diproses petugas', '2025-10-29 15:59:26', '2025-10-29 15:59:32'),
(5, 2, 3, 2, 'DONE', 'Diproses petugas', '2025-10-29 15:59:32', '2025-10-29 16:03:34'),
(6, 1, 3, 2, 'IN_PROGRESS', 'Diproses petugas', '2025-10-29 16:03:32', NULL),
(7, 2, 3, 2, 'IN_PROGRESS', 'Diproses petugas', '2025-10-29 16:03:34', NULL),
(8, 3, 3, 2, '', NULL, '2025-10-29 17:01:07', NULL),
(9, 6, 6, 5, '', NULL, '2025-10-29 17:23:03', NULL),
(10, 7, 3, 2, '', NULL, '2025-10-29 18:46:11', NULL),
(11, 7, 3, 2, '', NULL, '2025-10-29 18:46:14', NULL),
(12, 9, 3, 2, '', NULL, '2025-10-30 09:35:01', NULL),
(13, 9, 3, 2, '', NULL, '2025-10-30 09:35:05', NULL),
(14, 8, 3, 2, '', NULL, '2026-03-05 21:36:02', NULL),
(15, 10, 3, 2, '', NULL, '2026-03-05 21:36:04', NULL),
(16, 8, 3, 2, '', NULL, '2026-03-05 23:09:27', NULL),
(17, 8, 3, 2, '', NULL, '2026-03-05 23:09:33', NULL),
(18, 10, 3, 2, '', NULL, '2026-03-05 23:09:35', NULL),
(19, 8, 3, 2, '', NULL, '2026-03-05 23:09:55', NULL),
(20, 10, 3, 2, '', NULL, '2026-03-05 23:09:56', NULL),
(21, 12, 3, 2, '', NULL, '2026-03-05 23:09:57', NULL),
(22, 13, 3, 2, '', NULL, '2026-03-05 23:14:10', NULL),
(23, 14, 3, 2, '', NULL, '2026-03-06 22:16:05', NULL),
(24, 15, 3, 2, '', NULL, '2026-03-06 22:27:45', NULL),
(25, 16, 3, 2, '', NULL, '2026-03-06 22:36:50', NULL),
(26, 17, 3, 2, '', NULL, '2026-03-06 22:43:30', NULL),
(27, 18, 3, 2, '', NULL, '2026-03-06 23:08:37', NULL),
(28, 19, 3, 2, '', NULL, '2026-03-07 22:45:53', NULL),
(29, 20, 3, 2, '', NULL, '2026-03-07 22:56:03', NULL),
(30, 21, 3, 2, '', NULL, '2026-03-07 23:03:27', NULL),
(31, 22, 3, 2, '', NULL, '2026-03-07 23:54:37', NULL),
(32, 23, 3, 2, '', NULL, '2026-03-08 21:22:21', NULL),
(33, 24, 3, 2, '', NULL, '2026-03-08 21:32:59', NULL),
(34, 25, 3, 2, '', NULL, '2026-03-08 21:47:02', NULL),
(35, 26, 3, 2, '', NULL, '2026-03-08 21:47:04', NULL),
(36, 28, 3, 2, '', NULL, '2026-03-08 22:12:38', NULL),
(37, 27, 3, 2, '', NULL, '2026-03-08 22:33:40', NULL),
(38, 29, 3, 2, '', NULL, '2026-03-08 22:47:57', NULL),
(39, 30, 3, 2, '', NULL, '2026-03-08 23:05:05', NULL),
(40, 31, 3, 2, '', NULL, '2026-03-08 23:28:22', NULL),
(41, 32, 3, 2, '', NULL, '2026-03-09 00:09:21', NULL),
(42, 33, 3, 2, '', NULL, '2026-03-09 00:24:50', NULL),
(43, 34, 3, 2, '', NULL, '2026-03-09 08:02:18', NULL),
(44, 35, 3, 2, '', NULL, '2026-04-01 22:43:20', NULL),
(45, 36, 3, 2, '', NULL, '2026-04-06 15:14:21', NULL),
(46, 42, 3, NULL, '', NULL, '2026-04-09 19:05:39', NULL),
(47, 43, 3, NULL, '', NULL, '2026-04-10 22:22:56', NULL),
(48, 44, 3, NULL, '', NULL, '2026-04-10 22:22:57', NULL),
(49, 45, 3, NULL, '', NULL, '2026-04-10 22:22:58', NULL),
(50, 46, 3, NULL, '', NULL, '2026-04-10 22:23:02', NULL),
(51, 42, 3, NULL, '', NULL, '2026-04-10 22:50:45', NULL),
(52, 41, 4, NULL, '', NULL, '2026-04-10 22:54:49', NULL),
(53, 39, 4, NULL, '', NULL, '2026-04-10 23:15:07', NULL),
(54, 37, 4, NULL, '', NULL, '2026-04-10 23:17:23', NULL),
(55, 47, 3, NULL, '', NULL, '2026-04-11 00:06:33', NULL),
(56, 47, 4, NULL, '', NULL, '2026-04-11 00:06:46', NULL),
(57, 48, 2, 1, 'IN_PROGRESS', 'Menunggu penugasan koordinator', '2026-04-15 22:59:31', NULL),
(58, 48, 3, NULL, '', NULL, '2026-04-15 23:00:59', NULL),
(59, 48, 4, NULL, '', NULL, '2026-04-15 23:07:18', NULL),
(60, 50, 2, 1, 'IN_PROGRESS', 'Menunggu penugasan koordinator', '2026-04-15 23:08:37', NULL),
(61, 50, 3, NULL, '', NULL, '2026-04-15 23:08:49', NULL),
(62, 50, 4, NULL, '', NULL, '2026-04-15 23:09:00', NULL),
(63, 51, 2, 1, 'IN_PROGRESS', 'Menunggu penugasan koordinator', '2026-04-15 23:20:13', NULL),
(64, 51, 6, 2, 'IN_PROGRESS', 'Diproses petugas', '2026-04-15 23:46:27', NULL),
(65, 51, 4, NULL, '', NULL, '2026-04-15 23:46:38', NULL),
(66, 38, 4, NULL, '', NULL, '2026-04-15 23:46:38', NULL),
(67, 52, 2, 1, 'IN_PROGRESS', 'Menunggu penugasan koordinator', '2026-04-15 23:48:25', NULL),
(68, 52, 3, 2, 'IN_PROGRESS', 'Diproses petugas', '2026-04-15 23:48:37', NULL),
(69, 52, 4, NULL, '', NULL, '2026-04-15 23:48:47', NULL),
(70, 53, 2, 1, 'IN_PROGRESS', 'Menunggu penugasan koordinator', '2026-04-16 21:46:19', NULL),
(71, 53, 3, 2, 'IN_PROGRESS', 'Diproses petugas', '2026-04-16 21:46:39', NULL),
(72, 54, 2, 1, 'IN_PROGRESS', 'Menunggu penugasan koordinator', '2026-04-16 21:48:01', NULL),
(73, 54, 6, 2, 'IN_PROGRESS', 'Diproses petugas', '2026-04-16 21:48:23', NULL),
(74, 53, 4, NULL, '', NULL, '2026-04-16 21:48:43', NULL),
(75, 54, 4, NULL, '', NULL, '2026-04-16 21:49:09', NULL),
(76, 56, 2, 1, 'IN_PROGRESS', 'Menunggu penugasan koordinator', '2026-04-17 08:04:36', NULL),
(77, 56, 3, 2, 'IN_PROGRESS', 'Diproses petugas', '2026-04-17 08:04:56', NULL),
(78, 56, 4, NULL, '', NULL, '2026-04-17 08:05:14', NULL),
(79, 57, 2, 1, 'IN_PROGRESS', 'Menunggu penugasan koordinator', '2026-04-17 10:00:32', NULL),
(80, 57, 3, 2, 'IN_PROGRESS', 'Diproses petugas', '2026-04-17 10:00:57', NULL),
(81, 57, 4, NULL, '', NULL, '2026-04-17 10:01:11', NULL),
(82, 59, 2, 1, 'IN_PROGRESS', 'Menunggu penugasan koordinator', '2026-04-17 10:09:35', NULL),
(83, 59, 3, 2, 'IN_PROGRESS', 'Diproses petugas', '2026-04-17 10:09:51', NULL),
(84, 59, 4, NULL, '', NULL, '2026-04-17 10:10:08', NULL),
(85, 60, 2, 1, 'IN_PROGRESS', 'Menunggu penugasan koordinator', '2026-04-17 10:15:26', NULL),
(86, 60, 3, 2, 'IN_PROGRESS', 'Diproses petugas', '2026-04-17 10:15:52', NULL),
(87, 60, 4, NULL, '', NULL, '2026-04-17 10:16:22', NULL),
(88, 61, 2, 1, 'IN_PROGRESS', 'Menunggu penugasan koordinator', '2026-04-17 11:04:23', NULL),
(89, 61, 3, 2, 'IN_PROGRESS', 'Diproses petugas', '2026-04-17 11:05:09', NULL),
(90, 61, 4, NULL, '', NULL, '2026-04-17 11:06:03', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `bidang`
--

CREATE TABLE `bidang` (
  `id` int(10) UNSIGNED NOT NULL,
  `code` varchar(64) NOT NULL,
  `name` varchar(128) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `bidang`
--

INSERT INTO `bidang` (`id`, `code`, `name`, `created_at`) VALUES
(1, 'FO', 'Front Office', '2025-10-29 08:44:41'),
(2, 'BID-01', 'Bidang Pelayanan A', '2025-10-29 08:44:41'),
(3, 'BID-02', 'Bidang Pelayanan B', '2025-10-29 08:44:41'),
(4, 'SEKRET', 'Sekretariat/Pimpinan', '2025-10-29 08:44:41');

-- --------------------------------------------------------

--
-- Table structure for table `documents_out`
--

CREATE TABLE `documents_out` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ticket_id` bigint(20) UNSIGNED NOT NULL,
  `tte_provider` varchar(64) DEFAULT NULL,
  `tte_signed_path` varchar(400) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `documents_out`
--

INSERT INTO `documents_out` (`id`, `ticket_id`, `tte_provider`, `tte_signed_path`, `created_at`) VALUES
(2, 1, 'Peruri-TTE', '/signed/TCK-20251029-0001.pdf', '2025-10-29 08:47:59'),
(3, 1, 'Peruri-TTE', '/signed/TCK-20251029-0001.pdf', '2025-10-29 08:50:33'),
(8, 1, 'DevProvider', 'uploads/tte_Cuplikan_layar_2025-10-02_211633.png', '2025-10-29 09:10:49'),
(9, 3, 'DevProvider', 'uploads/tte_6901e618ab2c7_Cuplikan_layar_2025-10-02_211633.png', '2025-10-29 10:02:00'),
(10, 1, 'DevProvider', 'uploads/tte_6901e6362e637_Cuplikan_layar_2025-10-02_211633.png', '2025-10-29 10:02:30'),
(11, 7, 'DevProvider', 'uploads/tte_6901ffa79bf95_Cuplikan_layar_2025-10-02_211633.png', '2025-10-29 11:51:03'),
(12, 9, 'DevProvider', 'uploads/tte_6902cf2c7e2fa_sinopsis.docx', '2025-10-30 02:36:28'),
(13, 13, 'DevProvider', 'uploads/tte_69aaeee6821fb_f_69a9a62a59cbb_cv_bona.pdf', '2026-03-06 15:12:38'),
(14, 14, 'DevProvider', 'uploads/tte_69aaefefd8afb_f_69aaef80ca82b_1.2_BAB_I.pdf', '2026-03-06 15:17:03'),
(15, 15, 'DevProvider', 'uploads/tte_69aaf289ed9da_f_69aaf2640478c_1.2_BAB_I.pdf', '2026-03-06 15:28:09'),
(16, 16, 'DevProvider', 'uploads/tte_69aaf4c2b171a_f_69aaf48383a05_1.2_BAB_I.pdf', '2026-03-06 15:37:38'),
(17, 17, 'DevProvider', 'uploads/tte_69aaf63462917_f_69aaf61822330_1.2_BAB_I.pdf', '2026-03-06 15:43:48'),
(18, 18, 'DevProvider', 'uploads/tte_69aafc185481a_f_69aafbf55a28c_1.2_BAB_I.pdf', '2026-03-06 16:08:56'),
(19, 19, 'DevProvider', 'uploads/tte_69ac49faa57df_f_69ac366e7a705_1.2_BAB_I.pdf', '2026-03-07 15:53:30'),
(20, 20, 'DevProvider', 'uploads/tte_69ac4ac49d0f3_f_69ac4a5b983e8_1.2_BAB_I.pdf', '2026-03-07 15:56:52'),
(21, 21, 'DevProvider', 'uploads/tte_69ac4c8709f34_f_69ac4c4099e58_1.2_BAB_I.pdf', '2026-03-07 16:04:23'),
(22, 22, 'DevProvider', 'uploads/tte_69ac5867e14bc_f_69ac583c3c301_1.2_BAB_I.pdf', '2026-03-07 16:55:03'),
(23, 23, 'DevProvider', 'uploads/tte_69ad86404b397_f_69ad8609d424f_1.2_BAB_I.pdf', '2026-03-08 14:22:56'),
(24, 24, 'DevProvider', 'uploads/tte_69ad88c07910b_f_69ad888b14352_1.2_BAB_I.pdf', '2026-03-08 14:33:36'),
(25, 26, 'DevProvider', 'uploads/tte_69ad8c297d728_f_69ad8bcccbc26_cv_bona.pdf', '2026-03-08 14:48:09'),
(26, 25, 'DevProvider', 'uploads/tte_69ad8c2eb9ee7_f_69ad8bcccbc26_cv_bona.pdf', '2026-03-08 14:48:14'),
(27, 28, 'DevProvider', 'uploads/tte_69ad92104d176_f_69ad91b35c4ad_CV_BONA_2.pdf', '2026-03-08 15:13:20'),
(28, 29, 'DevProvider', 'uploads/tte_69ad9dd2b8be2_1772983842_f_69ad91b35c4ad_CV_BONA_2.pdf', '2026-03-08 16:03:30'),
(29, 27, 'DevProvider', 'uploads/tte_69ad9de829d8c_f_69a9a01d45c80_1.2_BAB_I.pdf', '2026-03-08 16:03:52'),
(30, 30, 'DevProvider', 'uploads/tte_69ad9e50b70a2_f_69ad9e1e2ee82_cv_bona.pdf', '2026-03-08 16:05:36'),
(31, 31, 'DevProvider', 'uploads/tte_69ada76209b35_f_69ada38f9d84d_CV_BONA_2.pdf', '2026-03-08 16:44:18'),
(32, 33, 'DevProvider', 'uploads/tte_69adb11f51af2_f_69adb0d3d4eea_CV_BONA_2.pdf', '2026-03-08 17:25:51'),
(33, 34, 'DevProvider', 'uploads/tte_69ae1c98c43cd_f_69ae1b76a2996_dokument.pdf', '2026-03-09 01:04:24'),
(34, 32, 'DevProvider', 'uploads/tte_69cd3d4632e1f_f_69adad313c166_1.2_BAB_I.pdf', '2026-04-01 15:44:06'),
(35, 36, 'DevProvider', 'uploads/tte_69d36be6683a3_f_69d36adf6ebaa_transkip_nilai.pdf', '2026-04-06 08:16:38'),
(36, 41, 'DevProvider', 'uploads/tte_69d91d7a71402_ktp.pdf', '2026-04-10 15:55:38'),
(37, 39, 'DevProvider', 'uploads/tte_69dfb7cd9f609_surat_mutasi.pdf', '2026-04-15 16:07:41'),
(38, 37, 'DevProvider', 'uploads/tte_69dfb7d1eac37_surat_mutasi.pdf', '2026-04-15 16:07:45'),
(39, 47, 'DevProvider', 'uploads/tte_69dfb7dbc852d_surat_mutasi.pdf', '2026-04-15 16:07:55'),
(40, 48, 'DevProvider', 'uploads/tte_69dfb7df0f225_surat_mutasi.pdf', '2026-04-15 16:07:59'),
(41, 50, 'DevProvider', 'uploads/tte_69dfb836cc1a8_surat_mutasi.pdf', '2026-04-15 16:09:26'),
(42, 51, 'DevProvider', 'uploads/tte_69dfc10702764_tte_69dfb836cc1a8_surat_mutasi.pdf', '2026-04-15 16:47:03'),
(43, 38, 'DevProvider', 'uploads/tte_69dfc10bba25c_f_69dfba3ba36a2_surat_mutasi.pdf', '2026-04-15 16:47:07'),
(44, 52, 'DevProvider', 'uploads/tte_69dfc1a824052_f_69dfc14633ec7_surat_mutasi.pdf', '2026-04-15 16:49:44'),
(45, 53, 'DevProvider', 'uploads/tte_69e0f717e4341_f_69e0f62478d67_surat_mutasi.pdf', '2026-04-16 14:49:59'),
(46, 54, 'DevProvider', 'uploads/tte_69e0f72069662_f_69e0f66040ddc_surat_kenaikan_pangkat.pdf', '2026-04-16 14:50:08'),
(47, 56, 'DevProvider', 'uploads/tte_69e187726501b_f_69e1870b7d83e_surat_mutasi.pdf', '2026-04-17 01:05:54'),
(48, 57, 'DevProvider', 'uploads/tte_69e1a2a774377_surat_mutasi.pdf', '2026-04-17 03:01:59'),
(49, 59, 'DevProvider', 'uploads/tte_69e1a4aae108a_surat_mutasi.pdf', '2026-04-17 03:10:34'),
(50, 60, 'DevProvider', 'uploads/tte_69e1a61c00d9c_surat_mutasi.pdf', '2026-04-17 03:16:44'),
(51, 61, 'DevProvider', 'uploads/tte_69e1b1e279a31_f_69e1b109e2bfa_surat_mutasi__1_.pdf', '2026-04-17 04:06:58');

--
-- Triggers `documents_out`
--
DELIMITER $$
CREATE TRIGGER `trg_documents_out_after_insert` AFTER INSERT ON `documents_out` FOR EACH ROW BEGIN
  DECLARE v_old_status VARCHAR(32);
  SELECT status INTO v_old_status FROM tickets WHERE id=NEW.ticket_id FOR UPDATE;

  UPDATE tickets SET status='SELESAI' WHERE id=NEW.ticket_id;

  INSERT INTO status_history(ticket_id, old_status, new_status, changed_by, comment)
  VALUES (NEW.ticket_id, v_old_status, 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan');

  -- Notifikasi hasil tersedia
  INSERT INTO notifications(recipient_applicant_id,type,ref_ticket_id,message)
  SELECT applicant_id,'RESULT_READY', NEW.ticket_id, 'Hasil layanan telah tersedia'
  FROM tickets WHERE id=NEW.ticket_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `recipient_user_id` int(10) UNSIGNED DEFAULT NULL,
  `recipient_applicant_id` bigint(20) UNSIGNED DEFAULT NULL,
  `type` varchar(64) NOT NULL,
  `ref_ticket_id` bigint(20) UNSIGNED DEFAULT NULL,
  `message` varchar(400) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `read_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `recipient_user_id`, `recipient_applicant_id`, `type`, `ref_ticket_id`, `message`, `created_at`, `read_at`) VALUES
(1, 2, NULL, 'STATUS_CHANGE', 1, 'Tiket TCK-20251029-0001 diterima FO dan masuk antrian bidang', '2025-10-29 08:44:41', NULL),
(2, 3, NULL, 'STATUS_CHANGE', 1, 'Tiket TCK-20251029-0001 ditugaskan ke Anda', '2025-10-29 08:44:41', NULL),
(3, NULL, 1, 'NEED_DATA', 1, 'Tiket TCK-20251029-0001: mohon lengkapi berkas Anda', '2025-10-29 08:44:41', NULL),
(4, NULL, 1, 'STATUS_CHANGE', 1, 'Status tiket TCK-20251029-0001 berubah menjadi SIAP_TTD', '2025-10-29 08:44:41', NULL),
(5, NULL, 1, 'RESULT_READY', 1, 'Hasil layanan telah tersedia', '2025-10-29 08:47:59', NULL),
(6, NULL, 1, 'RESULT_READY', 1, 'Hasil layanan telah tersedia', '2025-10-29 08:50:33', NULL),
(7, 2, NULL, 'STATUS_CHANGE', 2, 'Tiket TCK-20251029-5237 diterima FO dan masuk antrian bidang', '2025-10-29 08:58:00', NULL),
(8, 3, NULL, 'STATUS_CHANGE', 2, 'Tiket TCK-20251029-5237 ditugaskan ke Anda', '2025-10-29 08:59:26', NULL),
(9, 3, NULL, 'STATUS_CHANGE', 2, 'Tiket TCK-20251029-5237 ditugaskan ke Anda', '2025-10-29 08:59:32', NULL),
(10, NULL, 1, 'NEED_DATA', 1, 'Tiket TCK-20251029-0001: mohon lengkapi berkas Anda', '2025-10-29 09:00:31', NULL),
(11, NULL, 1, 'NEED_DATA', 1, 'Tiket TCK-20251029-0001: mohon lengkapi berkas Anda', '2025-10-29 09:00:43', NULL),
(12, NULL, 2, 'STATUS_CHANGE', 2, 'Status tiket TCK-20251029-5237 berubah menjadi SIAP_TTD', '2025-10-29 09:00:51', NULL),
(13, 3, NULL, 'STATUS_CHANGE', 1, 'Tiket TCK-20251029-0001 ditugaskan ke Anda', '2025-10-29 09:03:32', NULL),
(14, 3, NULL, 'STATUS_CHANGE', 2, 'Tiket TCK-20251029-5237 ditugaskan ke Anda', '2025-10-29 09:03:34', NULL),
(15, NULL, 2, 'STATUS_CHANGE', 2, 'Status tiket TCK-20251029-5237 berubah menjadi SIAP_TTD', '2025-10-29 09:04:04', NULL),
(16, NULL, 1, 'STATUS_CHANGE', 1, 'Status tiket TCK-20251029-0001 berubah menjadi SIAP_TTD', '2025-10-29 09:04:06', NULL),
(17, NULL, 2, 'STATUS_CHANGE', 2, 'Status tiket TCK-20251029-5237 berubah menjadi DITOLAK', '2025-10-29 09:04:14', NULL),
(18, NULL, 1, 'RESULT_READY', 1, 'Hasil layanan telah tersedia', '2025-10-29 09:10:49', NULL),
(19, NULL, 3, 'STATUS_CHANGE', 3, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2025-10-29 10:00:15', NULL),
(20, NULL, 3, 'RESULT_READY', 3, 'Hasil layanan telah tersedia', '2025-10-29 10:02:00', NULL),
(21, NULL, 3, 'RESULT_READY', 3, 'Hasil tersedia: uploads/tte_6901e618ab2c7_Cuplikan_layar_2025-10-02_211633.png', '2025-10-29 10:02:00', NULL),
(22, NULL, 1, 'RESULT_READY', 1, 'Hasil layanan telah tersedia', '2025-10-29 10:02:30', NULL),
(23, NULL, 1, 'RESULT_READY', 1, 'Hasil tersedia: uploads/tte_6901e6362e637_Cuplikan_layar_2025-10-02_211633.png', '2025-10-29 10:02:30', NULL),
(24, NULL, 2, 'STATUS_CHANGE', 4, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2025-10-29 10:07:53', NULL),
(25, NULL, 2, 'STATUS_CHANGE', 5, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2025-10-29 10:10:40', NULL),
(26, NULL, 2, 'STATUS_CHANGE', 6, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2025-10-29 10:22:20', NULL),
(27, NULL, 2, 'STATUS_CHANGE', 6, 'Status tiket MENUNGGU_DATA: Mohon lengkapi data', '2025-10-29 10:24:22', NULL),
(28, NULL, 2, 'STATUS_CHANGE', 6, 'Status tiket MENUNGGU_DATA: Mohon lengkapi data', '2025-10-29 10:27:57', NULL),
(29, NULL, 2, 'STATUS_CHANGE', 6, 'Status tiket MENUNGGU_DATA: Mohon lengkapi data', '2025-10-29 10:28:00', NULL),
(30, NULL, 2, 'STATUS_CHANGE', 7, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2025-10-29 11:45:55', NULL),
(31, NULL, 2, 'RESULT_READY', 7, 'Hasil layanan telah tersedia', '2025-10-29 11:51:03', NULL),
(32, NULL, 2, 'RESULT_READY', 7, 'Hasil tersedia: uploads/tte_6901ffa79bf95_Cuplikan_layar_2025-10-02_211633.png', '2025-10-29 11:51:03', NULL),
(33, NULL, 4, 'STATUS_CHANGE', 9, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2025-10-30 02:34:22', NULL),
(34, NULL, 4, 'RESULT_READY', 9, 'Hasil layanan telah tersedia', '2025-10-30 02:36:28', NULL),
(35, NULL, 4, 'RESULT_READY', 9, 'Hasil tersedia: uploads/tte_6902cf2c7e2fa_sinopsis.docx', '2025-10-30 02:36:28', NULL),
(36, NULL, 2, 'STATUS_CHANGE', 8, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-05 14:35:31', NULL),
(37, NULL, 2, 'STATUS_CHANGE', 10, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-05 14:35:33', NULL),
(38, NULL, 2, 'STATUS_CHANGE', 10, 'Status tiket MENUNGGU_DATA: Mohon lengkapi data pendukung.', '2026-03-05 14:37:00', NULL),
(39, NULL, 2, 'STATUS_CHANGE', 8, 'Status tiket MENUNGGU_DATA: Mohon lengkapi data pendukung.', '2026-03-05 14:37:02', NULL),
(40, NULL, 2, 'STATUS_CHANGE', 11, 'Status tiket DITOLAK: ', '2026-03-05 15:23:29', NULL),
(41, NULL, 5, 'STATUS_CHANGE', 12, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-05 15:55:53', NULL),
(42, NULL, 2, 'STATUS_CHANGE', 13, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-05 15:55:56', NULL),
(43, NULL, 2, 'STATUS_CHANGE', 2, 'Status tiket DITOLAK: ', '2026-03-05 16:21:11', NULL),
(44, NULL, 3, 'STATUS_CHANGE', 3, 'Status tiket DITOLAK: ', '2026-03-05 16:21:14', NULL),
(45, NULL, 1, 'STATUS_CHANGE', 1, 'Status tiket DITOLAK: ', '2026-03-05 16:21:17', NULL),
(46, NULL, 2, 'STATUS_CHANGE', 7, 'Status tiket DITOLAK: ', '2026-03-05 16:21:22', NULL),
(47, NULL, 1, 'STATUS_CHANGE', 1, 'Status tiket DITOLAK: ', '2026-03-05 16:21:42', NULL),
(48, NULL, 1, 'STATUS_CHANGE', 1, 'Status tiket DITOLAK: ', '2026-03-05 16:21:45', NULL),
(49, NULL, 2, 'STATUS_CHANGE', 8, 'Status tiket DITOLAK: ', '2026-03-05 16:24:58', NULL),
(50, NULL, 2, 'RESULT_READY', 13, 'Hasil layanan telah tersedia', '2026-03-06 15:12:38', NULL),
(51, NULL, 2, 'RESULT_READY', 13, 'Hasil tersedia: uploads/tte_69aaeee6821fb_f_69a9a62a59cbb_cv_bona.pdf', '2026-03-06 15:12:38', NULL),
(52, NULL, 2, 'STATUS_CHANGE', 14, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-06 15:15:45', NULL),
(53, NULL, 2, 'RESULT_READY', 14, 'Hasil layanan telah tersedia', '2026-03-06 15:17:03', NULL),
(54, NULL, 2, 'RESULT_READY', 14, 'Hasil tersedia: uploads/tte_69aaefefd8afb_f_69aaef80ca82b_1.2_BAB_I.pdf', '2026-03-06 15:17:03', NULL),
(55, NULL, 2, 'STATUS_CHANGE', 15, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-06 15:27:38', NULL),
(56, NULL, 2, 'RESULT_READY', 15, 'Hasil layanan telah tersedia', '2026-03-06 15:28:09', NULL),
(57, NULL, 2, 'RESULT_READY', 15, 'Hasil tersedia: uploads/tte_69aaf289ed9da_f_69aaf2640478c_1.2_BAB_I.pdf', '2026-03-06 15:28:09', NULL),
(58, NULL, 2, 'STATUS_CHANGE', 16, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-06 15:36:42', NULL),
(59, NULL, 2, 'RESULT_READY', 16, 'Hasil layanan telah tersedia', '2026-03-06 15:37:38', NULL),
(60, NULL, 2, 'RESULT_READY', 16, 'Hasil tersedia: uploads/tte_69aaf4c2b171a_f_69aaf48383a05_1.2_BAB_I.pdf', '2026-03-06 15:37:38', NULL),
(61, NULL, 2, 'STATUS_CHANGE', 17, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-06 15:43:25', NULL),
(62, NULL, 2, 'RESULT_READY', 17, 'Hasil layanan telah tersedia', '2026-03-06 15:43:48', NULL),
(63, NULL, 2, 'RESULT_READY', 17, 'Hasil tersedia: uploads/tte_69aaf63462917_f_69aaf61822330_1.2_BAB_I.pdf', '2026-03-06 15:43:48', NULL),
(64, NULL, 2, 'STATUS_CHANGE', 18, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-06 16:08:31', NULL),
(65, NULL, 2, 'RESULT_READY', 18, 'Hasil layanan telah tersedia', '2026-03-06 16:08:56', NULL),
(66, NULL, 2, 'RESULT_READY', 18, 'Hasil tersedia: uploads/tte_69aafc185481a_f_69aafbf55a28c_1.2_BAB_I.pdf', '2026-03-06 16:08:56', NULL),
(67, NULL, 2, 'STATUS_CHANGE', 19, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-07 15:45:05', NULL),
(68, NULL, 2, 'RESULT_READY', 19, 'Hasil layanan telah tersedia', '2026-03-07 15:53:30', NULL),
(69, NULL, 2, 'RESULT_READY', 19, 'Hasil tersedia: uploads/tte_69ac49faa57df_f_69ac366e7a705_1.2_BAB_I.pdf', '2026-03-07 15:53:30', NULL),
(70, NULL, 2, 'STATUS_CHANGE', 20, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-07 15:55:45', NULL),
(71, NULL, 2, 'RESULT_READY', 20, 'Hasil layanan telah tersedia', '2026-03-07 15:56:52', NULL),
(72, NULL, 2, 'RESULT_READY', 20, 'Hasil tersedia: uploads/tte_69ac4ac49d0f3_f_69ac4a5b983e8_1.2_BAB_I.pdf', '2026-03-07 15:56:52', NULL),
(73, NULL, 2, 'STATUS_CHANGE', 21, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-07 16:03:21', NULL),
(74, NULL, 5, 'STATUS_CHANGE', 12, 'Status tiket DITOLAK: ', '2026-03-07 16:03:59', NULL),
(75, NULL, 2, 'STATUS_CHANGE', 10, 'Status tiket DITOLAK: ', '2026-03-07 16:04:00', NULL),
(76, NULL, 2, 'RESULT_READY', 21, 'Hasil layanan telah tersedia', '2026-03-07 16:04:23', NULL),
(77, NULL, 2, 'RESULT_READY', 21, 'Hasil tersedia: uploads/tte_69ac4c8709f34_f_69ac4c4099e58_1.2_BAB_I.pdf', '2026-03-07 16:04:23', NULL),
(78, NULL, 2, 'STATUS_CHANGE', 22, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-07 16:54:29', NULL),
(79, NULL, 2, 'RESULT_READY', 22, 'Hasil layanan telah tersedia', '2026-03-07 16:55:03', NULL),
(80, NULL, 2, 'RESULT_READY', 22, 'Hasil tersedia: uploads/tte_69ac5867e14bc_f_69ac583c3c301_1.2_BAB_I.pdf', '2026-03-07 16:55:03', NULL),
(81, NULL, 2, 'STATUS_CHANGE', 23, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-08 14:22:12', NULL),
(82, NULL, 2, 'RESULT_READY', 23, 'Hasil layanan telah tersedia', '2026-03-08 14:22:56', NULL),
(83, NULL, 2, 'RESULT_READY', 23, 'Hasil tersedia: uploads/tte_69ad86404b397_f_69ad8609d424f_1.2_BAB_I.pdf', '2026-03-08 14:22:56', NULL),
(84, NULL, 2, 'STATUS_CHANGE', 24, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-08 14:32:53', NULL),
(85, NULL, 2, 'RESULT_READY', 24, 'Hasil layanan telah tersedia', '2026-03-08 14:33:36', NULL),
(86, NULL, 2, 'RESULT_READY', 24, 'Hasil tersedia: uploads/tte_69ad88c07910b_f_69ad888b14352_1.2_BAB_I.pdf', '2026-03-08 14:33:36', NULL),
(87, NULL, 2, 'STATUS_CHANGE', 25, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-08 14:36:33', NULL),
(88, NULL, 2, 'STATUS_CHANGE', 26, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-08 14:46:49', NULL),
(89, NULL, 2, 'RESULT_READY', 26, 'Hasil layanan telah tersedia', '2026-03-08 14:48:09', NULL),
(90, NULL, 2, 'RESULT_READY', 26, 'Hasil tersedia: uploads/tte_69ad8c297d728_f_69ad8bcccbc26_cv_bona.pdf', '2026-03-08 14:48:09', NULL),
(91, NULL, 2, 'RESULT_READY', 25, 'Hasil layanan telah tersedia', '2026-03-08 14:48:14', NULL),
(92, NULL, 2, 'RESULT_READY', 25, 'Hasil tersedia: uploads/tte_69ad8c2eb9ee7_f_69ad8bcccbc26_cv_bona.pdf', '2026-03-08 14:48:14', NULL),
(93, NULL, 2, 'STATUS_CHANGE', 27, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-08 14:53:08', NULL),
(94, NULL, 2, 'STATUS_CHANGE', 28, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-08 15:12:30', NULL),
(95, NULL, 2, 'RESULT_READY', 28, 'Hasil layanan telah tersedia', '2026-03-08 15:13:20', NULL),
(96, NULL, 2, 'RESULT_READY', 28, 'Hasil tersedia: uploads/tte_69ad92104d176_f_69ad91b35c4ad_CV_BONA_2.pdf', '2026-03-08 15:13:20', NULL),
(97, NULL, 2, 'STATUS_CHANGE', 29, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-08 15:47:47', NULL),
(98, NULL, 2, 'RESULT_READY', 29, 'Hasil layanan telah tersedia', '2026-03-08 16:03:30', NULL),
(99, NULL, 2, 'RESULT_READY', 29, 'Hasil tersedia: uploads/tte_69ad9dd2b8be2_1772983842_f_69ad91b35c4ad_CV_BONA_2.pdf', '2026-03-08 16:03:30', NULL),
(100, NULL, 2, 'RESULT_READY', 27, 'Hasil layanan telah tersedia', '2026-03-08 16:03:52', NULL),
(101, NULL, 2, 'RESULT_READY', 27, 'Hasil tersedia: uploads/tte_69ad9de829d8c_f_69a9a01d45c80_1.2_BAB_I.pdf', '2026-03-08 16:03:52', NULL),
(102, NULL, 2, 'STATUS_CHANGE', 30, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-08 16:04:56', NULL),
(103, NULL, 2, 'RESULT_READY', 30, 'Hasil layanan telah tersedia', '2026-03-08 16:05:36', NULL),
(104, NULL, 2, 'RESULT_READY', 30, 'Hasil tersedia: uploads/tte_69ad9e50b70a2_f_69ad9e1e2ee82_cv_bona.pdf', '2026-03-08 16:05:36', NULL),
(105, NULL, 2, 'STATUS_CHANGE', 31, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-08 16:28:08', NULL),
(106, NULL, 2, 'RESULT_READY', 31, 'Hasil layanan telah tersedia', '2026-03-08 16:44:18', NULL),
(107, NULL, 2, 'RESULT_READY', 31, 'Hasil tersedia: uploads/tte_69ada76209b35_f_69ada38f9d84d_CV_BONA_2.pdf', '2026-03-08 16:44:18', NULL),
(108, NULL, 2, 'STATUS_CHANGE', 32, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-08 17:09:15', NULL),
(109, NULL, 2, 'STATUS_CHANGE', 33, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-08 17:24:43', NULL),
(110, NULL, 2, 'RESULT_READY', 33, 'Hasil layanan telah tersedia', '2026-03-08 17:25:51', NULL),
(111, NULL, 2, 'RESULT_READY', 33, 'Hasil tersedia: uploads/tte_69adb11f51af2_f_69adb0d3d4eea_CV_BONA_2.pdf', '2026-03-08 17:25:51', NULL),
(112, NULL, 2, 'STATUS_CHANGE', 34, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-03-09 01:01:19', NULL),
(113, NULL, 2, 'RESULT_READY', 34, 'Hasil layanan telah tersedia', '2026-03-09 01:04:24', NULL),
(114, NULL, 2, 'RESULT_READY', 34, 'Hasil tersedia: uploads/tte_69ae1c98c43cd_f_69ae1b76a2996_dokument.pdf', '2026-03-09 01:04:24', NULL),
(115, NULL, 2, 'STATUS_CHANGE', 35, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-04-01 15:42:44', NULL),
(116, NULL, 2, 'RESULT_READY', 32, 'Hasil layanan telah tersedia', '2026-04-01 15:44:06', NULL),
(117, NULL, 2, 'RESULT_READY', 32, 'Hasil tersedia: uploads/tte_69cd3d4632e1f_f_69adad313c166_1.2_BAB_I.pdf', '2026-04-01 15:44:06', NULL),
(118, NULL, 2, 'STATUS_CHANGE', 36, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-04-06 08:13:55', NULL),
(119, NULL, 2, 'RESULT_READY', 36, 'Hasil layanan telah tersedia', '2026-04-06 08:16:38', NULL),
(120, NULL, 2, 'RESULT_READY', 36, 'Hasil tersedia: uploads/tte_69d36be6683a3_f_69d36adf6ebaa_transkip_nilai.pdf', '2026-04-06 08:16:38', NULL),
(121, NULL, 2, 'STATUS_CHANGE', 37, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-04-09 10:49:55', NULL),
(122, NULL, 2, 'STATUS_CHANGE', 38, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-04-09 10:50:34', NULL),
(123, NULL, 2, 'STATUS_CHANGE', 39, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-04-09 11:28:40', NULL),
(124, NULL, 2, 'STATUS_CHANGE', 40, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-04-09 11:28:40', NULL),
(125, NULL, 5, 'STATUS_CHANGE', 41, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-04-09 11:45:44', NULL),
(126, NULL, 2, 'STATUS_CHANGE', 42, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-04-09 11:53:03', NULL),
(127, NULL, 2, 'STATUS_CHANGE', 43, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-04-09 12:10:14', NULL),
(128, NULL, 4, 'STATUS_CHANGE', 44, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-04-09 13:18:13', NULL),
(129, NULL, 6, 'STATUS_CHANGE', 45, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-04-10 15:22:34', NULL),
(130, NULL, 6, 'STATUS_CHANGE', 46, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-04-10 15:22:36', NULL),
(131, NULL, 6, 'STATUS_CHANGE', 46, 'Status tiket DITOLAK: ', '2026-04-10 15:24:05', NULL),
(132, NULL, 5, 'RESULT_READY', 41, 'Hasil layanan telah tersedia', '2026-04-10 15:55:38', NULL),
(133, NULL, 5, 'RESULT_READY', 41, 'Hasil tersedia: uploads/tte_69d91d7a71402_ktp.pdf', '2026-04-10 15:55:38', NULL),
(134, NULL, 2, 'STATUS_CHANGE', 47, 'Permohonan diterima FO dan diarahkan ke bidang terkait', '2026-04-10 17:06:16', NULL),
(135, 2, NULL, 'STATUS_CHANGE', 48, 'Tiket TCK-20260415-3626 diterima FO dan masuk antrian bidang', '2026-04-15 15:59:31', NULL),
(136, NULL, 6, 'STATUS_CHANGE', 49, 'Status tiket DITOLAK: Ditolak saat screening FO', '2026-04-15 16:00:15', NULL),
(137, NULL, 2, 'RESULT_READY', 39, 'Hasil layanan telah tersedia', '2026-04-15 16:07:41', NULL),
(138, NULL, 2, 'RESULT_READY', 39, 'Hasil tersedia: uploads/tte_69dfb7cd9f609_surat_mutasi.pdf', '2026-04-15 16:07:41', NULL),
(139, NULL, 2, 'RESULT_READY', 37, 'Hasil layanan telah tersedia', '2026-04-15 16:07:45', NULL),
(140, NULL, 2, 'RESULT_READY', 37, 'Hasil tersedia: uploads/tte_69dfb7d1eac37_surat_mutasi.pdf', '2026-04-15 16:07:45', NULL),
(141, NULL, 2, 'RESULT_READY', 47, 'Hasil layanan telah tersedia', '2026-04-15 16:07:55', NULL),
(142, NULL, 2, 'RESULT_READY', 47, 'Hasil tersedia: uploads/tte_69dfb7dbc852d_surat_mutasi.pdf', '2026-04-15 16:07:55', NULL),
(143, NULL, 2, 'RESULT_READY', 48, 'Hasil layanan telah tersedia', '2026-04-15 16:07:59', NULL),
(144, NULL, 2, 'RESULT_READY', 48, 'Hasil tersedia: uploads/tte_69dfb7df0f225_surat_mutasi.pdf', '2026-04-15 16:07:59', NULL),
(145, 2, NULL, 'STATUS_CHANGE', 50, 'Tiket TCK-20260415-2336 diterima FO dan masuk antrian bidang', '2026-04-15 16:08:37', NULL),
(146, NULL, 2, 'RESULT_READY', 50, 'Hasil layanan telah tersedia', '2026-04-15 16:09:26', NULL),
(147, NULL, 2, 'RESULT_READY', 50, 'Hasil tersedia: uploads/tte_69dfb836cc1a8_surat_mutasi.pdf', '2026-04-15 16:09:26', NULL),
(148, 2, NULL, 'STATUS_CHANGE', 51, 'Tiket TCK-20260415-3113 diterima FO dan masuk antrian bidang', '2026-04-15 16:20:13', NULL),
(149, NULL, 2, 'RESULT_READY', 51, 'Hasil layanan telah tersedia', '2026-04-15 16:47:03', NULL),
(150, NULL, 2, 'RESULT_READY', 51, 'Hasil tersedia: uploads/tte_69dfc10702764_tte_69dfb836cc1a8_surat_mutasi.pdf', '2026-04-15 16:47:03', NULL),
(151, NULL, 2, 'RESULT_READY', 38, 'Hasil layanan telah tersedia', '2026-04-15 16:47:07', NULL),
(152, NULL, 2, 'RESULT_READY', 38, 'Hasil tersedia: uploads/tte_69dfc10bba25c_f_69dfba3ba36a2_surat_mutasi.pdf', '2026-04-15 16:47:07', NULL),
(153, 2, NULL, 'STATUS_CHANGE', 52, 'Tiket TCK-20260415-1779 diterima FO dan masuk antrian bidang', '2026-04-15 16:48:25', NULL),
(154, NULL, 2, 'RESULT_READY', 52, 'Hasil layanan telah tersedia', '2026-04-15 16:49:44', NULL),
(155, NULL, 2, 'RESULT_READY', 52, 'Hasil tersedia: uploads/tte_69dfc1a824052_f_69dfc14633ec7_surat_mutasi.pdf', '2026-04-15 16:49:44', NULL),
(156, 2, NULL, 'STATUS_CHANGE', 53, 'Tiket TCK-20260416-2373 diterima FO dan masuk antrian bidang', '2026-04-16 14:46:19', NULL),
(157, 2, NULL, 'STATUS_CHANGE', 54, 'Tiket TCK-20260416-5263 diterima FO dan masuk antrian bidang', '2026-04-16 14:48:01', NULL),
(158, NULL, 2, 'RESULT_READY', 53, 'Hasil layanan telah tersedia', '2026-04-16 14:49:59', NULL),
(159, NULL, 2, 'RESULT_READY', 53, 'Hasil tersedia: uploads/tte_69e0f717e4341_f_69e0f62478d67_surat_mutasi.pdf', '2026-04-16 14:49:59', NULL),
(160, NULL, 2, 'RESULT_READY', 54, 'Hasil layanan telah tersedia', '2026-04-16 14:50:08', NULL),
(161, NULL, 2, 'RESULT_READY', 54, 'Hasil tersedia: uploads/tte_69e0f72069662_f_69e0f66040ddc_surat_kenaikan_pangkat.pdf', '2026-04-16 14:50:08', NULL),
(162, NULL, 2, 'STATUS_CHANGE', 55, 'Status tiket DITOLAK: Ditolak saat screening FO', '2026-04-17 01:03:54', NULL),
(163, 2, NULL, 'STATUS_CHANGE', 56, 'Tiket TCK-20260417-9788 diterima FO dan masuk antrian bidang', '2026-04-17 01:04:36', NULL),
(164, NULL, 2, 'RESULT_READY', 56, 'Hasil layanan telah tersedia', '2026-04-17 01:05:54', NULL),
(165, NULL, 2, 'RESULT_READY', 56, 'Hasil tersedia: uploads/tte_69e187726501b_f_69e1870b7d83e_surat_mutasi.pdf', '2026-04-17 01:05:54', NULL),
(166, 2, NULL, 'STATUS_CHANGE', 57, 'Tiket TCK-20260417-4856 diterima FO dan masuk antrian bidang', '2026-04-17 03:00:32', NULL),
(167, NULL, 2, 'RESULT_READY', 57, 'Hasil layanan telah tersedia', '2026-04-17 03:01:59', NULL),
(168, NULL, 2, 'RESULT_READY', 57, 'Hasil tersedia: uploads/tte_69e1a2a774377_surat_mutasi.pdf', '2026-04-17 03:01:59', NULL),
(169, NULL, 2, 'STATUS_CHANGE', 58, 'Status tiket DITOLAK: tidak lengkap', '2026-04-17 03:03:23', NULL),
(170, 2, NULL, 'STATUS_CHANGE', 59, 'Tiket TCK-20260417-7324 diterima FO dan masuk antrian bidang', '2026-04-17 03:09:35', NULL),
(171, NULL, 2, 'RESULT_READY', 59, 'Hasil layanan telah tersedia', '2026-04-17 03:10:34', NULL),
(172, NULL, 2, 'RESULT_READY', 59, 'Hasil tersedia: uploads/tte_69e1a4aae108a_surat_mutasi.pdf', '2026-04-17 03:10:34', NULL),
(173, 2, NULL, 'STATUS_CHANGE', 60, 'Tiket TCK-20260417-1962 diterima FO dan masuk antrian bidang', '2026-04-17 03:15:26', NULL),
(174, NULL, 2, 'RESULT_READY', 60, 'Hasil layanan telah tersedia', '2026-04-17 03:16:44', NULL),
(175, NULL, 2, 'RESULT_READY', 60, 'Hasil tersedia: uploads/tte_69e1a61c00d9c_surat_mutasi.pdf', '2026-04-17 03:16:44', NULL),
(176, 2, NULL, 'STATUS_CHANGE', 61, 'Tiket TCK-20260417-2154 diterima FO dan masuk antrian bidang', '2026-04-17 04:04:23', NULL),
(177, NULL, 2, 'RESULT_READY', 61, 'Hasil layanan telah tersedia', '2026-04-17 04:06:58', NULL),
(178, NULL, 2, 'RESULT_READY', 61, 'Hasil tersedia: uploads/tte_69e1b1e279a31_f_69e1b109e2bfa_surat_mutasi__1_.pdf', '2026-04-17 04:06:58', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `priorities`
--

CREATE TABLE `priorities` (
  `code` varchar(16) NOT NULL,
  `name` varchar(64) NOT NULL,
  `sort_order` tinyint(3) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `priorities`
--

INSERT INTO `priorities` (`code`, `name`, `sort_order`) VALUES
('HIGH', 'High', 3),
('LOW', 'Low', 1),
('NORMAL', 'Normal', 2),
('URGENT', 'Urgent', 4);

-- --------------------------------------------------------

--
-- Table structure for table `roles`
--

CREATE TABLE `roles` (
  `id` int(10) UNSIGNED NOT NULL,
  `code` varchar(64) NOT NULL,
  `name` varchar(128) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `roles`
--

INSERT INTO `roles` (`id`, `code`, `name`, `created_at`) VALUES
(1, 'PEMOHON', 'Pemohon', '2025-10-29 08:44:41'),
(2, 'FO', 'Front Office', '2025-10-29 08:44:41'),
(3, 'KOORDINATOR', 'Koordinator Bidang', '2025-10-29 08:44:41'),
(4, 'PETUGAS', 'Petugas', '2025-10-29 08:44:41'),
(5, 'PIMPINAN', 'Pimpinan/TTE', '2025-10-29 08:44:41'),
(6, 'SYSTEM', 'Sistem', '2025-10-29 08:44:41');

-- --------------------------------------------------------

--
-- Table structure for table `services`
--

CREATE TABLE `services` (
  `id` int(10) UNSIGNED NOT NULL,
  `code` varchar(64) NOT NULL,
  `name` varchar(128) NOT NULL,
  `description` text DEFAULT NULL,
  `sla_hours` int(10) UNSIGNED NOT NULL DEFAULT 24,
  `requires_tte` tinyint(1) NOT NULL DEFAULT 1,
  `escalate_to_bidang_id` int(10) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `services`
--

INSERT INTO `services` (`id`, `code`, `name`, `description`, `sla_hours`, `requires_tte`, `escalate_to_bidang_id`) VALUES
(1, 'SV-LEGAL', 'Legalisir Dokumen', 'Contoh layanan legalisir', 48, 1, 4),
(2, 'SV-INFO', 'Informasi Umum', 'Informasi umum non-TTE', 24, 0, 4);

-- --------------------------------------------------------

--
-- Table structure for table `statuses`
--

CREATE TABLE `statuses` (
  `code` varchar(32) NOT NULL,
  `name` varchar(128) NOT NULL,
  `is_final` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `statuses`
--

INSERT INTO `statuses` (`code`, `name`, `is_final`) VALUES
('DALAM_PROSES', 'Dalam Proses', 0),
('DIAJUKAN', 'Diajukan Pemohon', 0),
('DIKERJAKAN', 'Sedang Dikerjakan', 0),
('DITERIMA_FO', 'Diterima Front Office', 0),
('DITOLAK', 'Ditolak', 1),
('MENUNGGU_DATA', 'Menunggu Data Pemohon', 0),
('SELESAI', 'Selesai', 1),
('SIAP_TTD', 'Siap TTE/Paraf Pimpinan', 0);

-- --------------------------------------------------------

--
-- Table structure for table `status_history`
--

CREATE TABLE `status_history` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ticket_id` bigint(20) UNSIGNED NOT NULL,
  `old_status` varchar(32) DEFAULT NULL,
  `new_status` varchar(32) NOT NULL,
  `changed_by` int(10) UNSIGNED DEFAULT NULL,
  `comment` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `changed_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `status_history`
--

INSERT INTO `status_history` (`id`, `ticket_id`, `old_status`, `new_status`, `changed_by`, `comment`, `created_at`, `changed_at`) VALUES
(1, 1, NULL, 'DIAJUKAN', NULL, 'Pengajuan awal oleh pemohon', '2025-10-29 15:44:41', '2026-03-07 23:33:25'),
(2, 1, 'DIAJUKAN', 'DITERIMA_FO', 1, 'Screening FO lulus', '2025-10-29 15:44:41', '2026-03-07 23:33:25'),
(3, 1, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2025-10-29 15:44:41', '2026-03-07 23:33:25'),
(4, 1, 'DALAM_PROSES', 'MENUNGGU_DATA', 3, 'Mohon unggah scan KTP & ijazah', '2025-10-29 15:44:41', '2026-03-07 23:33:25'),
(5, 1, 'MENUNGGU_DATA', 'SIAP_TTD', 3, 'Berkas valid, lanjut TTE', '2025-10-29 15:44:41', '2026-03-07 23:33:25'),
(6, 1, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2025-10-29 15:47:59', '2026-03-07 23:33:25'),
(7, 1, 'SELESAI', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2025-10-29 15:50:33', '2026-03-07 23:33:25'),
(8, 2, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2025-10-29 15:54:34', '2026-03-07 23:33:25'),
(9, 2, 'DIAJUKAN', 'DITERIMA_FO', 1, 'Screening FO lulus', '2025-10-29 15:58:00', '2026-03-07 23:33:25'),
(10, 2, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2025-10-29 15:59:26', '2026-03-07 23:33:25'),
(11, 2, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2025-10-29 15:59:32', '2026-03-07 23:33:25'),
(12, 1, 'DALAM_PROSES', 'MENUNGGU_DATA', 3, 'Mohon lengkapi data', '2025-10-29 16:00:31', '2026-03-07 23:33:25'),
(13, 1, 'DALAM_PROSES', 'MENUNGGU_DATA', 3, 'Mohon lengkapi data', '2025-10-29 16:00:43', '2026-03-07 23:33:25'),
(14, 2, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2025-10-29 16:00:51', '2026-03-07 23:33:25'),
(15, 1, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2025-10-29 16:03:32', '2026-03-07 23:33:25'),
(16, 2, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2025-10-29 16:03:34', '2026-03-07 23:33:25'),
(17, 2, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2025-10-29 16:04:04', '2026-03-07 23:33:25'),
(18, 1, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2025-10-29 16:04:06', '2026-03-07 23:33:25'),
(19, 2, 'SIAP_TTD', 'DITOLAK', 3, '', '2025-10-29 16:04:14', '2026-03-07 23:33:25'),
(20, 1, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2025-10-29 16:10:49', '2026-03-07 23:33:25'),
(21, 3, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2025-10-29 16:53:40', '2026-03-07 23:33:25'),
(22, 3, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2025-10-29 17:00:15', '2026-03-07 23:33:25'),
(23, 3, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2025-10-29 17:01:07', '2026-03-07 23:33:25'),
(24, 3, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2025-10-29 17:01:40', '2026-03-07 23:33:25'),
(25, 1, 'SELESAI', 'SIAP_TTD', 3, '', '2025-10-29 17:01:42', '2026-03-07 23:33:25'),
(26, 3, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2025-10-29 17:02:00', '2026-03-07 23:33:25'),
(27, 1, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2025-10-29 17:02:30', '2026-03-07 23:33:25'),
(28, 4, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2025-10-29 17:07:17', '2026-03-07 23:33:25'),
(29, 4, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2025-10-29 17:07:53', '2026-03-07 23:33:25'),
(30, 5, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2025-10-29 17:09:45', '2026-03-07 23:33:25'),
(31, 5, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2025-10-29 17:10:40', '2026-03-07 23:33:25'),
(32, 6, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2025-10-29 17:12:05', '2026-03-07 23:33:25'),
(33, 6, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2025-10-29 17:22:20', '2026-03-07 23:33:25'),
(34, 6, 'DITERIMA_FO', 'DALAM_PROSES', 5, 'Penugasan ke petugas', '2025-10-29 17:23:03', '2026-03-07 23:33:25'),
(35, 6, 'DALAM_PROSES', 'MENUNGGU_DATA', 6, 'Mohon lengkapi data', '2025-10-29 17:24:22', '2026-03-07 23:33:25'),
(36, 6, 'MENUNGGU_DATA', 'MENUNGGU_DATA', 6, 'Mohon lengkapi data', '2025-10-29 17:27:57', '2026-03-07 23:33:25'),
(37, 6, 'MENUNGGU_DATA', 'MENUNGGU_DATA', 6, 'Mohon lengkapi data', '2025-10-29 17:28:00', '2026-03-07 23:33:25'),
(38, 7, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2025-10-29 18:36:07', '2026-03-07 23:33:25'),
(39, 7, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2025-10-29 18:45:55', '2026-03-07 23:33:25'),
(40, 7, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2025-10-29 18:46:11', '2026-03-07 23:33:25'),
(41, 7, 'DALAM_PROSES', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2025-10-29 18:46:14', '2026-03-07 23:33:25'),
(42, 7, 'DALAM_PROSES', 'SIAP_TTD', 3, 'Dokumen siap untuk TTE.', '2025-10-29 18:50:43', '2026-03-07 23:33:25'),
(43, 7, 'SIAP_TTD', 'SIAP_TTD', 3, 'Dokumen siap untuk TTE.', '2025-10-29 18:50:45', '2026-03-07 23:33:25'),
(44, 7, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2025-10-29 18:51:03', '2026-03-07 23:33:25'),
(45, 8, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2025-10-30 09:29:19', '2026-03-07 23:33:25'),
(46, 9, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2025-10-30 09:33:48', '2026-03-07 23:33:25'),
(47, 9, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2025-10-30 09:34:22', '2026-03-07 23:33:25'),
(48, 9, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2025-10-30 09:35:01', '2026-03-07 23:33:25'),
(49, 9, 'DALAM_PROSES', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2025-10-30 09:35:05', '2026-03-07 23:33:25'),
(50, 9, 'DALAM_PROSES', 'SIAP_TTD', 3, 'Dokumen siap untuk TTE.', '2025-10-30 09:35:39', '2026-03-07 23:33:25'),
(51, 9, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2025-10-30 09:36:28', '2026-03-07 23:33:25'),
(52, 10, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-05 21:35:13', '2026-03-07 23:33:25'),
(53, 8, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-05 21:35:31', '2026-03-07 23:33:25'),
(54, 10, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-05 21:35:33', '2026-03-07 23:33:25'),
(55, 8, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-05 21:36:02', '2026-03-07 23:33:25'),
(56, 10, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-05 21:36:04', '2026-03-07 23:33:25'),
(57, 10, 'DALAM_PROSES', 'MENUNGGU_DATA', 3, 'Mohon lengkapi data pendukung.', '2026-03-05 21:37:00', '2026-03-07 23:33:25'),
(58, 8, 'DALAM_PROSES', 'MENUNGGU_DATA', 3, 'Mohon lengkapi data pendukung.', '2026-03-05 21:37:02', '2026-03-07 23:33:25'),
(59, 8, 'MENUNGGU_DATA', 'SIAP_TTD', 3, 'Dokumen siap untuk TTE.', '2026-03-05 21:37:08', '2026-03-07 23:33:25'),
(60, 10, 'MENUNGGU_DATA', 'SIAP_TTD', 3, 'Dokumen siap untuk TTE.', '2026-03-05 21:37:09', '2026-03-07 23:33:25'),
(61, 11, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-05 22:05:39', '2026-03-07 23:33:25'),
(62, 11, 'DIAJUKAN', 'DITOLAK', 1, '', '2026-03-05 22:23:29', '2026-03-07 23:33:25'),
(63, 12, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-05 22:24:13', '2026-03-07 23:33:25'),
(64, 13, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-05 22:50:02', '2026-03-07 23:33:25'),
(65, 12, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-05 22:55:53', '2026-03-07 23:33:25'),
(66, 13, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-05 22:55:56', '2026-03-07 23:33:25'),
(67, 8, 'SIAP_TTD', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-05 23:09:27', '2026-03-07 23:33:25'),
(68, 8, 'DALAM_PROSES', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-05 23:09:33', '2026-03-07 23:33:25'),
(69, 10, 'SIAP_TTD', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-05 23:09:35', '2026-03-07 23:33:25'),
(70, 8, 'DALAM_PROSES', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-05 23:09:55', '2026-03-07 23:33:25'),
(71, 10, 'DALAM_PROSES', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-05 23:09:56', '2026-03-07 23:33:25'),
(72, 12, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-05 23:09:57', '2026-03-07 23:33:25'),
(73, 13, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-05 23:14:10', '2026-03-07 23:33:25'),
(74, 2, 'DITOLAK', 'DITOLAK', 3, '', '2026-03-05 23:21:11', '2026-03-07 23:33:25'),
(75, 3, 'SELESAI', 'DITOLAK', 3, '', '2026-03-05 23:21:14', '2026-03-07 23:33:25'),
(76, 1, 'SELESAI', 'DITOLAK', 3, '', '2026-03-05 23:21:17', '2026-03-07 23:33:25'),
(77, 7, 'SELESAI', 'DITOLAK', 3, '', '2026-03-05 23:21:22', '2026-03-07 23:33:25'),
(78, 1, 'DITOLAK', 'DITOLAK', 3, '', '2026-03-05 23:21:42', '2026-03-07 23:33:25'),
(79, 1, 'DITOLAK', 'DITOLAK', 3, '', '2026-03-05 23:21:45', '2026-03-07 23:33:25'),
(80, 8, 'DALAM_PROSES', 'DITOLAK', 3, '', '2026-03-05 23:24:58', '2026-03-07 23:33:25'),
(81, 13, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-06 20:59:41', '2026-03-07 23:33:25'),
(82, 13, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-06 22:12:38', '2026-03-07 23:33:25'),
(83, 14, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-06 22:15:12', '2026-03-07 23:33:25'),
(84, 14, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-06 22:15:45', '2026-03-07 23:33:25'),
(85, 14, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-06 22:16:05', '2026-03-07 23:33:25'),
(86, 14, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-06 22:16:37', '2026-03-07 23:33:25'),
(87, 14, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-06 22:17:03', '2026-03-07 23:33:25'),
(88, 15, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-06 22:27:32', '2026-03-07 23:33:25'),
(89, 15, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-06 22:27:38', '2026-03-07 23:33:25'),
(90, 15, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-06 22:27:45', '2026-03-07 23:33:25'),
(91, 15, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-06 22:27:58', '2026-03-07 23:33:25'),
(92, 15, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-06 22:28:09', '2026-03-07 23:33:25'),
(93, 16, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-06 22:36:35', '2026-03-07 23:33:25'),
(94, 16, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-06 22:36:42', '2026-03-07 23:33:25'),
(95, 16, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-06 22:36:50', '2026-03-07 23:33:25'),
(96, 16, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-06 22:37:17', '2026-03-07 23:33:25'),
(97, 16, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-06 22:37:38', '2026-03-07 23:33:25'),
(98, 17, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-06 22:43:20', '2026-03-07 23:33:25'),
(99, 17, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-06 22:43:25', '2026-03-07 23:33:25'),
(100, 17, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-06 22:43:30', '2026-03-07 23:33:25'),
(101, 17, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-06 22:43:37', '2026-03-07 23:33:25'),
(102, 17, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-06 22:43:48', '2026-03-07 23:33:25'),
(103, 18, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-06 23:08:21', '2026-03-07 23:33:25'),
(104, 18, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-06 23:08:31', '2026-03-07 23:33:25'),
(105, 18, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-06 23:08:37', '2026-03-07 23:33:25'),
(106, 18, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-06 23:08:46', '2026-03-07 23:33:25'),
(107, 18, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-06 23:08:56', '2026-03-07 23:33:25'),
(108, 19, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-07 21:30:06', '2026-03-07 23:33:25'),
(109, 19, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-07 22:45:05', '2026-03-07 23:33:25'),
(110, 19, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-07 22:45:53', '2026-03-07 23:33:25'),
(111, 19, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-07 22:53:13', '2026-03-07 23:33:25'),
(112, 19, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-07 22:53:30', '2026-03-07 23:33:25'),
(113, 20, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-07 22:55:07', '2026-03-07 23:33:25'),
(114, 20, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-07 22:55:45', '2026-03-07 23:33:25'),
(115, 20, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-07 22:56:03', '2026-03-07 23:33:25'),
(116, 20, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-07 22:56:27', '2026-03-07 23:33:25'),
(117, 20, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-07 22:56:52', '2026-03-07 23:33:25'),
(118, 21, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-07 23:03:12', '2026-03-07 23:33:25'),
(119, 21, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-07 23:03:21', '2026-03-07 23:33:25'),
(120, 21, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-07 23:03:27', '2026-03-07 23:33:25'),
(121, 12, 'DALAM_PROSES', 'DITOLAK', 3, '', '2026-03-07 23:03:59', '2026-03-07 23:33:25'),
(122, 10, 'DALAM_PROSES', 'DITOLAK', 3, '', '2026-03-07 23:04:00', '2026-03-07 23:33:25'),
(123, 21, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-07 23:04:06', '2026-03-07 23:33:25'),
(124, 21, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-07 23:04:23', '2026-03-07 23:33:25'),
(125, 22, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-07 23:54:20', '2026-03-07 23:54:20'),
(126, 22, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-07 23:54:29', '2026-03-07 23:54:29'),
(127, 22, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-07 23:54:37', '2026-03-07 23:54:37'),
(128, 22, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-07 23:54:50', '2026-03-07 23:54:50'),
(129, 22, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-07 23:55:03', '2026-03-07 23:55:03'),
(130, 23, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-08 21:22:01', '2026-03-08 21:22:01'),
(131, 23, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-08 21:22:12', '2026-03-08 21:22:12'),
(132, 23, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-08 21:22:21', '2026-03-08 21:22:21'),
(133, 23, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-08 21:22:38', '2026-03-08 21:22:38'),
(134, 23, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-08 21:22:56', '2026-03-08 21:22:56'),
(135, 24, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-08 21:32:43', '2026-03-08 21:32:43'),
(136, 24, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-08 21:32:53', '2026-03-08 21:32:53'),
(137, 24, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-08 21:32:59', '2026-03-08 21:32:59'),
(138, 24, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-08 21:33:21', '2026-03-08 21:33:21'),
(139, 24, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-08 21:33:36', '2026-03-08 21:33:36'),
(140, 25, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-08 21:36:21', '2026-03-08 21:36:21'),
(141, 25, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-08 21:36:33', '2026-03-08 21:36:33'),
(142, 26, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-08 21:46:36', '2026-03-08 21:46:36'),
(143, 26, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-08 21:46:49', '2026-03-08 21:46:49'),
(144, 25, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-08 21:47:02', '2026-03-08 21:47:02'),
(145, 26, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-08 21:47:04', '2026-03-08 21:47:04'),
(146, 26, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-08 21:47:17', '2026-03-08 21:47:17'),
(147, 25, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-08 21:47:19', '2026-03-08 21:47:19'),
(148, 26, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-08 21:48:09', '2026-03-08 21:48:09'),
(149, 25, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-08 21:48:14', '2026-03-08 21:48:14'),
(150, 27, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-08 21:52:57', '2026-03-08 21:52:57'),
(151, 27, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-08 21:53:08', '2026-03-08 21:53:08'),
(152, 28, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-08 22:11:47', '2026-03-08 22:11:47'),
(153, 28, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-08 22:12:30', '2026-03-08 22:12:30'),
(154, 28, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-08 22:12:38', '2026-03-08 22:12:38'),
(155, 28, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-08 22:13:06', '2026-03-08 22:13:06'),
(156, 28, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-08 22:13:20', '2026-03-08 22:13:20'),
(157, 27, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-08 22:33:40', '2026-03-08 22:33:40'),
(158, 27, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-08 22:33:53', '2026-03-08 22:33:53'),
(159, 29, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-08 22:47:30', '2026-03-08 22:47:30'),
(160, 29, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-08 22:47:47', '2026-03-08 22:47:47'),
(161, 29, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-08 22:47:57', '2026-03-08 22:47:57'),
(162, 29, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-08 22:49:42', '2026-03-08 22:49:42'),
(163, 29, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-08 23:03:30', '2026-03-08 23:03:30'),
(164, 27, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-08 23:03:52', '2026-03-08 23:03:52'),
(165, 30, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-08 23:04:46', '2026-03-08 23:04:46'),
(166, 30, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-08 23:04:56', '2026-03-08 23:04:56'),
(167, 30, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-08 23:05:05', '2026-03-08 23:05:05'),
(168, 30, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-08 23:05:17', '2026-03-08 23:05:17'),
(169, 30, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-08 23:05:36', '2026-03-08 23:05:36'),
(170, 31, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-08 23:27:59', '2026-03-08 23:27:59'),
(171, 31, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-08 23:28:08', '2026-03-08 23:28:08'),
(172, 31, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-08 23:28:22', '2026-03-08 23:28:22'),
(173, 31, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-08 23:28:31', '2026-03-08 23:28:31'),
(174, 31, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-08 23:44:18', '2026-03-08 23:44:18'),
(175, 32, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-09 00:09:05', '2026-03-09 00:09:05'),
(176, 32, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-09 00:09:15', '2026-03-09 00:09:15'),
(177, 32, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-09 00:09:21', '2026-03-09 00:09:21'),
(178, 32, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-09 00:09:32', '2026-03-09 00:09:32'),
(179, 33, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-09 00:24:35', '2026-03-09 00:24:35'),
(180, 33, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-09 00:24:43', '2026-03-09 00:24:43'),
(181, 33, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-09 00:24:50', '2026-03-09 00:24:50'),
(182, 33, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-09 00:25:02', '2026-03-09 00:25:02'),
(183, 33, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-09 00:25:51', '2026-03-09 00:25:51'),
(184, 34, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-09 07:59:34', '2026-03-09 07:59:34'),
(185, 34, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-03-09 08:01:19', '2026-03-09 08:01:19'),
(186, 34, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-03-09 08:02:18', '2026-03-09 08:02:18'),
(187, 34, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-03-09 08:03:11', '2026-03-09 08:03:11'),
(188, 34, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-03-09 08:04:24', '2026-03-09 08:04:24'),
(189, 35, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-03-15 22:14:06', '2026-03-15 22:14:06'),
(190, 35, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-04-01 22:42:44', '2026-04-01 22:42:44'),
(191, 35, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-04-01 22:43:20', '2026-04-01 22:43:20'),
(192, 35, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-04-01 22:43:36', '2026-04-01 22:43:36'),
(193, 32, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-01 22:44:06', '2026-04-01 22:44:06'),
(194, 36, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-06 15:12:15', '2026-04-06 15:12:15'),
(195, 36, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-04-06 15:13:55', '2026-04-06 15:13:55'),
(196, 36, 'DITERIMA_FO', 'DALAM_PROSES', 2, 'Penugasan ke petugas', '2026-04-06 15:14:21', '2026-04-06 15:14:21'),
(197, 36, 'DALAM_PROSES', 'SIAP_TTD', 3, '', '2026-04-06 15:15:06', '2026-04-06 15:15:06'),
(198, 36, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-06 15:16:38', '2026-04-06 15:16:38'),
(199, 37, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-09 17:49:40', '2026-04-09 17:49:40'),
(200, 37, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-04-09 17:49:55', '2026-04-09 17:49:55'),
(201, 38, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-09 17:50:30', '2026-04-09 17:50:30'),
(202, 38, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-04-09 17:50:34', '2026-04-09 17:50:34'),
(203, 39, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-09 18:28:17', '2026-04-09 18:28:17'),
(204, 40, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-09 18:28:30', '2026-04-09 18:28:30'),
(205, 39, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-04-09 18:28:40', '2026-04-09 18:28:40'),
(206, 40, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-04-09 18:28:40', '2026-04-09 18:28:40'),
(207, 41, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-09 18:45:39', '2026-04-09 18:45:39'),
(208, 41, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-04-09 18:45:44', '2026-04-09 18:45:44'),
(209, 42, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-09 18:52:55', '2026-04-09 18:52:55'),
(210, 42, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-04-09 18:53:03', '2026-04-09 18:53:03'),
(211, 43, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-09 19:10:10', '2026-04-09 19:10:10'),
(212, 43, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-04-09 19:10:14', '2026-04-09 19:10:14'),
(213, 44, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-09 20:18:09', '2026-04-09 20:18:09'),
(214, 44, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-04-09 20:18:13', '2026-04-09 20:18:13'),
(215, 45, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-10 21:25:07', '2026-04-10 21:25:07'),
(216, 46, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-10 21:29:55', '2026-04-10 21:29:55'),
(217, 45, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-04-10 22:22:34', '2026-04-10 22:22:34'),
(218, 46, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-04-10 22:22:36', '2026-04-10 22:22:36'),
(219, 46, 'DIKERJAKAN', 'DITOLAK', 3, '', '2026-04-10 22:24:05', '2026-04-10 22:24:05'),
(220, 45, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-10 22:26:32', '2026-04-10 22:26:32'),
(221, 44, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-10 22:26:34', '2026-04-10 22:26:34'),
(222, 40, 'DIKERJAKAN', 'SIAP_TTD', 6, '', '2026-04-10 22:30:12', '2026-04-10 22:30:12'),
(223, 43, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-10 22:36:50', '2026-04-10 22:36:50'),
(224, 42, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-10 22:50:45', '2026-04-10 22:50:45'),
(225, 41, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-10 22:54:49', '2026-04-10 22:54:49'),
(226, 41, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-10 22:55:38', '2026-04-10 22:55:38'),
(227, 39, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-10 23:15:07', '2026-04-10 23:15:07'),
(228, 37, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-10 23:17:23', '2026-04-10 23:17:23'),
(229, 47, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-11 00:05:40', '2026-04-11 00:05:40'),
(230, 47, NULL, 'DITERIMA_FO', 1, 'Screening FO: diterima', '2026-04-11 00:06:16', '2026-04-11 00:06:16'),
(231, 47, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-11 00:06:46', '2026-04-11 00:06:46'),
(232, 48, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-15 16:34:16', '2026-04-15 16:34:16'),
(233, 48, 'DIAJUKAN', 'DITERIMA_FO', 1, 'Screening FO lulus dan diteruskan ke koordinator', '2026-04-15 22:59:31', '2026-04-15 22:59:31'),
(234, 49, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-15 22:59:52', '2026-04-15 22:59:52'),
(235, 49, 'DIAJUKAN', 'DITOLAK', 1, 'Ditolak saat screening FO', '2026-04-15 23:00:15', '2026-04-15 23:00:15'),
(236, 48, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-15 23:07:18', '2026-04-15 23:07:18'),
(237, 39, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-15 23:07:41', '2026-04-15 23:07:41'),
(238, 37, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-15 23:07:45', '2026-04-15 23:07:45'),
(239, 47, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-15 23:07:55', '2026-04-15 23:07:55'),
(240, 48, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-15 23:07:59', '2026-04-15 23:07:59'),
(241, 50, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-15 23:08:19', '2026-04-15 23:08:19'),
(242, 50, 'DIAJUKAN', 'DITERIMA_FO', 1, 'Screening FO lulus dan diteruskan ke koordinator', '2026-04-15 23:08:37', '2026-04-15 23:08:37'),
(243, 50, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-15 23:09:00', '2026-04-15 23:09:00'),
(244, 50, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-15 23:09:26', '2026-04-15 23:09:26'),
(245, 51, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-15 23:18:03', '2026-04-15 23:18:03'),
(246, 51, 'DIAJUKAN', 'DITERIMA_FO', 1, 'Screening FO lulus dan diteruskan ke koordinator', '2026-04-15 23:20:13', '2026-04-15 23:20:13'),
(247, 51, 'DIKERJAKAN', 'SIAP_TTD', 6, '', '2026-04-15 23:46:38', '2026-04-15 23:46:38'),
(248, 38, 'DIKERJAKAN', 'SIAP_TTD', 6, '', '2026-04-15 23:46:38', '2026-04-15 23:46:38'),
(249, 51, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-15 23:47:03', '2026-04-15 23:47:03'),
(250, 38, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-15 23:47:07', '2026-04-15 23:47:07'),
(251, 52, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-15 23:48:06', '2026-04-15 23:48:06'),
(252, 52, 'DIAJUKAN', 'DITERIMA_FO', 1, 'Screening FO lulus dan diteruskan ke koordinator', '2026-04-15 23:48:25', '2026-04-15 23:48:25'),
(253, 52, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-15 23:48:47', '2026-04-15 23:48:47'),
(254, 52, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-15 23:49:44', '2026-04-15 23:49:44'),
(255, 53, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-16 21:45:56', '2026-04-16 21:45:56'),
(256, 53, 'DIAJUKAN', 'DITERIMA_FO', 1, 'Screening FO lulus dan diteruskan ke koordinator', '2026-04-16 21:46:19', '2026-04-16 21:46:19'),
(257, 54, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-16 21:46:56', '2026-04-16 21:46:56'),
(258, 54, 'DIAJUKAN', 'DITERIMA_FO', 1, 'Screening FO lulus dan diteruskan ke koordinator', '2026-04-16 21:48:01', '2026-04-16 21:48:01'),
(259, 53, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-16 21:48:43', '2026-04-16 21:48:43'),
(260, 54, 'DIKERJAKAN', 'SIAP_TTD', 6, '', '2026-04-16 21:49:09', '2026-04-16 21:49:09'),
(261, 53, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-16 21:49:59', '2026-04-16 21:49:59'),
(262, 54, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-16 21:50:08', '2026-04-16 21:50:08'),
(263, 55, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-17 08:03:22', '2026-04-17 08:03:22'),
(264, 55, 'DIAJUKAN', 'DITOLAK', 1, 'Ditolak saat screening FO', '2026-04-17 08:03:54', '2026-04-17 08:03:54'),
(265, 56, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-17 08:04:11', '2026-04-17 08:04:11'),
(266, 56, 'DIAJUKAN', 'DITERIMA_FO', 1, 'Screening FO lulus dan diteruskan ke koordinator', '2026-04-17 08:04:36', '2026-04-17 08:04:36'),
(267, 56, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-17 08:05:14', '2026-04-17 08:05:14'),
(268, 56, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-17 08:05:54', '2026-04-17 08:05:54'),
(269, 57, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-17 10:00:16', '2026-04-17 10:00:16'),
(270, 57, 'DIAJUKAN', 'DITERIMA_FO', 1, 'Screening FO lulus dan diteruskan ke koordinator', '2026-04-17 10:00:32', '2026-04-17 10:00:32'),
(271, 57, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-17 10:01:11', '2026-04-17 10:01:11'),
(272, 57, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-17 10:01:59', '2026-04-17 10:01:59'),
(273, 58, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-17 10:02:57', '2026-04-17 10:02:57'),
(274, 58, 'DIAJUKAN', 'DITOLAK', 1, 'tidak lengkap', '2026-04-17 10:03:23', '2026-04-17 10:03:23'),
(275, 59, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-17 10:07:10', '2026-04-17 10:07:10'),
(276, 59, 'DIAJUKAN', 'DITERIMA_FO', 1, 'Screening FO lulus dan diteruskan ke koordinator', '2026-04-17 10:09:35', '2026-04-17 10:09:35'),
(277, 59, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-17 10:10:08', '2026-04-17 10:10:08'),
(278, 59, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-17 10:10:34', '2026-04-17 10:10:34'),
(279, 60, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-17 10:14:54', '2026-04-17 10:14:54'),
(280, 60, 'DIAJUKAN', 'DITERIMA_FO', 1, 'Screening FO lulus dan diteruskan ke koordinator', '2026-04-17 10:15:26', '2026-04-17 10:15:26'),
(281, 60, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-17 10:16:22', '2026-04-17 10:16:22'),
(282, 60, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-17 10:16:44', '2026-04-17 10:16:44'),
(283, 61, NULL, 'DIAJUKAN', NULL, 'Pengajuan via web', '2026-04-17 11:03:21', '2026-04-17 11:03:21'),
(284, 61, 'DIAJUKAN', 'DITERIMA_FO', 1, 'Screening FO lulus dan diteruskan ke koordinator', '2026-04-17 11:04:23', '2026-04-17 11:04:23'),
(285, 61, 'DIKERJAKAN', 'SIAP_TTD', 3, '', '2026-04-17 11:06:03', '2026-04-17 11:06:03'),
(286, 61, 'SIAP_TTD', 'SELESAI', NULL, 'Dokumen keluar TTE tersimpan', '2026-04-17 11:06:58', '2026-04-17 11:06:58');

-- --------------------------------------------------------

--
-- Table structure for table `tickets`
--

CREATE TABLE `tickets` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(32) NOT NULL,
  `service_id` int(10) UNSIGNED NOT NULL,
  `applicant_id` bigint(20) UNSIGNED NOT NULL,
  `current_bidang_id` int(10) UNSIGNED DEFAULT NULL,
  `status` varchar(32) NOT NULL,
  `priority` varchar(16) NOT NULL DEFAULT 'NORMAL',
  `sla_due_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `file_tte` varchar(255) DEFAULT NULL,
  `tujuan_petugas` enum('mutasi','kenaikan_pangkat') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tickets`
--

INSERT INTO `tickets` (`id`, `code`, `service_id`, `applicant_id`, `current_bidang_id`, `status`, `priority`, `sla_due_at`, `created_at`, `updated_at`, `file_tte`, `tujuan_petugas`) VALUES
(1, 'TCK-20251029-0001', 1, 1, 2, 'DITOLAK', 'NORMAL', '2025-10-31 15:44:41', '2025-10-29 15:44:41', '2026-03-05 16:21:45', NULL, NULL),
(2, 'TCK-20251029-5237', 2, 2, 2, 'DITOLAK', 'NORMAL', '2025-10-30 15:58:00', '2025-10-29 15:54:34', '2026-03-05 16:21:11', NULL, NULL),
(3, 'TCK-20251029-6438', 2, 3, 2, 'DITOLAK', 'NORMAL', '2025-10-30 17:00:15', '2025-10-29 16:53:40', '2026-03-05 16:21:14', NULL, NULL),
(4, 'TCK-20251029-1697', 1, 2, 1, 'DITERIMA_FO', 'NORMAL', '2025-10-31 17:07:53', '2025-10-29 17:07:17', '2025-10-29 10:07:53', NULL, NULL),
(5, 'TCK-20251029-5393', 1, 2, 4, 'DITERIMA_FO', 'NORMAL', '2025-10-31 17:10:40', '2025-10-29 17:09:45', '2025-10-29 10:10:40', NULL, NULL),
(6, 'TCK-20251029-6083', 2, 2, 3, 'MENUNGGU_DATA', 'NORMAL', '2025-10-30 17:22:20', '2025-10-29 17:12:05', '2025-10-29 10:28:00', NULL, NULL),
(7, 'TCK-20251029-2855', 2, 2, 2, 'DITOLAK', 'NORMAL', '2025-10-30 18:45:55', '2025-10-29 18:36:07', '2026-03-05 16:21:22', NULL, NULL),
(8, 'TCK-20251030-8138', 2, 2, 2, 'DITOLAK', 'NORMAL', '2026-03-06 21:35:31', '2025-10-30 09:29:19', '2026-03-05 16:24:58', NULL, NULL),
(9, 'TCK-20251030-0679', 2, 4, 2, 'SELESAI', 'NORMAL', '2025-10-31 09:34:22', '2025-10-30 09:33:48', '2025-10-30 02:36:28', NULL, NULL),
(10, 'TCK-20260305-4946', 2, 2, 2, 'DITOLAK', 'NORMAL', '2026-03-06 21:35:33', '2026-03-05 21:35:13', '2026-03-07 16:04:00', NULL, NULL),
(11, 'TCK-20260305-9202', 2, 2, NULL, 'DITOLAK', 'NORMAL', NULL, '2026-03-05 22:05:39', '2026-03-05 15:23:29', NULL, NULL),
(12, 'TCK-20260305-8852', 2, 5, 2, 'DITOLAK', 'NORMAL', '2026-03-06 22:55:53', '2026-03-05 22:24:13', '2026-03-07 16:03:59', NULL, NULL),
(13, 'TCK-20260305-9154', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-06 22:55:56', '2026-03-05 22:50:02', '2026-03-06 15:12:38', NULL, NULL),
(14, 'TCK-20260306-5002', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-07 22:15:45', '2026-03-06 22:15:12', '2026-03-06 15:17:03', NULL, NULL),
(15, 'TCK-20260306-7388', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-07 22:27:38', '2026-03-06 22:27:32', '2026-03-06 15:28:09', NULL, NULL),
(16, 'TCK-20260306-4460', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-07 22:36:42', '2026-03-06 22:36:35', '2026-03-06 15:37:38', NULL, NULL),
(17, 'TCK-20260306-7885', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-07 22:43:25', '2026-03-06 22:43:20', '2026-03-06 15:43:48', NULL, NULL),
(18, 'TCK-20260306-6594', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-07 23:08:31', '2026-03-06 23:08:21', '2026-03-06 16:08:56', NULL, NULL),
(19, 'TCK-20260307-5477', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-08 22:45:05', '2026-03-08 20:52:50', '2026-03-08 13:52:50', 'tte_69ac5867e14bc_f_69ac583c3c301_1.2_BAB_I', NULL),
(20, 'TCK-20260307-2675', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-08 22:55:45', '2026-03-07 22:55:07', '2026-03-07 15:56:52', NULL, NULL),
(21, 'TCK-20260307-1527', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-08 23:03:21', '2026-03-07 23:03:12', '2026-03-07 16:04:23', NULL, NULL),
(22, 'TCK-20260307-6870', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-08 23:54:29', '2026-03-07 23:55:03', '2026-03-07 16:55:03', NULL, NULL),
(23, 'TCK-20260308-1502', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-09 21:22:12', '2026-03-08 21:22:56', '2026-03-08 14:22:56', NULL, NULL),
(24, 'TCK-20260308-5529', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-09 21:32:53', '2026-03-08 21:33:36', '2026-03-08 14:33:36', NULL, NULL),
(25, 'TCK-20260308-4601', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-09 21:36:33', '2026-03-08 21:48:14', '2026-03-08 14:48:14', NULL, NULL),
(26, 'TCK-20260308-1195', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-09 21:46:49', '2026-03-08 22:30:42', '2026-03-08 15:30:42', '1772983842_f_69ad91b35c4ad_CV_BONA_2.pdf', NULL),
(27, 'TCK-20260308-6527', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-09 21:53:08', '2026-03-08 23:03:52', '2026-03-08 16:03:52', NULL, NULL),
(28, 'TCK-20260308-7195', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-09 22:12:30', '2026-03-08 22:13:20', '2026-03-08 15:13:20', NULL, NULL),
(29, 'TCK-20260308-9547', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-09 22:47:47', '2026-03-08 23:03:30', '2026-03-08 16:03:30', NULL, NULL),
(30, 'TCK-20260308-9465', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-09 23:04:56', '2026-03-08 23:05:36', '2026-03-08 16:05:36', NULL, NULL),
(31, 'TCK-20260308-1101', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-09 23:28:08', '2026-03-08 23:44:18', '2026-03-08 16:44:18', NULL, NULL),
(32, 'TCK-20260308-6912', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-10 00:09:15', '2026-04-01 22:44:06', '2026-04-01 15:44:06', NULL, NULL),
(33, 'TCK-20260308-7725', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-10 00:24:43', '2026-03-09 00:25:51', '2026-03-08 17:25:51', NULL, NULL),
(34, 'TCK-20260309-5122', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-03-10 08:01:19', '2026-03-09 08:04:24', '2026-03-09 01:04:24', NULL, NULL),
(35, 'TCK-20260315-2692', 2, 2, 2, 'SIAP_TTD', 'NORMAL', '2026-04-02 22:42:44', '2026-04-01 22:43:36', '2026-04-01 15:43:36', NULL, NULL),
(36, 'TCK-20260406-9598', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-04-07 15:13:55', '2026-04-06 15:16:38', '2026-04-06 08:16:38', NULL, NULL),
(37, 'TCK-20260409-9114', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-04-10 17:49:55', '2026-04-15 23:07:45', '2026-04-15 16:07:45', NULL, 'mutasi'),
(38, 'TCK-20260409-3144', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-04-10 17:50:34', '2026-04-15 23:47:07', '2026-04-15 16:47:07', NULL, 'kenaikan_pangkat'),
(39, 'TCK-20260409-3716', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-04-10 18:28:40', '2026-04-15 23:07:41', '2026-04-15 16:07:41', NULL, 'mutasi'),
(40, 'TCK-20260409-8888', 2, 2, 2, 'SIAP_TTD', 'NORMAL', '2026-04-10 18:28:40', '2026-04-10 22:30:12', '2026-04-10 15:30:12', NULL, 'kenaikan_pangkat'),
(41, 'TCK-20260409-3401', 2, 5, 2, 'SELESAI', 'NORMAL', '2026-04-10 18:45:44', '2026-04-10 22:55:38', '2026-04-10 15:55:38', NULL, 'mutasi'),
(42, 'TCK-20260409-9233', 2, 2, 2, 'SIAP_TTD', 'NORMAL', '2026-04-10 18:53:03', '2026-04-10 22:50:45', '2026-04-10 15:50:45', NULL, 'mutasi'),
(43, 'TCK-20260409-9284', 2, 2, 2, 'SIAP_TTD', 'NORMAL', '2026-04-10 19:10:14', '2026-04-10 22:36:50', '2026-04-10 15:36:50', NULL, 'mutasi'),
(44, 'TCK-20260409-8674', 2, 4, 2, 'SIAP_TTD', 'NORMAL', '2026-04-10 20:18:13', '2026-04-10 22:26:34', '2026-04-10 15:26:34', NULL, 'mutasi'),
(45, 'TCK-20260410-0573', 2, 6, 2, 'SIAP_TTD', 'NORMAL', '2026-04-11 22:22:34', '2026-04-10 22:26:32', '2026-04-10 15:26:32', NULL, 'mutasi'),
(46, 'TCK-20260410-1455', 2, 6, 2, 'DITOLAK', 'NORMAL', '2026-04-11 22:22:36', '2026-04-10 22:24:05', '2026-04-10 15:24:05', NULL, 'mutasi'),
(47, 'TCK-20260410-9300', 2, 2, 2, 'SELESAI', 'NORMAL', '2026-04-12 00:06:16', '2026-04-15 23:07:55', '2026-04-15 16:07:55', NULL, 'mutasi'),
(48, 'TCK-20260415-3626', 2, 2, 2, 'SELESAI', 'NORMAL', NULL, '2026-04-15 23:07:59', '2026-04-15 16:07:59', NULL, 'mutasi'),
(49, 'TCK-20260415-0824', 2, 6, NULL, 'DITOLAK', 'NORMAL', NULL, '2026-04-15 23:00:15', '2026-04-15 16:00:15', NULL, NULL),
(50, 'TCK-20260415-2336', 2, 2, 2, 'SELESAI', 'NORMAL', NULL, '2026-04-15 23:09:26', '2026-04-15 16:09:26', NULL, 'mutasi'),
(51, 'TCK-20260415-3113', 2, 2, 2, 'SELESAI', 'NORMAL', NULL, '2026-04-15 23:47:03', '2026-04-15 16:47:03', NULL, 'kenaikan_pangkat'),
(52, 'TCK-20260415-1779', 2, 2, 2, 'SELESAI', 'NORMAL', NULL, '2026-04-15 23:49:44', '2026-04-15 16:49:44', NULL, 'mutasi'),
(53, 'TCK-20260416-2373', 2, 2, 2, 'SELESAI', 'NORMAL', NULL, '2026-04-16 21:49:59', '2026-04-16 14:49:59', NULL, 'mutasi'),
(54, 'TCK-20260416-5263', 2, 2, 2, 'SELESAI', 'NORMAL', NULL, '2026-04-16 21:50:08', '2026-04-16 14:50:08', NULL, 'kenaikan_pangkat'),
(55, 'TCK-20260417-9577', 2, 2, NULL, 'DITOLAK', 'NORMAL', NULL, '2026-04-17 08:03:54', '2026-04-17 01:03:54', NULL, NULL),
(56, 'TCK-20260417-9788', 2, 2, 2, 'SELESAI', 'NORMAL', NULL, '2026-04-17 08:05:54', '2026-04-17 01:05:54', NULL, 'mutasi'),
(57, 'TCK-20260417-4856', 2, 2, 2, 'SELESAI', 'NORMAL', NULL, '2026-04-17 10:01:59', '2026-04-17 03:01:59', NULL, 'mutasi'),
(58, 'TCK-20260417-6217', 2, 2, NULL, 'DITOLAK', 'NORMAL', NULL, '2026-04-17 10:03:23', '2026-04-17 03:03:23', NULL, NULL),
(59, 'TCK-20260417-7324', 2, 2, 2, 'SELESAI', 'NORMAL', NULL, '2026-04-17 10:10:34', '2026-04-17 03:10:34', NULL, 'mutasi'),
(60, 'TCK-20260417-1962', 2, 2, 2, 'SELESAI', 'NORMAL', NULL, '2026-04-17 10:16:44', '2026-04-17 03:16:44', NULL, 'mutasi'),
(61, 'TCK-20260417-2154', 2, 2, 2, 'SELESAI', 'NORMAL', NULL, '2026-04-17 11:06:58', '2026-04-17 04:06:58', NULL, 'mutasi');

-- --------------------------------------------------------

--
-- Table structure for table `ticket_comments`
--

CREATE TABLE `ticket_comments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ticket_id` bigint(20) UNSIGNED NOT NULL,
  `author_user_id` int(10) UNSIGNED DEFAULT NULL,
  `body` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ticket_files`
--

CREATE TABLE `ticket_files` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ticket_id` bigint(20) UNSIGNED NOT NULL,
  `uploaded_by_applicant` tinyint(1) NOT NULL DEFAULT 1,
  `original_name` varchar(255) NOT NULL,
  `stored_path` varchar(400) NOT NULL,
  `sha256` char(64) DEFAULT NULL,
  `size_bytes` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `ticket_files`
--

INSERT INTO `ticket_files` (`id`, `ticket_id`, `uploaded_by_applicant`, `original_name`, `stored_path`, `sha256`, `size_bytes`, `created_at`) VALUES
(1, 2, 1, 'Cuplikan layar 2025-10-02 211633.png', 'uploads/f_6901d64ae7b0c_Cuplikan_layar_2025-10-02_211633.png', NULL, NULL, '2025-10-29 08:54:34'),
(2, 3, 1, 'Cuplikan layar 2025-10-02 211633.png', 'uploads/f_6901e4245c3b0_Cuplikan_layar_2025-10-02_211633.png', NULL, NULL, '2025-10-29 09:53:40'),
(3, 4, 1, 'sinopsis.docx', 'uploads/f_6901e75524289_sinopsis.docx', NULL, NULL, '2025-10-29 10:07:17'),
(4, 5, 1, 'sinopsis.docx', 'uploads/f_6901e7e92a754_sinopsis.docx', NULL, NULL, '2025-10-29 10:09:45'),
(5, 6, 1, '3.+Yutya+Maydila.pdf', 'uploads/f_6901e87580cd7_3._Yutya_Maydila.pdf', NULL, NULL, '2025-10-29 10:12:05'),
(6, 7, 1, 'Cuplikan layar 2025-10-02 211633.png', 'uploads/f_6901fc27aa377_Cuplikan_layar_2025-10-02_211633.png', NULL, NULL, '2025-10-29 11:36:07'),
(7, 8, 1, '2025 Buku monograft Komparasi Algoritma Naïve Bayes dan K-NN dalam Pembagian Bantuan Desa.pdf', 'uploads/f_6902cd7fd594e_2025_Buku_monograft_Komparasi_Algoritma_Na__ve_Bayes_dan_K-NN_dalam_Pembagian_Bantuan_Desa.pdf', NULL, NULL, '2025-10-30 02:29:19'),
(8, 9, 1, 'sinopsis.docx', 'uploads/f_6902ce8c59486_sinopsis.docx', NULL, NULL, '2025-10-30 02:33:48'),
(9, 10, 1, 'Cuplikan layar 2026-03-01 230905.png', 'uploads/f_69a994a14c67d_Cuplikan_layar_2026-03-01_230905.png', NULL, NULL, '2026-03-05 14:35:13'),
(10, 11, 1, 'Cuplikan layar 2025-10-02 211633.png', 'uploads/f_69a99bc3e86c2_Cuplikan_layar_2025-10-02_211633.png', NULL, NULL, '2026-03-05 15:05:39'),
(11, 12, 1, '1.2 BAB I.pdf', 'uploads/f_69a9a01d45c80_1.2_BAB_I.pdf', NULL, NULL, '2026-03-05 15:24:13'),
(12, 13, 1, 'cv bona.pdf', 'uploads/f_69a9a62a59cbb_cv_bona.pdf', NULL, NULL, '2026-03-05 15:50:02'),
(13, 14, 1, '1.2 BAB I.pdf', 'uploads/f_69aaef80ca82b_1.2_BAB_I.pdf', NULL, NULL, '2026-03-06 15:15:12'),
(14, 15, 1, '1.2 BAB I.pdf', 'uploads/f_69aaf2640478c_1.2_BAB_I.pdf', NULL, NULL, '2026-03-06 15:27:32'),
(15, 16, 1, '1.2 BAB I.pdf', 'uploads/f_69aaf48383a05_1.2_BAB_I.pdf', NULL, NULL, '2026-03-06 15:36:35'),
(16, 17, 1, '1.2 BAB I.pdf', 'uploads/f_69aaf61822330_1.2_BAB_I.pdf', NULL, NULL, '2026-03-06 15:43:20'),
(17, 18, 1, '1.2 BAB I.pdf', 'uploads/f_69aafbf55a28c_1.2_BAB_I.pdf', NULL, NULL, '2026-03-06 16:08:21'),
(18, 19, 1, '1.2 BAB I.pdf', 'uploads/f_69ac366e7a705_1.2_BAB_I.pdf', NULL, NULL, '2026-03-07 14:30:06'),
(19, 20, 1, '1.2 BAB I.pdf', 'uploads/f_69ac4a5b983e8_1.2_BAB_I.pdf', NULL, NULL, '2026-03-07 15:55:07'),
(20, 21, 1, '1.2 BAB I.pdf', 'uploads/f_69ac4c4099e58_1.2_BAB_I.pdf', NULL, NULL, '2026-03-07 16:03:12'),
(21, 22, 1, '1.2 BAB I.pdf', 'uploads/f_69ac583c3c301_1.2_BAB_I.pdf', NULL, NULL, '2026-03-07 16:54:20'),
(22, 23, 1, '1.2 BAB I.pdf', 'uploads/f_69ad8609d424f_1.2_BAB_I.pdf', NULL, NULL, '2026-03-08 14:22:01'),
(23, 24, 1, '1.2 BAB I.pdf', 'uploads/f_69ad888b14352_1.2_BAB_I.pdf', NULL, NULL, '2026-03-08 14:32:43'),
(24, 25, 1, 'cv bona.pdf', 'uploads/f_69ad896588627_cv_bona.pdf', NULL, NULL, '2026-03-08 14:36:21'),
(25, 26, 1, 'cv bona.pdf', 'uploads/f_69ad8bcccbc26_cv_bona.pdf', NULL, NULL, '2026-03-08 14:46:36'),
(26, 27, 1, '1.2 BAB I.pdf', 'uploads/f_69ad8d49f310b_1.2_BAB_I.pdf', NULL, NULL, '2026-03-08 14:52:57'),
(27, 28, 1, 'CV BONA 2.pdf', 'uploads/f_69ad91b35c4ad_CV_BONA_2.pdf', NULL, NULL, '2026-03-08 15:11:47'),
(28, 29, 1, 'CV BONA 2.pdf', 'uploads/f_69ad9a12e014d_CV_BONA_2.pdf', NULL, NULL, '2026-03-08 15:47:30'),
(29, 30, 1, 'cv bona.pdf', 'uploads/f_69ad9e1e2ee82_cv_bona.pdf', NULL, NULL, '2026-03-08 16:04:46'),
(30, 31, 1, 'CV BONA 2.pdf', 'uploads/f_69ada38f9d84d_CV_BONA_2.pdf', NULL, NULL, '2026-03-08 16:27:59'),
(31, 32, 1, '1.2 BAB I.pdf', 'uploads/f_69adad313c166_1.2_BAB_I.pdf', NULL, NULL, '2026-03-08 17:09:05'),
(32, 33, 1, 'CV BONA 2.pdf', 'uploads/f_69adb0d3d4eea_CV_BONA_2.pdf', NULL, NULL, '2026-03-08 17:24:35'),
(33, 34, 1, 'dokument.pdf', 'uploads/f_69ae1b76a2996_dokument.pdf', NULL, NULL, '2026-03-09 00:59:34'),
(34, 35, 1, 'BAB IV.pdf', 'uploads/f_69b6ccbe9d748_BAB_IV.pdf', NULL, NULL, '2026-03-15 15:14:06'),
(35, 36, 1, 'transkip nilai.pdf', 'uploads/f_69d36adf6ebaa_transkip_nilai.pdf', NULL, NULL, '2026-04-06 08:12:15'),
(36, 37, 1, 'transkip nilai.pdf', 'uploads/f_69d784444218a_transkip_nilai.pdf', NULL, NULL, '2026-04-09 10:49:40'),
(37, 38, 1, 'ktp.pdf', 'uploads/f_69d78476501e0_ktp.pdf', NULL, NULL, '2026-04-09 10:50:30'),
(38, 39, 1, 'mutasi.pdf', 'uploads/f_69d78d51e3cf7_mutasi.pdf', NULL, NULL, '2026-04-09 11:28:17'),
(39, 40, 1, 'pangkat.pdf', 'uploads/f_69d78d5e115b4_pangkat.pdf', NULL, NULL, '2026-04-09 11:28:30'),
(40, 41, 1, 'mutasi.pdf', 'uploads/f_69d79163a3556_mutasi.pdf', NULL, NULL, '2026-04-09 11:45:39'),
(41, 42, 1, 'mutasi.pdf', 'uploads/f_69d793173dc95_mutasi.pdf', NULL, NULL, '2026-04-09 11:52:55'),
(42, 43, 1, 'mutasi.pdf', 'uploads/f_69d7972238450_mutasi.pdf', NULL, NULL, '2026-04-09 12:10:10'),
(43, 44, 1, 'mutasi.pdf', 'uploads/f_69d7a71172946_mutasi.pdf', NULL, NULL, '2026-04-09 13:18:09'),
(44, 45, 1, 'mutasi.pdf', 'uploads/f_69d9084387ae0_mutasi.pdf', NULL, NULL, '2026-04-10 14:25:07'),
(45, 47, 1, 'mutasi.pdf', 'uploads/f_69d92de4e74f3_mutasi.pdf', NULL, NULL, '2026-04-10 17:05:40'),
(46, 48, 1, 'surat mutasi.pdf', 'uploads/f_69df5b9824e28_surat_mutasi.pdf', NULL, NULL, '2026-04-15 09:34:16'),
(47, 49, 1, 'surat kenaikan pangkat.pdf', 'uploads/f_69dfb5f82b2c6_surat_kenaikan_pangkat.pdf', NULL, NULL, '2026-04-15 15:59:52'),
(48, 50, 1, 'surat mutasi.pdf', 'uploads/f_69dfb7f3823f1_surat_mutasi.pdf', NULL, NULL, '2026-04-15 16:08:19'),
(49, 51, 1, 'surat mutasi.pdf', 'uploads/f_69dfba3ba36a2_surat_mutasi.pdf', NULL, NULL, '2026-04-15 16:18:03'),
(50, 52, 1, 'surat mutasi.pdf', 'uploads/f_69dfc14633ec7_surat_mutasi.pdf', NULL, NULL, '2026-04-15 16:48:06'),
(51, 53, 1, 'surat mutasi.pdf', 'uploads/f_69e0f62478d67_surat_mutasi.pdf', NULL, NULL, '2026-04-16 14:45:56'),
(52, 54, 1, 'surat kenaikan pangkat.pdf', 'uploads/f_69e0f66040ddc_surat_kenaikan_pangkat.pdf', NULL, NULL, '2026-04-16 14:46:56'),
(53, 55, 1, 'surat mutasi.pdf', 'uploads/f_69e186da3b0bd_surat_mutasi.pdf', NULL, NULL, '2026-04-17 01:03:22'),
(54, 56, 1, 'surat mutasi.pdf', 'uploads/f_69e1870b7d83e_surat_mutasi.pdf', NULL, NULL, '2026-04-17 01:04:11'),
(55, 57, 1, 'surat mutasi.pdf', 'uploads/f_69e1a2406f306_surat_mutasi.pdf', NULL, NULL, '2026-04-17 03:00:16'),
(56, 58, 1, 'surat mutasi.pdf', 'uploads/f_69e1a2e16b0b8_surat_mutasi.pdf', NULL, NULL, '2026-04-17 03:02:57'),
(57, 59, 1, 'surat mutasi.pdf', 'uploads/f_69e1a3def31e7_surat_mutasi.pdf', NULL, NULL, '2026-04-17 03:07:10'),
(58, 60, 1, 'surat mutasi.pdf', 'uploads/f_69e1a5aed3232_surat_mutasi.pdf', NULL, NULL, '2026-04-17 03:14:54'),
(59, 61, 1, 'surat mutasi.pdf', 'uploads/f_69e1b109e2bfa_surat_mutasi.pdf', NULL, NULL, '2026-04-17 04:03:21');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(10) UNSIGNED NOT NULL,
  `role_id` int(10) UNSIGNED NOT NULL,
  `bidang_id` int(10) UNSIGNED DEFAULT NULL,
  `name` varchar(128) NOT NULL,
  `email` varchar(191) DEFAULT NULL,
  `phone` varchar(64) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `jenis_petugas` enum('mutasi','kenaikan_pangkat') DEFAULT NULL,
  `password` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `role_id`, `bidang_id`, `name`, `email`, `phone`, `is_active`, `created_at`, `jenis_petugas`, `password`) VALUES
(1, 2, 1, 'Front Office 1', 'fo1@example.local', '0800-0001', 1, '2025-10-29 08:44:41', NULL, '$2y$10$UFJYIsu.mrkrMWBlWvSN/eYYXQWbLCclaL607j/w1ncAqhyvtuaDm'),
(2, 3, 2, 'Koordinator A', 'kor-a@example.local', '0800-0002', 1, '2025-10-29 08:44:41', NULL, '$2y$10$vCrIagSpJp4JMkZE.AOui.S0ILRrdrd8f3TPg0mCE1vAA3VbpQGNC'),
(3, 4, 2, 'Petugas A1', 'pet-a1@example.local', '0800-0003', 1, '2025-10-29 08:44:41', 'mutasi', '$2y$10$7OmJmXHqpN8lkmiYHsA7pu3LRdXtFcDTF0PTCjKb.r9dcqcx1PXje'),
(4, 5, 4, 'Pimpinan', 'pimpinan@example.local', '0800-0004', 1, '2025-10-29 08:44:41', NULL, '$2y$10$Nu.4LMojs1lG7AQxheqQHeE8z89APJ40f79EYXmytVTrD7hjz20q.'),
(5, 3, 3, 'Koordinator B', 'kor-b@example.local', '0800-0005', 1, '2025-10-29 10:21:52', NULL, '$2y$12$6LTTrhxXd.FrC2SNqzG/FOHZ11VVmeGio11GQzKLMTnz6DO5jKQWK'),
(6, 4, 3, 'Petugas B1', 'pet-b1@example.local', '0800-0006', 1, '2025-10-29 10:21:52', 'kenaikan_pangkat', '$2y$10$d6xbw2u6.AaHBVos5ExUA.Y4/fKh3/pumS.zRaM59NMYi6/WY8nGq');

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_ticket_inbox`
-- (See below for the actual view)
--
CREATE TABLE `v_ticket_inbox` (
`id` bigint(20) unsigned
,`code` varchar(32)
,`service` varchar(128)
,`status` varchar(32)
,`priority` varchar(16)
,`sla_due_at` datetime
,`current_bidang_id` int(10) unsigned
,`current_bidang` varchar(128)
,`created_at` datetime
,`updated_at` timestamp
);

-- --------------------------------------------------------

--
-- Structure for view `v_ticket_inbox`
--
DROP TABLE IF EXISTS `v_ticket_inbox`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_ticket_inbox`  AS SELECT `t`.`id` AS `id`, `t`.`code` AS `code`, `sv`.`name` AS `service`, `t`.`status` AS `status`, `t`.`priority` AS `priority`, `t`.`sla_due_at` AS `sla_due_at`, `t`.`current_bidang_id` AS `current_bidang_id`, `b`.`name` AS `current_bidang`, `t`.`created_at` AS `created_at`, `t`.`updated_at` AS `updated_at` FROM ((`tickets` `t` join `services` `sv` on(`sv`.`id` = `t`.`service_id`)) left join `bidang` `b` on(`b`.`id` = `t`.`current_bidang_id`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `applicants`
--
ALTER TABLE `applicants`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `assignments`
--
ALTER TABLE `assignments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_assign_to` (`assigned_to_user_id`),
  ADD KEY `fk_assign_by` (`assigned_by_user_id`),
  ADD KEY `idx_assign_active` (`ticket_id`,`unassigned_at`);

--
-- Indexes for table `bidang`
--
ALTER TABLE `bidang`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `documents_out`
--
ALTER TABLE `documents_out`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_docout_ticket` (`ticket_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_notif_user` (`recipient_user_id`),
  ADD KEY `fk_notif_appl` (`recipient_applicant_id`),
  ADD KEY `fk_notif_ticket` (`ref_ticket_id`);

--
-- Indexes for table `priorities`
--
ALTER TABLE `priorities`
  ADD PRIMARY KEY (`code`);

--
-- Indexes for table `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `services`
--
ALTER TABLE `services`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `fk_services_escalate_bidang` (`escalate_to_bidang_id`);

--
-- Indexes for table `statuses`
--
ALTER TABLE `statuses`
  ADD PRIMARY KEY (`code`);

--
-- Indexes for table `status_history`
--
ALTER TABLE `status_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_hist_ticket` (`ticket_id`),
  ADD KEY `fk_hist_old` (`old_status`),
  ADD KEY `fk_hist_new` (`new_status`),
  ADD KEY `fk_hist_user` (`changed_by`);

--
-- Indexes for table `tickets`
--
ALTER TABLE `tickets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `fk_tickets_service` (`service_id`),
  ADD KEY `fk_tickets_applicant` (`applicant_id`),
  ADD KEY `fk_tickets_priority` (`priority`),
  ADD KEY `idx_tickets_status` (`status`),
  ADD KEY `idx_tickets_sla` (`sla_due_at`),
  ADD KEY `idx_tickets_bidang` (`current_bidang_id`);

--
-- Indexes for table `ticket_comments`
--
ALTER TABLE `ticket_comments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_comments_ticket` (`ticket_id`),
  ADD KEY `fk_comments_author` (`author_user_id`);

--
-- Indexes for table `ticket_files`
--
ALTER TABLE `ticket_files`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_ticket_files_ticket` (`ticket_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `fk_users_role` (`role_id`),
  ADD KEY `fk_users_bidang` (`bidang_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `applicants`
--
ALTER TABLE `applicants`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `assignments`
--
ALTER TABLE `assignments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=91;

--
-- AUTO_INCREMENT for table `bidang`
--
ALTER TABLE `bidang`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `documents_out`
--
ALTER TABLE `documents_out`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=179;

--
-- AUTO_INCREMENT for table `roles`
--
ALTER TABLE `roles`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `services`
--
ALTER TABLE `services`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `status_history`
--
ALTER TABLE `status_history`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=287;

--
-- AUTO_INCREMENT for table `tickets`
--
ALTER TABLE `tickets`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=62;

--
-- AUTO_INCREMENT for table `ticket_comments`
--
ALTER TABLE `ticket_comments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ticket_files`
--
ALTER TABLE `ticket_files`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=60;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `assignments`
--
ALTER TABLE `assignments`
  ADD CONSTRAINT `fk_assign_by` FOREIGN KEY (`assigned_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_assign_ticket` FOREIGN KEY (`ticket_id`) REFERENCES `tickets` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_assign_to` FOREIGN KEY (`assigned_to_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `documents_out`
--
ALTER TABLE `documents_out`
  ADD CONSTRAINT `fk_docout_ticket` FOREIGN KEY (`ticket_id`) REFERENCES `tickets` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_notif_appl` FOREIGN KEY (`recipient_applicant_id`) REFERENCES `applicants` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_notif_ticket` FOREIGN KEY (`ref_ticket_id`) REFERENCES `tickets` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_notif_user` FOREIGN KEY (`recipient_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `services`
--
ALTER TABLE `services`
  ADD CONSTRAINT `fk_services_escalate_bidang` FOREIGN KEY (`escalate_to_bidang_id`) REFERENCES `bidang` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `status_history`
--
ALTER TABLE `status_history`
  ADD CONSTRAINT `fk_hist_new` FOREIGN KEY (`new_status`) REFERENCES `statuses` (`code`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_hist_old` FOREIGN KEY (`old_status`) REFERENCES `statuses` (`code`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_hist_ticket` FOREIGN KEY (`ticket_id`) REFERENCES `tickets` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_hist_user` FOREIGN KEY (`changed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `tickets`
--
ALTER TABLE `tickets`
  ADD CONSTRAINT `fk_tickets_applicant` FOREIGN KEY (`applicant_id`) REFERENCES `applicants` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_tickets_bidang` FOREIGN KEY (`current_bidang_id`) REFERENCES `bidang` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_tickets_priority` FOREIGN KEY (`priority`) REFERENCES `priorities` (`code`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_tickets_service` FOREIGN KEY (`service_id`) REFERENCES `services` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_tickets_status` FOREIGN KEY (`status`) REFERENCES `statuses` (`code`) ON UPDATE CASCADE;

--
-- Constraints for table `ticket_comments`
--
ALTER TABLE `ticket_comments`
  ADD CONSTRAINT `fk_comments_author` FOREIGN KEY (`author_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_comments_ticket` FOREIGN KEY (`ticket_id`) REFERENCES `tickets` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `ticket_files`
--
ALTER TABLE `ticket_files`
  ADD CONSTRAINT `fk_ticket_files_ticket` FOREIGN KEY (`ticket_id`) REFERENCES `tickets` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_bidang` FOREIGN KEY (`bidang_id`) REFERENCES `bidang` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_users_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
