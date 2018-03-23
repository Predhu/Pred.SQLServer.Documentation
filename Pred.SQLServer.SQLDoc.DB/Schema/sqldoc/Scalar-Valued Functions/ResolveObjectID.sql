CREATE FUNCTION sqldoc.ResolveObjectID
(
	  @DatabaseID	INT			NOT NULL
	, @SchemaName	sys.sysname	NULL	= NULL
	, @ObjectName	sys.sysname	NULL	= NULL
	, @ObjectID		INT			NULL	= NULL
)
RETURNS INT
AS
BEGIN
	SET @DatabaseID = sqldoc.ResolveDatabaseID(NULL, @DatabaseID);
	IF (@DatabaseID IS NULL) BEGIN
		SET @SchemaName	= NULL;
		SET @ObjectName	= NULL;
		SET @ObjectID	= NULL;
	END

	IF (PARSENAME(@ObjectName, 2) IS NOT NULL) BEGIN
		SET @SchemaName = PARSENAME(@ObjectName, 2);
	END

	IF (@SchemaName IS NULL) BEGIN
		SET @SchemaName = SCHEMA_NAME();
	END

	IF (@SchemaName IS NOT NULL AND @ObjectName IS NOT NULL) BEGIN
		SET @ObjectID = OBJECT_ID(sqldoc.BuildObjectName(DB_NAME(@DatabaseID), @SchemaName, @ObjectName, 1));
	END

	/* Check if object name exists */
	IF (OBJECT_NAME(@ObjectID, @DatabaseID) IS NULL) BEGIN
		SET @ObjectID = NULL;
	END

	RETURN @ObjectID;
END
