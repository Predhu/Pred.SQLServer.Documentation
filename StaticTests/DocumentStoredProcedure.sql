SET NOCOUNT ON;

DECLARE @ModuleInputName	NVARCHAR(MAX) = 'ibi.Logic_GetNationalityBenchmark'

DECLARE @SchemaName	sys.sysname	= PARSENAME(@ModuleInputName, 2);
DECLARE @ModuleName	sys.sysname	= PARSENAME(@ModuleInputName, 1);
DECLARE @ObjectID	INT			= OBJECT_ID(CONCAT(QUOTENAME(@SchemaName), '.', QUOTENAME(@ModuleName)));
DECLARE @SchemaID	INT			= SCHEMA_ID(QUOTENAME(@SchemaName));

DECLARE @ModuleDefinition	NVARCHAR(MAX);
DECLARE @ModuleExcerpt		NVARCHAR(MAX);
DECLARE @ModuleAbstract		NVARCHAR(MAX);


DECLARE @LoopCurrent	INT;
DECLARE @LoopMax		INT;
DECLARE @LoopText		NVARCHAR(MAX);

SELECT
	  @ModuleDefinition = M.definition
	, @ModuleExcerpt = CONVERT(NVARCHAR(MAX), EP_E.value)
	, @ModuleAbstract = COALESCE(CONVERT(NVARCHAR(MAX), EP_A.value), CONVERT(NVARCHAR(MAX), EP_D.value))
FROM
	sys.objects O
	INNER JOIN sys.sql_modules M
		ON M.object_id = O.object_id
	LEFT JOIN sys.extended_properties EP_E
		ON O.object_id = EP_E.major_id
			AND EP_E.class = 0
			AND EP_E.name = 'sqldoc.excerpt'
	LEFT JOIN sys.extended_properties EP_A
		ON O.object_id = EP_A.major_id
			AND EP_A.class = 0
			AND EP_A.name = 'sqldoc.abstract'
	LEFT JOIN sys.extended_properties EP_D
		ON O.object_id = EP_D.major_id
			AND EP_D.class = 0
			AND EP_D.name = 'MS_Description'
WHERE
	O.object_id = @ObjectID
;


PRINT CONCAT(DB_NAME(), '.', @SchemaName, '.', @ModuleName);
PRINT '';


PRINT 'h1. Abstract';
PRINT CONCAT('{excerpt}&#91;SP&#93; ', ISNULL(@ModuleExcerpt, CONCAT(DB_NAME(), '.', @SchemaName, '.', @ModuleName)), '{excerpt}');
PRINT '';
PRINT ISNULL(@ModuleAbstract, CONCAT(DB_NAME(), '.', @SchemaName, '.', @ModuleName));
PRINT '';


DECLARE @ParamList TABLE (
	ParamID		INT
	, ParamName sys.sysname
	, ParamType	sys.sysname
	, LengthDefinition	NVARCHAR(16)
	, IsNullable	BIT
	, IsReadOnly	BIT
	, IsOutput		BIT
	, IsCursorRef	BIT
	, Description	NVARCHAR(MAX)
	, Remarks		NVARCHAR(MAX)
)


INSERT INTO @ParamList (
	  ParamID
	, ParamName
	, ParamType
	, LengthDefinition
	, IsNullable
	, IsReadOnly
	, IsOutput
	, IsCursorRef
	, Description
	, Remarks
)
SELECT
	  P.parameter_id
	, P.name
	, T.name	AS DataType
	, CASE
		/* Exact numerics */
		WHEN T.name IN ('bit', 'tinyint', 'smallint', 'int', 'bigint', 'money', 'smallmoney', 'date', 'datetime', 'text', 'ntext', 'image', 'sql_variant', 'uniqueidentifier', 'hierarchyid', 'timestamp') THEN ''
		WHEN T.name IN ('numeric', 'decimal') THEN CONCAT('(', P.precision, ', ', P.scale, ')')
		WHEN T.name IN ('datetime2', 'datetimeoffset', 'time') THEN CONCAT('(', P.scale, ')')
		WHEN T.name IN ('float', 'real') THEN CONCAT('(', P.precision, ')')
		WHEN T.name IN ('char', 'varchar', 'binary', 'varbinary') THEN IIF(P.max_length = -1, '(MAX)', CONCAT('(', P.max_length ,')'))
		WHEN T.name IN ('nchar', 'nvarchar') THEN IIF(P.max_length = -1, '(MAX)', CONCAT('(', P.max_length / 2 ,')'))
		WHEN T.name IN ('xml') THEN ''
	END				AS LengthDefinition
	, P.is_nullable
	, P.is_readonly
	, P.is_output
	, P.is_cursor_ref
	, COALESCE(CONVERT(NVARCHAR(MAX), EP_A.value), CONVERT(NVARCHAR(MAX), EP_D.value))	AS Description
	, CONVERT(NVARCHAR(MAX), EP_R.value)	AS Remarks
FROM
	sys.parameters P
	INNER JOIN sys.types T
		ON P.system_type_id = T.user_type_id
	LEFT JOIN sys.extended_properties EP_A
		ON EP_A.major_id = P.object_id
			AND EP_A.minor_id = P.parameter_id
			AND EP_A.class = 1
			AND EP_A.name = 'sqldoc.description'
	LEFT JOIN sys.extended_properties EP_D
		ON EP_D.major_id = P.object_id
			AND EP_D.minor_id = P.parameter_id
			AND EP_D.class = 1
			AND EP_D.name = 'MS_Description'
	LEFT JOIN sys.extended_properties EP_R
		ON EP_R.major_id = P.object_id
			AND EP_R.minor_id = P.parameter_id
			AND EP_R.class = 1
			AND EP_R.name = 'sqldoc.remarks'
