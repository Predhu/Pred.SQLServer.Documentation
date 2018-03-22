using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.SqlServer.Management.SqlParser;
using Microsoft.SqlServer.Management.SqlParser.Parser;



namespace Pred.SQLServer.Documentation.CommandLine.src.Parser
{
    class SQLServerQueryParser
    {



        IEnumerable<Tokens> ParseSql(string sql)
        {
            ParseOptions parseOptions = new ParseOptions();
            Scanner scanner = new Scanner(parseOptions);

            int state = 0;
            int start;
            int end;
            int lastTokenEnd;
            int token;

            bool isPairMatch;
            bool isExecAutoParamHelp;

            List<Token> tokens = new List<Token>();

            scanner.SetSource(sql, 0);

            while (token = scanner.GetNext(ref state, out start, out end, out isPairMatch, out isExecAutoParamHelp) != (int)Tokens.EOF)
            {

            }
        }
    }
}
