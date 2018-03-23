SET NOCOUNT ON;

DECLARE @InputTableName NVARCHAR(MAX) = 'config.TableauUser';
DECLARE @SchemaName	sys.sysname	= PARSENAME(@InputTableName, 2)
DECLARE @TableName	sys.sysname	= PARSENAME(@InputTableName, 1)
DECLARE @ObjectID	INT			= OBJECT_ID(CONCAT(QUOTENAME(@SchemaName), '.', QUOTENAME(@TableName)))
DECLARE @SchemaID	INT			= SCHEMA_ID(QUOTENAME(@SchemaName))


DECLARE @LoopCurrent	INT;
DECLARE @LoopMax		INT;
DECLARE @LoopText		NVARCHAR(MAX);


DECLARE @AbstractMarkup NVARCHAR(MAX) = N'h1. Abstract
{excerpt}&#91;Table&#93; $(Excerpt){excerpt}

$(Abstract)';


DECLARE @Structure NVARCHAR(MAX) = N'h1. Structure

|| Column Name || Data Type || Nullability || Default || Description ||
'

DECLARE @Remarks NVARCHAR(MAX) = N'h1. Remarks'

DECLARE @ForeignKeys NVARCHAR(MAX) = N'h1. Foreign Keys'

DECLARE @SeeAlso		NVARCHAR(MAX) = N'h1. See Also'

DECLARE @Title			NVARCHAR(MAX)
DECLARE @Abstract		NVARCHAR(MAX)
DECLARE @Excerpt		NVARCHAR(MAX)


SELECT
	  @Excerpt = CONVERT(NVARCHAR(MAX), EP_E.value)
	, @Abstract = COALESCE(CONVERT(NVARCHAR(MAX), EP_A.value), CONVERT(NVARCHAR(MAX), EP_D.value))
	, @Title = CONCAT(DB_NAME(), N'.', OBJECT_SCHEMA_NAME(T.object_id), '.', OBJECT_NAME(T.object_id))
FROM
	sys.tables T
	LEFT JOIN sys.extended_properties EP_A
		ON T.object_id = EP_A.major_id
			AND EP_A.class = 1
			AND EP_A.value = 'sqldoc.abstract'
	LEFT JOIN sys.extended_properties EP_D
		ON T.object_id = EP_D.major_id
			AND EP_D.class = 1
			AND EP_D.value = 'MS_Description'
	LEFT JOIN sys.extended_properties EP_R
		ON T.object_id = EP_R.major_id
			AND EP_R.class = 1
			AND EP_R.value = 'sqldoc.remarks'
	LEFT JOIN sys.extended_properties EP_E
		ON T.object_id = EP_E.major_id
			AND EP_E.class = 1
			AND EP_E.value = 'sqldoc.excerpt'
WHERE
	T.object_id = @ObjectID
;


DECLARE @Columns TABLE (
	  ColumnID					INT
	, ColumnName				sys.sysname
	, DataType					sys.sysname
	, LengthDefinition			VARCHAR(32)
	, IsNullable				BIT
	, DefaultDefinition			NVARCHAR(MAX)
	, IsComputed				BIT
	, IsPersisted				BIT
	, ComputedColumnDefinition	NVARCHAR(MAX)
	, Description				NVARCHAR(MAX)
	, IsIdentity				BIT
)


INSERT INTO @Columns (
	  ColumnID
	, ColumnName
	, DataType
	, LengthDefinition
	, IsNullable
	, DefaultDefinition
	, IsComputed
	, IsPersisted
	, ComputedColumnDefinition
	, Description
	, IsIdentity
)
SELECT
	  C.column_id	AS ColumnID
	, C.name		AS ColumnName
	, T.name		AS DataType
	, CASE
		/* Exact numerics */
		WHEN T.name IN ('bit', 'tinyint', 'smallint', 'int', 'bigint', 'money', 'smallmoney', 'date', 'datetime', 'text', 'ntext', 'image', 'sql_variant', 'uniqueidentifier', 'hierarchyid', 'timestamp') THEN ''
		WHEN T.name IN ('numeric', 'decimal') THEN CONCAT('(', C.precision, ', ', C.scale, ')')
		WHEN T.name IN ('datetime2', 'datetimeoffset', 'time') THEN CONCAT('(', C.scale, ')')
		WHEN T.name IN ('float', 'real') THEN CONCAT('(', C.precision, ')')
		WHEN T.name IN ('char', 'varchar', 'binary', 'varbinary') THEN IIF(C.max_length = -1, '(MAX)', CONCAT('(', C.max_length ,')'))
		WHEN T.name IN ('nchar', 'nvarchar') THEN IIF(C.max_length = -1, '(MAX)', CONCAT('(', C.max_length / 2 ,')'))
		WHEN T.name IN ('xml') THEN ''
	END				AS LengthDefinition
	, C.is_nullable
	, OBJECT_DEFINITION(C.default_object_id) AS DefaultDefinition
	, C.is_computed
	, CC.is_persisted
	, CC.definition	AS ComputedColumnDefinition
	, COALESCE(CONVERT(NVARCHAR(MAX), EP_A.value), CONVERT(NVARCHAR(MAX), EP_D.value))	AS Description
	, C.is_identity
