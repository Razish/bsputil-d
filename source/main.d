module main;

import parse.entities;
import parse.header;
import parse.shaders;
static import stdio = std.stdio;
import std.string : format;

version (Windows)
{
  pragma(msg, "I can't believe you've done this 🥺");
}

void main(string[] args)
{
  // parse commandline arguments so we know which file to read
  if (args.length <= 2)
  {
    throw new Error("usage: %s <filename> <lump name>".format(args[0]));
  }
  const string inputFilename = args[1];
  const string desiredLump = args[2];

  // read the file from disk
  auto f = stdio.File(inputFilename, "rb");

  // parse the header
  BspHeader header = parse.header.read(f);

  // parse the lump(s) and serialise as JSONL
  // what does memory allocation look like? should i...not care until i have to?
  switch (desiredLump)
  {
  case "entities", "ents":
    {
      auto entities = parse.entities.read(f, &header);
      stdio.writeln(entities.serialise);
    }
    break;
  case "shaders":
    {
      auto shaders = parse.shaders.read(f, &header);
      stdio.writeln(shaders.serialise);
    }
    break;
  default:
    class UnsupportedLumpException : Exception
    {
      this(string msg, string file = __FILE__, size_t line = __LINE__)
      {
        super(msg, file, line);
      }
    }

    throw new UnsupportedLumpException("unsupported lump '%s'".format(desiredLump));
    break;
  }
  f.close;
}
