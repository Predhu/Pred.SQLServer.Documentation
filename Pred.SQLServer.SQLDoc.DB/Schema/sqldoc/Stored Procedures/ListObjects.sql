CREATE PROCEDURE sqldoc.ListTables
	@DatabaseName	sys.sysname	NOT NULL
AS
BEGIN
	DECLARE @DynamicSQL NVARCHAR(MAX) = '
SELECT
	  name							AS ObjectName
	, OBJECT_SCHEMA_NAME(object_id)	AS SchemaName
	, object_id						AS ObjectID
	, schema_id						AS SchemaID
	, type_desc						AS ObjectType
FROM
	$(DB_NAME).sys.objects
WHERE
	type_desc IN (
		  ''AGGREGATE_FUNCTION''
		, ''CLR_SCALAR_FUNCTION''
		, ''CLR_STORED_PROCEDURE''
		, ''CLR_TABLE_VALUED_FUNCTION''
		, ''SQL_INLINE_TABLE_VALUED_FUNCTION''
		, ''SQL_SCALAR_FUNCTION''
		, ''SQL_STORED_PROCEDURE''
		, ''SQL_TABLE_VALUED_FUNCTION''
		, ''SYNONYM''
		, ''USER_TABLE
		, ''VIEW''
	)
';

	SET @DynamicSQL = REPLACE(@DynamicSQL, '$(DB_NAME)', QUOTENAME(@DatabaseName));

	EXEC sys.sp_executesql
		@stmt = @DynamicSQL
	;
END