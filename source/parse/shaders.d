module parse.shaders;

import parse.header;
import std.algorithm : map;
static import json = std.json;
static import stdio = std.stdio;
import std.string : format, fromStringz, join;

/**
maximum length of a path for the quake virtual filesystem (VFS)
*/
const MAX_QPATH = 64u;

/**
general purpose type for bitflags
*/
alias Flag = uint;

/**
binary representation of a shader on disk, to be transformed to the D-friendly `Shader`
*/
struct RawShader
{
  char[MAX_QPATH] path;
  Flag surfaceFlags;
  Flag contentFlags;
}

/**
friendly representation of a shader from the BSP
*/
struct Shader
{
  string path;
  Flag surfaceFlags;
  Flag contentFlags;

  json.JSONValue toJson()
  {
    return json.JSONValue([
      "shader": json.JSONValue(path.dup),
      "surfaceFlags": json.JSONValue(surfaceFlags),
      "contentFlags": json.JSONValue(contentFlags),
    ]);
  }
}

string serialise(Shader[] shaders) => shaders
  .map!(s => s.toJson.toString(json.JSONOptions.doNotEscapeSlashes))
  .join("\n");

Shader[] read(stdio.File f, BspHeader* header)
{
  Lump* lump = &header.lumps[LumpId.Shaders];
  const uint numShaders = lump.length / RawShader.sizeof;

  // FIXME: can we alias the raw file contents as RawShaders, and transform them into Shaders instead of double copying?
  RawShader[] rawShaders = new RawShader[numShaders];
  f.seek(lump.offset);
  f.rawRead(rawShaders);

  Shader[] shaders = new Shader[numShaders];
  foreach (i; 0 .. numShaders)
  {
    shaders[i].path = rawShaders[i].path.idup.fromStringz;
    shaders[i].contentFlags = rawShaders[i].contentFlags;
    shaders[i].surfaceFlags = rawShaders[i].surfaceFlags;
  }
  return shaders;
}
