CREATE PROCEDURE sqldoc.DocumentTable
	  @DatabaseName	sys.sysname	NULL	= NULL
	, @SchemaName	sys.sysname	NULL	= NULL
	, @ObjectName	sys.sysname	NULL	= NULL
	, @DatabaseID	INT			NULL	= NULL
	, @ObjectID		INT			NULL	= NULL
AS
BEGIN
	DECLARE @Message NVARCHAR(MAX);

	SET @DatabaseID = sqldoc.ResolveDatabaseID(@DatabaseName, @DatabaseID);
	IF (@DatabaseID IS NULL) BEGIN
		SET @Message = N'Database is not set or not found. Check your privileges and if the database exists and accessible.';
		THROW 110001, @Message, 1;
	END

	SET @DatabaseName = DB_NAME(@DatabaseID);
	
	/* Get the object */
	SET @ObjectID = sqldoc.ResolveObjectID(@DatabaseName, @SchemaName, @ObjectName);
	IF (@ObjectID IS NULL) BEGIN
		SET @Message = N'Object not found.';
	END

	SET @SchemaName = OBJECT_SCHEMA_NAME(@ObjectID, @DatabaseID);
	SET @ObjectName	= OBJECT_NAME(@ObjectName, @DatabaseID)
	
	
	DECLARE @TableExcerpt			NVARCHAR(MAX);
	DECLARE @TableDescription		NVARCHAR(MAX);
	DECLARE @TableRemarks			NVARCHAR(MAX);
	DECLARE @ExtendedPropertyValue	NVARCHAR(MAX);
	
	DECLARE @ExtendedProperyQuery NVARCHAR(MAX) = CONCAT(N'
SELECT
	@TableExcerpt = CONVERT(NVARCHAR(MAX), EP.value)
FROM
	', QUOTENAME(@DatabaseName), N'.sys.extended_properties EP
WHERE
	EP.major_id = @ObjectID
	AND EP.class = 1
	AND EP.name = @ExtendedPropertyName
;
	');

	EXEC sys.sp_executesql
		  @stmt						= @ExtendedProperyQuery
		, @paraeters				= N'@ObjectID INT, @ExtendedPropertyName sys.sysname, @ExtendedPropertyValue NVARCHAR(MAX) OUTPUT'
		, @ObjectID					= @ObjectID
		, @ExtendedPropertyName		= 'sqldoc.excerpt'
		, @ExtendedPropertyValue	= @ExtendedPropertyValue OUTPUT
	;
	SET @TableExcerpt = ISNULL(@ExtendedPropertyValue, 'Excerpt Not Set');

	EXEC sys.sp_executesql
		  @stmt						= @ExtendedProperyQuery
		, @paraeters				= N'@ObjectID INT, @ExtendedPropertyName sys.sysname, @ExtendedPropertyValue NVARCHAR(MAX) OUTPUT'
		, @ObjectID					= @ObjectID
		, @ExtendedPropertyName		= 'sqldoc.abstract'
		, @ExtendedPropertyValue	= @ExtendedPropertyValue OUTPUT
	;
	SET @TableDescription = ISNULL(@ExtendedPropertyValue, '');

	EXEC sys.sp_executesql
		  @stmt						= @ExtendedProperyQuery
		, @paraeters				= N'@ObjectID INT, @ExtendedPropertyName sys.sysname, @ExtendedPropertyValue NVARCHAR(MAX) OUTPUT'
		, @ObjectID					= @ObjectID
		, @ExtendedPropertyName		= 'sqldoc.description'
		, @ExtendedPropertyValue	= @ExtendedPropertyValue OUTPUT
	;
	SET @TableDescription = CONCAT(IIF(@TableDescription = '', '', CONCAT(@TableDescription, CHAR(13), CHAR(10))), ISNULL(@ExtendedPropertyValue, ''));

	EXEC sys.sp_executesql
		  @stmt						= @ExtendedProperyQuery
		, @paraeters				= N'@ObjectID INT, @ExtendedPropertyName sys.sysname, @ExtendedPropertyValue NVARCHAR(MAX) OUTPUT'
		, @ObjectID					= @ObjectID
		, @ExtendedPropertyName		= 'MS_Description'
		, @ExtendedPropertyValue	= @ExtendedPropertyValue OUTPUT
	;
	SET @TableDescription = CONCAT(IIF(@TableDescription = '', '', CONCAT(@TableDescription, CHAR(13), CHAR(10))), ISNULL(@ExtendedPropertyValue, ''));

	EXEC sys.sp_executesql
		  @stmt						= @ExtendedProperyQuery
		, @paraeters				= N'@ObjectID INT, @ExtendedPropertyName sys.sysname, @ExtendedPropertyValue NVARCHAR(MAX) OUTPUT'
		, @ObjectID					= @ObjectID
		, @ExtendedPropertyName		= 'sqldoc.remarks'
		, @ExtendedPropertyValue	= @ExtendedPropertyValue OUTPUT
	;
	SET @TableRemarks = @ExtendedPropertyValue;




	RETURN 0;
END