CREATE TYPE sqldoc.ObjectList AS TABLE
(
	  ObjectListID	INT				NOT NULL	IDENTITY(1,1)
	, ObjectName	sys.sysname		NOT NULL
	, SchemaName	sys.sysname		NOT NULL
	, ObjectID		INT				NOT NULL
	, SchemaID		INT				NOT NULL
	, ObjectType	NVARCHAR(60)	NOT NULL

	, PRIMARY KEY (ObjectListID)
);
