module util.tokeniser;

import std.string : format, indexOf;

/**
a string-aware, stateful tokeniser that operates on an immutable buffer of bytes and produces tokens as slices.  

the primary way to consume tokens is to repeatedly `scan` tokens and read the text via `tokenText` until the token
returned is an EOF marker.
*/
class Tokeniser
{
  enum Opts
  {
    None = 0x0,
    StringAware = 0x1,
    AllowLinebreaks = 0x2 //FIXME: implement AllowLinebreaks
  }

  //TODO: consider implementing the following?
  // Ident,
  // Int,
  // Float,
  // Char,
  // Comment,
  enum Token
  {
    EOF,
    String,
    QuotedString,
  }

  this(string input, Opts opts = Opts.None)
  {
    this.input = input;
    this.opts = opts;
  }

  //TODO: also implement readQuotedString(token) helper
  //TODO: bail if we're at EOF
  string tokenText() => input[readIndex .. nextReadIndex];

  /**
  scan is the only way to move the start/end markers (readIndex, nextReadIndex) across the input buffer.
  if we are StringAware, the start/end markers will point to consuming the inside string and skip over the quotes.
  once a token has been scanned, it may be consumed via `tokenText`

  Returns: the kind of token (`Token`) contained by the start/end markers. an `EOF` token signals parsing should halt.
  */
  Token scan()
  {
    // sanity checks
    if (index >= input.length)
    {
      index = input.length;
      return Token.EOF;
    }
    if (input[index] == '\0')
    {
      index = readIndex = nextReadIndex;
      return Token.EOF;
    }

    Token token = Token.String;
    // in the typical case, we split by whitespace
    // ...but if we're starting with a quote, and we're StringAware then try find the closing quote
    string delimiters = " \t\n";
    const bool startsWithQuote = input[index] == '"';
    if ((opts & Opts.StringAware) && startsWithQuote)
    {
      delimiters = "\"";
    }

    size_t nextIndex = index;
    for (size_t i = index + 1; i < input.length; i++)
    {
      if (delimiters.indexOf(input[i]) != -1)
      {
        // this is a delimiter, stop reading
        nextIndex = i++;
        break;
      }
    }
    if (nextIndex == index)
    {
      // no delimiters found, just read from here til the end of the string
      readIndex = index;
      nextReadIndex = index = input.length;
      return token;
    }

    const bool parsingQuotedString = (opts & Opts.StringAware) && startsWithQuote && input[nextIndex] == '"';

    if (parsingQuotedString)
    {
      token = Token.QuotedString;
      // skip the first '"'
      index += 1;
    }

    // actually set the read markers
    assert(index >= 0 && index < input.length,
      "start index OOB: %d >= %d or < 0".format(index, input.length));
    assert(
      nextIndex > 0 && nextIndex < input.length,
      "next index OOB: %d >= %d or <= 0".format(nextIndex, input.length));
    readIndex = index;
    nextReadIndex = nextIndex;

    if (readIndex == nextReadIndex || index >= input.length || input[index .. index + 1] == "\0")
    {
      return Token.EOF;
    }

    if (parsingQuotedString)
    {
      // skip over the trailing '"' for the next scan
      nextIndex += 1;
    }

    // start reading from the next character
    index = nextIndex + 1;
    return token;
  }

private:
  string input;
  Opts opts;
  //TOOD: see if we can get rid of `index`
  size_t index, readIndex, nextReadIndex;
}