FROM
	sys.columns C
	INNER JOIN sys.types T
		ON C.system_type_id = T.user_type_id
	LEFT JOIN sys.computed_columns CC
		ON C.object_id = CC.object_id
			AND C.column_id = CC.column_id
	LEFT JOIN sys.extended_properties EP_A
		ON EP_A.major_id = C.object_id
			AND EP_A.minor_id = C.column_id
			AND EP_A.class = 1
			AND EP_A.name = 'sqldoc.description'
	LEFT JOIN sys.extended_properties EP_D
		ON EP_D.major_id = C.object_id
			AND EP_D.minor_id = C.column_id
			AND EP_D.class = 1
			AND EP_D.name = 'MS_Description'
WHERE
	C.object_id = @ObjectID


PRINT @Title
PRINT ''
PRINT REPLACE(REPLACE(@AbstractMarkup, '$(Excerpt)', ISNULL(@Excerpt, @Title)), '$(Abstract)', ISNULL(@Abstract, @Title));
PRINT ''
PRINT @Structure;


SET @LoopCurrent	= 1
SET @LoopMax		= (SELECT MAX(ColumnID) FROM @Columns)
SET @LoopText		= N''

WHILE (@LoopCurrent <= @LoopMax) BEGIN
	SELECT
		@LoopText = CONCAT(
			'| ', C.ColumnName
			, ' | ', UPPER(C.DataType), C.LengthDefinition
			, ' | ', IIF(C.IsNullable = 0, 'NOT NULL', 'NULL')
			, ' | ', IIF(C.DefaultDefinition IS NOT NULL, CONCAT('{code:language=sql}', C.DefaultDefinition, '{code}'), ''), IIF(IsIdentity = 1, 'IDENTITY', '')
			, ' | ', C.Description, IIF(C.IsComputed = 1, CONCAT('{code:language=sql}', C.ComputedColumnDefinition, '{code}'), '')
			, ' |'
		)
	FROM
		@Columns C
	WHERE
		C.ColumnID = @LoopCurrent
	;

	PRINT @LoopText;
	SET @LoopCurrent = @LoopCurrent + 1;
END;


DECLARE @PrimaryKey NVARCHAR(MAX) = '';

/* PRIMARY KEY */
WITH UQCL AS (
	SELECT
		  IL.object_id
		, IL.index_id
		, REPLACE(STUFF((
			SELECT
				CONCAT('$(CRLF)', ' * ', C.name)
			FROM
				sys.index_columns IC
				INNER JOIN sys.columns C
					ON IC.object_id = C.object_id
						AND IC.column_id = C.column_id
			WHERE
				IC.object_id = IL.object_id
				AND IC.index_id = IL.index_id
			ORDER BY
				IC.key_ordinal
			FOR XML PATH('')
		), 1, LEN('$(CRLF)'), ''), '$(CRLF)', CHAR(13) + CHAR(10)) AS ColumnList
	FROM
		sys.indexes IL
)
SELECT
	@PrimaryKey = CONCAT('h1. Primary Key
', I.name, '

', UQCL.ColumnList, '

'
)
FROM
	sys.indexes I
	INNER JOIN UQCL
		ON I.object_id = UQCL.object_id
			AND I.index_id = UQCL.index_id
WHERE
	I.object_id = @ObjectID
	AND I.is_primary_key = 1
;

PRINT '';
PRINT @PrimaryKey;
PRINT '';


DECLARE @UniqueKeyList TABLE (
	  UniqueKeyID	INT	IDENTITY(1,1)
	, UniqueKeyName	sys.sysname
	, ColumnList	NVARCHAR(MAX)
);


/* UNIQUE */
WITH UQCL AS (
	SELECT
		  IL.object_id
		, IL.index_id
		, REPLACE(STUFF((
			SELECT
				CONCAT('$(CRLF)', ' * ', C.name)
			FROM
				sys.index_columns IC
				INNER JOIN sys.columns C
					ON IC.object_id = C.object_id
						AND IC.column_id = C.column_id
			WHERE
				IC.object_id = IL.object_id
				AND IC.index_id = IL.index_id
			ORDER BY
				IC.key_ordinal
			FOR XML PATH('')
		), 1, LEN('$(CRLF)'), ''), '$(CRLF)', CHAR(13) + CHAR(10)) AS ColumnList
	FROM
		sys.indexes IL
)
INSERT INTO @UniqueKeyList (
	  UniqueKeyName
	, ColumnList
)
SELECT
	  I.name
	, UQCL.ColumnList
