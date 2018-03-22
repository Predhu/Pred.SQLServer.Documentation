/**
 * Sample stored procedure documentation
 * 
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
CREATE PROCEDURE [dbo].[SampleStoredProcedure]
	/**
	 * Extended documentation for Param1
	 * 
	 * @required
	 */
	@param1 int = 0,

	/** Simple textual doc for Param 2 **/
	@param2 int
AS
BEGIN
	SELECT @param1, @param2

	RETURN 0;
END