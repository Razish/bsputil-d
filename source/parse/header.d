module parse.header;

static import bitmanip = std.bitmanip;
static import stdio = std.stdio;
import std.string : format;

const uint RBSP_IDENT = (('R' << 24) + ('B' << 16) + ('S' << 8) + 'P');
const uint RBSP_VERSION = 1;

class UnsupportedBspException : Exception
{
  this(string msg, string file = __FILE__, size_t line = __LINE__)
  {
    super(msg, file, line);
  }
}

enum LumpId
{
  Entities = 0u,
  Shaders,
  Planes,
  Nodes,
  Leafs,
  LeafSurfaces,
  LeafBrushes,
  Models,
  Brushes,
  BrushSides,
  DrawVerts,
  DrawIndexes,
  Fogs,
  Surfaces,
  Lightmaps,
  LightGrid,
  Visibility,
  LightArray,
  NumLumps,
}

struct Lump
{
  uint offset;
  uint length;
}

struct BspHeader
{
  uint ident;
  uint _version;
  Lump[LumpId.NumLumps] lumps;
}

/**
Params:
  f = an open handle to a BSP file

Throws: UnsupportedBspException if the ident or version are not expected
*/
BspHeader read(stdio.File f)
{
  //FIXME: why do we need a 1-sized array just to rawRead...
  BspHeader[1] bspHeader;
  f.rawRead(bspHeader);

  bspHeader[0].ident = bitmanip.bigEndianToNative!(uint, uint.sizeof)(*cast(ubyte[uint.sizeof]*)&bspHeader[0].ident);

  if (bspHeader[0].ident != RBSP_IDENT)
  {
    throw new UnsupportedBspException(
      "unexpected BSP identifier %u, expected %u".format(bspHeader[0].ident, RBSP_IDENT)
    );
  }
  if (bspHeader[0]._version != RBSP_VERSION)
  {
    throw new UnsupportedBspException(
      "unexpected BSP version %u, expected %u".format(bspHeader[0]._version, RBSP_VERSION)
    );
  }
  return bspHeader[0];
}
