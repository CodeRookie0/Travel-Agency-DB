--This SQL query returns the names of all views contained in the 'dbo' schema in the database.

SELECT TABLE_NAME AS ViewName
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'dbo';