FROM
	sys.indexes I
	INNER JOIN UQCL
		ON I.object_id = UQCL.object_id
			AND I.index_id = UQCL.index_id
WHERE
	I.object_id = @ObjectID
	AND I.is_unique = 1
;

SET @LoopCurrent	= 1;
SET @LoopMax		= (SELECT MAX(UniqueKeyID) FROM @UniqueKeyList);
SET @LoopText		= N''

PRINT '';
PRINT 'h1. Unique Keys'
PRINT ''

WHILE (@LoopCurrent <= @LoopMax) BEGIN
	SELECT
		@LoopText = CONCAT('h2. ', UQL.UniqueKeyName, '

', UQL.ColumnList, '

'
		)
	FROM
		@UniqueKeyList UQL
	WHERE
		UniqueKeyID = @LoopCurrent
	;

	PRINT @LoopText;
	SET @LoopCurrent = @LoopCurrent + 1;
END




DECLARE @CheckConstraintList TABLE (
	  CheckConstraintID		INT			IDENTITY(1,1)
	, CheckConstraintName	sys.sysname
	, CheckConstraintDefinition NVARCHAR(MAX)
	, Description				NVARCHAR(MAX)
)


/* CHECK */
INSERT INTO @CheckConstraintList (
	  CheckConstraintName
	, CheckConstraintDefinition
	, Description
)
SELECT
	  CC.name	AS CheckConstraintName
	, CC.definition	AS CheckConstraintDefinition
	, ISNULL(CONVERT(NVARCHAR(MAX), EP_A.value), CONVERT(NVARCHAR(MAX), EP_D.value))	AS Description
FROM
	sys.check_constraints CC
	LEFT JOIN sys.extended_properties EP_A
		ON CC.object_id = EP_A.major_id
			AND EP_A.class = 1
			AND EP_A.name = 'sqldoc.description'
	LEFT JOIN sys.extended_properties EP_D
		ON CC.object_id = EP_D.major_id
			AND EP_D.class = 1
			AND EP_D.name = 'MS_Description'
WHERE
	CC.parent_object_id = @ObjectID
;


PRINT '';
PRINT 'h1. Check Constraints';
PRINT '';

SET @LoopCurrent	= 1;
SET @LoopMax		= (SELECT MAX(CheckConstraintID) FROM @CheckConstraintList);
SET @LoopText		= N''


