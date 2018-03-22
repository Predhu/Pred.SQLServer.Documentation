/**
 * **Markdown** enabled Function documentation.
 *
 * @author {Username}
 * @version {Version}
 * @see {Reference}
 * @throws {ErrorNumber} {Description}
 * @returns
 * @deprecated
 *
 * @example
 * 
 */
CREATE FUNCTION [dbo].[SampleScalarFunction]
(
	/** Parameter doc */
	@param1 INT,
	/** Parameter doc */
	@param2 INT
)
RETURNS INT
AS
BEGIN
	RETURN @param1 + @param2
END
