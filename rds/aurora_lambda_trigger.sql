DROP PROCEDURE IF EXISTS trigger_lambda;
DELIMITER ;;
CREATE PROCEDURE trigger_lambda (
  IN id VARCHAR(255),
  IN customerID VARCHAR(255),
  IN customerBirthday VARCHAR(255),
  IN customerGender VARCHAR(255),
  IN productID VARCHAR(255),
  IN productCategory VARCHAR(255),
  IN productPrice VARCHAR(255)
  ) LANGUAGE SQL 
BEGIN
  CALL mysql.lambda_async('arn:aws:lambda:us-east-1:648911607072:function:day2-log-transfer',
    CONCAT('{ "id" : "', id, 
          '", "customerID" : "', customerID,
          '", "customerBirthday" : "', customerBirthday,
          '", "customerGender" : "', customerGender,
          '", "productID" : "', productID, 
          '", "productCategory" : "', productCategory, 
          '", "productPrice" : "', productPrice,
          '"}')
    );
END
;;
DELIMITER ;

DROP TRIGGER IF EXISTS trigger_lambda;
 
DELIMITER ;;
CREATE TRIGGER trigger_lambda 
  AFTER INSERT ON `order`
  FOR EACH ROW
BEGIN
  SELECT NEW.id, NEW.customerID, New.customerBirthday, New.customerGender, New.productID, New.productCategory, New.productPrice
  INTO @id, @customerID, @customerBirthday, @customerGender, @productID, @productCategory, @productPrice;
  CALL trigger_lambda(@id, @customerID, @customerBirthday, @customerGender, @productID, @productCategory, @productPrice);
END
;;
DELIMITER ;

GRANT EXECUTE ON PROCEDURE mysql.lambda_async TO 'app'@'%'
