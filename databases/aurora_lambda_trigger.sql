-- Stored procedure (Aurora v2)

DROP TRIGGER IF EXISTS on_order_insert;
DELIMITER $$
CREATE TRIGGER on_order_insert
  AFTER INSERT ON `order`
  FOR EACH ROW
BEGIN
  CALL mysql.lambda_async(
    'arn:aws:lambda:ap-northeast-2:<ACCOUNT_ID>:function:day2-order-transfer',
    JSON_OBJECT(
      'id',               NEW.id,
      'customerID',       NEW.customerID,
      'customerBirthday', NEW.customerBirthday,
      'customerGender',   NEW.customerGender,
      'productID',        NEW.productID,
      'productCategory',  NEW.productCategory,
      'productPrice',     NEW.productPrice
    )
  );
END$$
DELIMITER ;

GRANT EXECUTE ON PROCEDURE mysql.lambda_async TO 'app'@'%';

-- Native function (Aurora v3)

SET @result=0;
DROP TRIGGER IF EXISTS on_order_insert;
DELIMITER $$
CREATE TRIGGER on_order_insert
  AFTER INSERT ON `order`
  FOR EACH ROW
BEGIN
  SELECT lambda_async(
    'arn:aws:lambda:ap-northeast-2:<ACCOUNT_ID>:function:day2-order-transfer',
    JSON_OBJECT(
      'id',               NEW.id,
      'customerID',       NEW.customerID,
      'customerBirthday', NEW.customerBirthday,
      'customerGender',   NEW.customerGender,
      'productID',        NEW.productID,
      'productCategory',  NEW.productCategory,
      'productPrice',     NEW.productPrice
    )
  )
   INTO @result;
END$$
DELIMITER ;

GRANT INVOKE LAMBDA ON *.* TO 'app'@'%';
