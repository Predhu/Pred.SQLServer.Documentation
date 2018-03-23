CREATE FUNCTION sqldoc.ResolveDatabaseID
(
	  @DatabaseName	sys.sysname	NULL	= NULL
	, @DatabaseID	INT			NULL	= NULL
)
RETURNS INT
AS
BEGIN
	/* Nothing is set, get the current database. */
	IF (@DatabaseName IS NULL OR @DatabaseID IS NULL) BEGIN
		SET @DatabaseName	= DB_NAME();
		SET @DatabaseID		= DB_ID();
	END

	/* When Database name is set, use it and discard @DatabaseID */
	IF (@DatabaseName IS NOT NULL) BEGIN
		SET @DatabaseID = DB_ID(@DatabaseName);
	END

	/* Check if database exists by ID */
	IF (NOT EXISTS (SELECT * FROM sys.databases WHERE database_id = @DatabaseID)) BEGIN
		SET @DatabaseID = NULL;
		SET @DatabaseName = NULL;
	END

	RETURN @DatabaseID;
END
