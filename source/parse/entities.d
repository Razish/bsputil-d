module parse.entities;

import parse.header;
import std.algorithm : each, map;
static import json = std.json;
static import stdio = std.stdio;
import std.string : format, join;
import util.tokeniser;

/**
an entity consists of k,v string pairs
*/
alias Entity = string[string];

/**
binary representation of entity data on disk, to be tokenised and parsed into a list of entities
*/
alias EntityString = char[];

class UnexpectedTokenException : Exception
{
  this(string msg, string file = __FILE__, size_t line = __LINE__)
  {
    super(msg, file, line);
  }
}

class ParseException : Exception
{
  this(string msg, string file = __FILE__, size_t line = __LINE__)
  {
    super(msg, file, line);
  }
}

/**
Throws: UnexpectedTokenException if structural markers were expected but not found
Throws: ParseException for generic parser errors
*/
static Entity[] parseEntityString(EntityString bytes)
{
  Entity[] entities;

  /*
  format:
    {
      "key1" "value1"
      "key2" "value two"
    }
    {
      "key1" "value one"
      "key2" "value 2"
    }
  */

  Tokeniser tk = new Tokeniser(bytes.idup, Tokeniser.Opts.StringAware);
  for (auto token = tk.scan; token != Tokeniser.Token.EOF; token = tk.scan)
  {
    string text = tk.tokenText;
    if (text != "{")
    {
      throw new UnexpectedTokenException("\"%s\" reading entity, expected \"{\"".format(text));
    }

    auto entity = new Entity;
    for (token = tk.scan; token != Tokeniser.Token.EOF; token = tk.scan)
    {
      text = tk.tokenText;
      // we're parsing k,v pairs of entity properties until the next "}"
      if (text == "}")
      {
        entities ~= entity;
        break;
      }

      const string key = tk.tokenText;
      if (!key)
      {
        throw new ParseException("couldn't parse entity key");
      }

      token = tk.scan;
      const string value = tk.tokenText;
      if (!value)
      {
        throw new ParseException("couldn't parse entity value");
      }

      entity[key] = value;
    }
  }

  return entities;
}

unittest
{
  auto ents = parseEntityString(cast(char[]) `{
"one" "value1"
"two" "value two"
}
{
"1" "value1"
"2" "value two"
}
{
"won" "value one"
"too" "value 2"
}`);
  assert(ents.length == 3, "there should be three entities");
  assert(ents.each!(e => e.keys.length == 2), "each entity should have 2 keys");

  ents = parseEntityString(cast(char[]) ``);
  assert(ents.length == 0, "there should be no entities");
}

string serialise(Entity[] entities) => entities
  .map!(e => json.JSONValue(e).toString(json.JSONOptions.doNotEscapeSlashes))
  .join("\n");

unittest
{
  struct TestCase
  {
    Entity[] entities;
    string expected;
  }

  TestCase[] testCases = [
    {entities: [], expected: ""},
    {entities: [["key": "value"]], expected: "{\"key\":\"value\"}"},
    {entities: [["key": "value"], ["key": "value"]], expected: "{\"key\":\"value\"}\n{\"key\":\"value\"}"},
  ];
  foreach (testCase; testCases)
  {
    auto serialised = serialise(testCase.entities);
    assert(serialised == testCase.expected,
      "`%s` should serialise correctly, got: `%s`, expected `%s`".format(
        testCase.entities, serialised, testCase.expected));
  }
}

Entity[] read(stdio.File f, BspHeader* header)
{
  Lump* lump = &header.lumps[LumpId.Entities];
  EntityString bytes = new char[lump.length];
  f.seek(lump.offset);
  f.rawRead(bytes);

  return bytes.parseEntityString;
}
