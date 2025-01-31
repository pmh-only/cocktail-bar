-- RatingQuery

SELECT AVG(rating)
FROM dev.public.review
WHERE productcategory='jean' AND authorage BETWEEN 20 AND 29;

-- VIPQuery
SELECT customerid, customerage, customergender
FROM "order"
ORDER BY productprice DESC
LIMIT 1;