WHILE (@LoopCurrent <= @LoopMax) BEGIN
	SELECT
		@LoopText = CONCAT(N'h2. ', CCL.CheckConstraintName, '

{code:language=sql}', CCL.CheckConstraintDefinition, '{code}

', CCL.Description, '
')
	FROM
		@CheckConstraintList CCL
	WHERE
		CheckConstraintID = @LoopCurrent
	;

	PRINT @LoopText;
	SET @LoopCurrent = @LoopCurrent + 1;
END





/* FOREIGN KEYS */
DECLARE @ForeignKeyList TABLE (
	  ForeignKeyID			INT	IDENTITY(1,1)
	, ConstraintName		sys.sysname
	, ReferencedSchemaName	sys.sysname
	, ReferencedTableName	sys.sysname
	, OnDelete				VARCHAR(32)
	, OnUpdate				VARCHAR(32)
	, ColumnList			NVARCHAR(MAX)
	, Description			NVARCHAR(MAX)
);

WITH FKCL AS (
	SELECT
		FKL.object_id
		, REPLACE(STUFF((
			SELECT
				CONCAT('$(CRLF)', ' | ', CP.name, ' | ', CR.name, ' | ')
			FROM
				sys.foreign_key_columns FKC
				INNER JOIN sys.columns CP
					ON FKC.parent_object_id = CP.object_id
						AND FKC.parent_column_id = CP.column_id
				INNER JOIN sys.columns CR
					ON FKC.referenced_object_id = CR.object_id
						AND FKC.referenced_column_id = CR.column_id
			WHERE
				FKC.constraint_object_id = FKL.object_id
			FOR XML PATH('')
		), 1, LEN('$(CRLF)'), ''), '$(CRLF)', CHAR(13) + CHAR(10)) AS ColumnList
	FROM
		sys.foreign_keys FKL
)
INSERT INTO @ForeignKeyList (
	  ConstraintName
	, ReferencedSchemaName
	, ReferencedTableName
	, OnDelete
	, OnUpdate
	, ColumnList
	, Description
)
SELECT
	  FK.name										AS ConstraintName
	, OBJECT_SCHEMA_NAME(FK.referenced_object_id)	AS ReferencedSchemaName
	, OBJECT_NAME(FK.referenced_object_id)			AS ReferencedTableName
	, FK.delete_referential_action_desc				AS OnDelete
	, FK.update_referential_action_desc				AS OnUpdate
	, FKCL.ColumnList								AS ColumnList
	, ISNULL(CONVERT(NVARCHAR(MAX), EP_A.value), CONVERT(NVARCHAR(MAX), EP_D.value))	AS Description
FROM
	sys.foreign_keys FK
	INNER JOIN FKCL
		ON FK.object_id = FKCL.object_id
	LEFT JOIN sys.extended_properties EP_A
		ON FK.object_id = EP_A.major_id
			AND EP_A.class = 1
			AND EP_A.name = 'sqldoc.description'
	LEFT JOIN sys.extended_properties EP_D
		ON FK.object_id = EP_D.major_id
			AND EP_D.class = 1
			AND EP_D.name = 'MS_Description'
WHERE
	FK.parent_object_id = @ObjectID
ORDER BY
	  OBJECT_SCHEMA_NAME(FK.referenced_object_id)
	, OBJECT_NAME(FK.referenced_object_id)
	, FK.name
;


SET @LoopCurrent	= 1;
SET @LoopMax		= (SELECT MAX(ForeignKeyID) FROM @ForeignKeyList);
SET @LoopText		= N''

PRINT '';
PRINT 'h1. Foreign Keys'
PRINT ''

WHILE (@LoopCurrent <= @LoopMax) BEGIN
	SELECT
		@LoopText = CONCAT(
'h2. ', FKL.ReferencedSchemaName, '.', FKL.ReferencedTableName, ' (', FKL.ConstraintName, ')
^[', DB_NAME(), '.', FKL.ReferencedSchemaName, '.', FKL.ReferencedTableName , '] | *OnDelete:* ', FKL.OnDelete , ' | *OnUpdate:* ', FKL.OnUpdate, '^

|| Local Column || RemoteColumn ||
', FKL.ColumnList, '

'
		)
	FROM
		@ForeignKeyList FKL
	WHERE
		ForeignKeyID = @LoopCurrent
	;

	PRINT @LoopText;
	SET @LoopCurrent = @LoopCurrent + 1;
END



/* Dependencies */

DECLARE @SeeAlsoList TABLE (
	  ReferenceID	INT				NOT NULL	IDENTITY(1,1)
	, Reference		NVARCHAR(MAX)	NOT NULL
);


INSERT INTO @SeeAlsoList (
	Reference
)


SELECT
	CONCAT(DB_NAME(), '.', OBJECT_SCHEMA_NAME(referenced_object_id), '.', OBJECT_NAME(referenced_object_id))
FROM
	sys.foreign_keys FK
WHERE
	parent_object_id = @ObjectID

UNION

SELECT
	CONCAT(DB_NAME(), '.', OBJECT_SCHEMA_NAME(parent_object_id), '.', OBJECT_NAME(parent_object_id))
FROM
	sys.foreign_keys FK
WHERE
	referenced_object_id = @ObjectID

UNION

SELECT
	CONCAT(DB_NAME(), '.', OBJECT_SCHEMA_NAME(referenced_major_id), '.', OBJECT_NAME(referenced_major_id))
FROM
	sys.sql_dependencies
WHERE
	object_id = @ObjectID

UNION

SELECT
	CONCAT(DB_NAME(), '.', OBJECT_SCHEMA_NAME(object_id), '.', OBJECT_NAME(object_id))
FROM
	sys.sql_dependencies
WHERE
	referenced_major_id = @ObjectID

UNION

SELECT
	CONCAT(DB_NAME(), '.', OBJECT_SCHEMA_NAME(referencing_id), '.', OBJECT_NAME(referencing_id))
FROM
	sys.sql_expression_dependencies
WHERE
	referenced_id = @ObjectID

UNION

SELECT
	CONCAT(ISNULL(referenced_database_name, DB_NAME()), '.', referenced_schema_name, '.', referenced_entity_name)
FROM
	sys.sql_expression_dependencies
WHERE
	referencing_id = @ObjectID
;

PRINT '';
PRINT @SeeAlso;
PRINT '';


SET @LoopCurrent	= 1;
SET @LoopMax		= (SELECT MAX(ReferenceID) FROM @SeeAlsoList);
SET @LoopText		= N''


WHILE (@LoopCurrent <= @LoopMax) BEGIN
	SELECT
		@LoopText = Reference
	FROM
		@SeeAlsoList
	WHERE
		ReferenceID = @LoopCurrent
	;

	PRINT CONCAT('* [', @LoopText, ']');
	SET @LoopCurrent = @LoopCurrent + 1;
END



--SELECT
--	*
--FROM
--	@SeeAlsoList