WHERE
	object_id = @ObjectID
;



/**/
DECLARE @Syntax NVARCHAR(MAX) = CONCAT(@SchemaName, '.', @ModuleName);


DECLARE @ArgumentList NVARCHAR(MAX) = '
|| Argument Name || Data Type || Nullability || Default || Read Only || Output || Description ||';

DECLARE @ArgumentRemarks NVARCHAR(MAX);

SET @LoopCurrent	= 1
SET @LoopMax		= (SELECT MAX(ParamID) FROM @ParamList)
SET @LoopText		= N''

WHILE (@LoopCurrent <= @LoopMax) BEGIN
	SELECT
		  @Syntax = CONCAT(@Syntax, CHAR(13), CHAR(10), CHAR(9), IIF(@LoopCurrent > 1, ', ', '  '), PL.ParamName)
		, @ArgumentList = CONCAT(@ArgumentList, CHAR(13), CHAR(10), '| ', PL.ParamName, ' | ', PL.ParamType, PL.LengthDefinition, ' | ', IIF(PL.IsNullable = 0, 'NOT NULL', 'NULL'), ' |  | ', IIF(PL.IsReadOnly = 1, 'READ_ONLY', '-'), ' | ', IIF(PL.IsOutput = 1, 'OUTPUT', '-'), ' | ', PL.Description, ' |')
		, @LoopText = CONCAT('h2. ', PL.ParamName, '
^', PL.ParamType, PL.LengthDefinition, IIF(PL.IsNullable = 0, ' | NOT NULL', ''), IIF(PL.IsOutput = 1, ' | OUTPUT', ''), IIF(PL.IsReadOnly = 1, ' | READ_ONLY', ''), '^
', PL.Description, '
', PL.Remarks
)
	FROM
		@ParamList PL
	WHERE
		PL.ParamID = @LoopCurrent
	;

	SET @ArgumentRemarks = CONCAT(@ArgumentRemarks, IIF(@LoopCurrent > 1, CONCAT(CHAR(13), CHAR(10)), ''), @LoopText);
	SET @LoopCurrent = @LoopCurrent + 1;
END;


PRINT 'h1. Syntax';
PRINT CONCAT('{code:language=sql}', @Syntax, '{code}');
PRINT '';

PRINT 'h1. Return Code Values';
PRINT '|| Return Code || Description || Remarks ||'
PRINT '| 0 | Success | The stored procedure finished successfully |'
PRINT '';
PRINT 'h1. Arguments';
PRINT @ArgumentList;
PRINT '';
PRINT @ArgumentRemarks;


/* Result Set */
DECLARE @RSColumns TABLE (
	  ColumnID					INT
	, ColumnName				sys.sysname
	, DataType					sys.sysname
	, LengthDefinition			VARCHAR(32)
	, IsNullable				BIT
);


INSERT INTO @RSColumns (
	  ColumnID
	, ColumnName
	, DataType
	, LengthDefinition
	, IsNullable
)
SELECT
	  RS.column_ordinal	AS ColumnID
	, RS.name		AS ColumnName
	, T.name		AS DataType
	--, RS.system_type_name
	, CASE
		/* Exact numerics */
		WHEN T.name IN ('bit', 'tinyint', 'smallint', 'int', 'bigint', 'money', 'smallmoney', 'date', 'datetime', 'text', 'ntext', 'image', 'sql_variant', 'uniqueidentifier', 'hierarchyid', 'timestamp') THEN ''
		WHEN T.name IN ('numeric', 'decimal') THEN CONCAT('(', RS.precision, ', ', RS.scale, ')')
		WHEN T.name IN ('datetime2', 'datetimeoffset', 'time') THEN CONCAT('(', RS.scale, ')')
		WHEN T.name IN ('float', 'real') THEN CONCAT('(', RS.precision, ')')
		WHEN T.name IN ('char', 'varchar', 'binary', 'varbinary') THEN IIF(RS.max_length = -1, '(MAX)', CONCAT('(', RS.max_length ,')'))
		WHEN T.name IN ('nchar', 'nvarchar') THEN IIF(RS.max_length = -1, '(MAX)', CONCAT('(', RS.max_length / 2 ,')'))
		WHEN T.name IN ('xml') THEN ''
	END				AS LengthDefinition
	, RS.is_nullable

FROM
	sys.dm_exec_describe_first_result_set_for_object(@ObjectID, 1) RS
	INNER JOIN sys.types T
		ON RS.system_type_id = T.user_type_id

;

PRINT 'h1. Result Set';
PRINT '';
PRINT '|| Column Name || Data Type || Nullability || Description ||'

SET @LoopCurrent	= 1
SET @LoopMax		= (SELECT MAX(ColumnID) FROM @RSColumns)
SET @LoopText		= N''

WHILE (@LoopCurrent <= @LoopMax) BEGIN
	SELECT
		@LoopText = CONCAT(
			'| ', C.ColumnName
			, ' | ', UPPER(C.DataType), C.LengthDefinition
			, ' | ', IIF(C.IsNullable = 0, 'NOT NULL', 'NULL')
			, ' |'
		)
	FROM
		@RSColumns C
	WHERE
		C.ColumnID = @LoopCurrent
	;

	PRINT @LoopText;
	SET @LoopCurrent = @LoopCurrent + 1;
END;



PRINT 'h1. Examples';
PRINT '';
PRINT '';


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

DECLARE @SeeAlso		NVARCHAR(MAX) = N'h1. See Also'

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

PRINT '';
PRINT 'h1. Source Code'
PRINT CONCAT('{code:language=sql|title=Source Code of ', DB_NAME(), '.', @SchemaName, '.', @ModuleName, '|collapse=true|linenumbers=true}', @ModuleDefinition ,'{code}');
PRINT '';