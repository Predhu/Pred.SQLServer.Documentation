CREATE FUNCTION sqldoc.BuildObjectName
(
	  @DatabaseName	sys.sysname	NOT NULL
	, @SchemaName	sys.sysname	NOT NULL
	, @ObjectName	sys.sysname	NOT NULL
	, @DoQuote		BIT			NOT NULL	= 1
)
RETURNS NVARCHAR(512)
AS
BEGIN
	DECLARE @QualifiedName NVARCHAR(512) = CONCAT(@DatabaseName, @SchemaName, @ObjectName);

	SET @DatabaseName = PARSENAME(@QualifiedName, 3);
	SET @SchemaName = PARSENAME(@QualifiedName, 2);
	SET @ObjectName = PARSENAME(@QualifiedName, 1);

	IF (@DoQuote = 1) BEGIN
		SET @QualifiedName = CONCAT(QUOTENAME(@DatabaseName), '.', QUOTENAME(@SchemaName), '.', QUOTENAME(@ObjectName));
	END
	ELSE BEGIN
		SET @QualifiedName = CONCAT(@DatabaseName, '.', @SchemaName, '.', @ObjectName);
	END

	RETURN @QualifiedName;
END
