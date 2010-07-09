ALTER TABLE `smsd`.`outbox` ENGINE = InnoDB;
ALTER TABLE `smsd`.`outbox` ADD INDEX `CreatorID`(`CreatorID`(64)),
 ADD INDEX `DestinationNumber`(`DestinationNumber`),
 ADD INDEX `MultiPart`(`MultiPart`);

ALTER TABLE `smsd`.`inbox` ENGINE = InnoDB;
ALTER TABLE `smsd`.`inbox` ADD INDEX `Processed`(`Processed`),
 ADD INDEX `RecipientID`(`RecipientID`(64));

ALTER TABLE `smsd`.`sentitems` ENGINE = InnoDB;
ALTER TABLE `smsd`.`sentitems` ADD INDEX `CreatorID`(`CreatorID`(64)),
 ADD INDEX `Status`(`Status`);

CREATE TABLE `smsd`.`inbox_relay` (
  `ID` INTEGER  NOT NULL,
  `sender_number` VARCHAR(20) NOT NULL,
  `message` TEXT NOT NULL,
  `received_at` DATETIME NOT NULL,
  `recipient_id` VARCHAR(64) DEFAULT NULL,
  `network` VARCHAR(64)  DEFAULT NULL,
  `sent_at` DATETIME  DEFAULT NULL,
  `worked_at` DATETIME  DEFAULT NULL,
  `rt_at` DATETIME DEFAULT NULL,
  `try_count` INTEGER  NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`),
  INDEX `recipient_id`(`recipient_id`),
  INDEX `sent_at`(`sent_at`),
  INDEX `worked_at`(`worked_at`),
  INDEX `try_count`(`try_count`)
)
ENGINE = InnoDB;
