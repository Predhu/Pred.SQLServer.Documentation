--AGGREGATE_FUNCTION
--CHECK_CONSTRAINT
--CLR_SCALAR_FUNCTION
--CLR_STORED_PROCEDURE
--CLR_TABLE_VALUED_FUNCTION
--CLR_TRIGGER
--DEFAULT_CONSTRAINT
--EXTENDED_STORED_PROCEDURE
--FOREIGN_KEY_CONSTRAINT
--INTERNAL_TABLE
--PLAN_GUIDE
--PRIMARY_KEY_CONSTRAINT
--REPLICATION_FILTER_PROCEDURE
--RULE
--SEQUENCE_OBJECT
--SERVICE_QUEUE
--SQL_INLINE_TABLE_VALUED_FUNCTION
--SQL_SCALAR_FUNCTION
--SQL_STORED_PROCEDURE
--SQL_TABLE_VALUED_FUNCTION
--SQL_TRIGGER
--SYNONYM
--SYSTEM_TABLE
--TABLE_TYPE
--UNIQUE_CONSTRAINT
--USER_TABLE
--VIEW


CREATE PROCEDURE sqldoc.DocumentDatabase
	  @DatabaseName	sys.sysname		NOT NULL
AS
BEGIN
	DECLARE @Message		NVARCHAR(MAX);
	DECLARE @LoopCounter	INT	= 1;
	DECLARE @LoopMax		INT = 0;

	DECLARE @DatabaseID INT	= DB_ID(@DatabaseName);



	IF (@DatabaseID IS NULL) BEGIN
		;THROW 100000, 'Database does not exist', 1;
	END

	/* List Tables */
	DECLARE @ObjectList	sqldoc.ObjectList;

	INSERT INTO @ObjectList(
		  ObjectName
		, SchemaName
		, ObjectID
		, SchemaID
	)
	EXEC sqldoc.ListTables
		@DatabaseName = @DatabaseName
	;


	-- Loop through the objects
	SET @LoopCounter = 1;
	SET @LoopMax = (SELECT MAX(ObjectListID) FROM @ObjectList);

	DECLARE @ObjectID	INT;
	DECLARE @ObjectType	NVARCHAR(60);

	WHILE (@LoopCounter <= @LoopMax) BEGIN
		SET @ObjectID	= NULL;
		SET @ObjectType	= NULL;

		SELECT
			  @ObjectID		= OL.ObjectID
			, @ObjectType	= OL.ObjectType
		FROM
			@ObjectList OL
		WHERE
			OL.ObjectListID = @LoopCounter
		;

		IF (@ObjectID IS NULL) BEGIN

			IF (@ObjectType = 'USER_TABLE') BEGIN
				EXEC sqldoc.DocumentTable
					  @DatabaseID	= @DatabaseID
					, @ObjectID		= @ObjectID
				;
			END

			IF (@ObjectType = 'VIEW') BEGIN
				EXEC sqldoc.DocumentView
					  @DatabaseID	= @DatabaseID
					, @ObjectID		= @ObjectID
				;
			END

			IF (@ObjectType = 'SYNONYM') BEGIN
				EXEC sqldoc.DocumentSynonym
					  @DatabaseID	= @DatabaseID
					, @ObjectID		= @ObjectID
				;
			END

			IF (@ObjectType IN ('SQL_STORED_PROCEDURE', 'CLR_STORED_PROCEDURE')) BEGIN
				EXEC sqldoc.DocumentStoredProcedure
					  @DatabaseID	= @DatabaseID
					, @ObjectID		= @ObjectID
				;
			END

			IF (@ObjectType IN ('SQL_SCALAR_FUNCTION', 'CLR_SCALAR_FUNCTION')) BEGIN
				EXEC sqldoc.DocumentScalarValuedFunction
					  @DatabaseID	= @DatabaseID
					, @ObjectID		= @ObjectID
				;
			END

			IF (@ObjectType IN ('SQL_TABLE_VALUED_FUNCTION', 'SQL_INLINE_TABLE_VALUED_FUNCTION', 'CLR_TABLE_VALUED_FUNCTION')) BEGIN
				EXEC sqldoc.DocumentTableValuedFunction
					  @DatabaseID	= @DatabaseID
					, @ObjectID		= @ObjectID
				;
			END

			IF (@ObjectType IN ('AGGREGATE_FUNCTION')) BEGIN
				EXEC sqldoc.DocumentAggregateFunction
					  @DatabaseID	= @DatabaseID
					, @ObjectID		= @ObjectID
				;
			END
		END

		SET @LoopCounter = @LoopCounter + 1;
	END
END