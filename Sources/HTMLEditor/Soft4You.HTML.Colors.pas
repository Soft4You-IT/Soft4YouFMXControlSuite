unit Soft4You.HTML.Colors;

{ *****************************************************************************
  Soft4You FMX Control Suite - FireMonkey (FMX) controls for Delphi
  TS4YHTMLEditor - WYSIWYG HTML editor
  Original author: Carlo Marona (Soft4You) - 2026

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  ***************************************************************************** }

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  System.UITypes;

type
  /// <summary>A W3C color name with its color.</summary>
  TS4YHTMLNamedColor = record
    /// <summary>Lowercase W3C name of the color.</summary>
    Name: string;
    /// <summary>Color value.</summary>
    Color: TAlphaColor;
  end;

/// <summary>
/// Parses a CSS color value.
/// </summary>
/// <param name="AValue">Value in the form #RRGGBB, #RGB, rgb(r,g,b) or a W3C color name.</param>
/// <param name="AColor">Parsed color, opaque; claNull when the value cannot be parsed.</param>
/// <returns>True when the value was parsed.</returns>
function HTMLColorToAlphaColor(const AValue: string; out AColor: TAlphaColor): Boolean;

/// <summary>
/// Looks up a W3C color name.
/// </summary>
/// <param name="AName">Color name; the case is ignored.</param>
/// <param name="AColor">Color of the name, when it is found.</param>
/// <returns>True when the name is a recognised W3C color name.</returns>
function HTMLColorNameToAlphaColor(const AName: string; out AColor: TAlphaColor): Boolean;

/// <summary>
/// Returns the table of the W3C named colors.
/// </summary>
/// <returns>The 148 colors, sorted alphabetically by lowercase name.</returns>
function HTMLNamedColors: TArray<TS4YHTMLNamedColor>;

/// <summary>
/// Writes a color as #RRGGBB.
/// </summary>
/// <param name="AColor">Color to write; its alpha channel is ignored.</param>
/// <returns>The color in the form #RRGGBB.</returns>
function AlphaColorToHTMLHex(AColor: TAlphaColor): string;

/// <summary>
/// Writes a color as its W3C name.
/// </summary>
/// <param name="AColor">Color to write.</param>
/// <param name="FallbackToHex">True to return #RRGGBB when the color has no name.</param>
/// <returns>The W3C name of the color (for example cornflowerblue); otherwise #RRGGBB when FallbackToHex is True, or an empty string when it is False.</returns>
function AlphaColorToHTMLName(AColor: TAlphaColor; FallbackToHex: Boolean = True): string;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults;

var
  GColorLookup: TDictionary<string, TAlphaColor>;
  GColorReverseLookup: TDictionary<TAlphaColor, string>;
  GNamedColors: TArray<TS4YHTMLNamedColor>;

function HTMLColorToAlphaColor(const AValue: string; out AColor: TAlphaColor): Boolean;
var
  LValue: string;
  LHex: string;
  LParts: TArray<string>;
  LRed, LGreen, LBlue: Integer;
begin
  AColor := TAlphaColor($00000000);
  Result := False;
  LValue := AValue.Trim.ToLower;

  if LValue = '' then
    Exit;

  if LValue[Low(LValue)] = '#' then
  begin
    LHex := LValue.Substring(1);

    if Length(LHex) = 3 then
      LHex := LHex[Low(LHex)] + LHex[Low(LHex)] +
              LHex[Low(LHex) + 1] + LHex[Low(LHex) + 1] +
              LHex[Low(LHex) + 2] + LHex[Low(LHex) + 2];

    if Length(LHex) = 6 then
      try
        LRed   := StrToInt('$' + LHex.Substring(0, 2));
        LGreen := StrToInt('$' + LHex.Substring(2, 2));
        LBlue  := StrToInt('$' + LHex.Substring(4, 2));
        AColor := TAlphaColor(($FF shl 24) or (LRed shl 16) or (LGreen shl 8) or LBlue);
        Result := True;
      except
      end;
  end
  else if LValue.StartsWith('rgb(') and LValue.EndsWith(')') then
  begin
    LParts := LValue.Substring(4, LValue.Length - 5).Split([',']);

    if Length(LParts) >= 3 then
      try
        LRed   := LParts[0].Trim.ToInteger;
        LGreen := LParts[1].Trim.ToInteger;
        LBlue  := LParts[2].Trim.ToInteger;
        AColor := TAlphaColor(($FF shl 24) or (LRed shl 16) or (LGreen shl 8) or LBlue);
        Result := True;
      except
      end;
  end
  else
    Result := GColorLookup.TryGetValue(LValue, AColor);
end;

function HTMLColorNameToAlphaColor(const AName: string; out AColor: TAlphaColor): Boolean;
begin
  Result := GColorLookup.TryGetValue(AName.ToLower, AColor);
end;

function HTMLNamedColors: TArray<TS4YHTMLNamedColor>;
begin
  Result := GNamedColors;
end;

function AlphaColorToHTMLHex(AColor: TAlphaColor): string;
begin
  Result := '#' +
    IntToHex((AColor shr 16) and $FF, 2) +
    IntToHex((AColor shr 8)  and $FF, 2) +
    IntToHex(AColor and $FF, 2);
end;

function AlphaColorToHTMLName(AColor: TAlphaColor; FallbackToHex: Boolean = True): string;
begin
  if not GColorReverseLookup.TryGetValue(AColor, Result) then
  begin
    if FallbackToHex then
      Result := AlphaColorToHTMLHex(AColor)
    else
      Result := '';
  end;
end;

procedure BuildColorTable;
var
  LIndex: Integer;
  LPair: TPair<string, TAlphaColor>;
begin
  GColorLookup := TDictionary<string, TAlphaColor>.Create(160);

  GColorLookup.Add('aliceblue',            TAlphaColor($FFF0F8FF));
  GColorLookup.Add('antiquewhite',         TAlphaColor($FFFAEBD7));
  GColorLookup.Add('aqua',                 TAlphaColor($FF00FFFF));
  GColorLookup.Add('aquamarine',           TAlphaColor($FF7FFFD4));
  GColorLookup.Add('azure',                TAlphaColor($FFF0FFFF));
  GColorLookup.Add('beige',                TAlphaColor($FFF5F5DC));
  GColorLookup.Add('bisque',               TAlphaColor($FFFFE4C4));
  GColorLookup.Add('black',                TAlphaColor($FF000000));
  GColorLookup.Add('blanchedalmond',       TAlphaColor($FFFFEBCD));
  GColorLookup.Add('blue',                 TAlphaColor($FF0000FF));
  GColorLookup.Add('blueviolet',           TAlphaColor($FF8A2BE2));
  GColorLookup.Add('brown',                TAlphaColor($FFA52A2A));
  GColorLookup.Add('burlywood',            TAlphaColor($FFDEB887));
  GColorLookup.Add('cadetblue',            TAlphaColor($FF5F9EA0));
  GColorLookup.Add('chartreuse',           TAlphaColor($FF7FFF00));
  GColorLookup.Add('chocolate',            TAlphaColor($FFD2691E));
  GColorLookup.Add('coral',                TAlphaColor($FFFF7F50));
  GColorLookup.Add('cornflowerblue',       TAlphaColor($FF6495ED));
  GColorLookup.Add('cornsilk',             TAlphaColor($FFFFF8DC));
  GColorLookup.Add('crimson',              TAlphaColor($FFDC143C));
  GColorLookup.Add('cyan',                 TAlphaColor($FF00FFFF));
  GColorLookup.Add('darkblue',             TAlphaColor($FF00008B));
  GColorLookup.Add('darkcyan',             TAlphaColor($FF008B8B));
  GColorLookup.Add('darkgoldenrod',        TAlphaColor($FFB8860B));
  GColorLookup.Add('darkgray',             TAlphaColor($FFA9A9A9));
  GColorLookup.Add('darkgreen',            TAlphaColor($FF006400));
  GColorLookup.Add('darkgrey',             TAlphaColor($FFA9A9A9));
  GColorLookup.Add('darkkhaki',            TAlphaColor($FFBDB76B));
  GColorLookup.Add('darkmagenta',          TAlphaColor($FF8B008B));
  GColorLookup.Add('darkolivegreen',       TAlphaColor($FF556B2F));
  GColorLookup.Add('darkorange',           TAlphaColor($FFFF8C00));
  GColorLookup.Add('darkorchid',           TAlphaColor($FF9932CC));
  GColorLookup.Add('darkred',              TAlphaColor($FF8B0000));
  GColorLookup.Add('darksalmon',           TAlphaColor($FFE9967A));
  GColorLookup.Add('darkseagreen',         TAlphaColor($FF8FBC8F));
  GColorLookup.Add('darkslateblue',        TAlphaColor($FF483D8B));
  GColorLookup.Add('darkslategray',        TAlphaColor($FF2F4F4F));
  GColorLookup.Add('darkslategrey',        TAlphaColor($FF2F4F4F));
  GColorLookup.Add('darkturquoise',        TAlphaColor($FF00CED1));
  GColorLookup.Add('darkviolet',           TAlphaColor($FF9400D3));
  GColorLookup.Add('deeppink',             TAlphaColor($FFFF1493));
  GColorLookup.Add('deepskyblue',          TAlphaColor($FF00BFFF));
  GColorLookup.Add('dimgray',              TAlphaColor($FF696969));
  GColorLookup.Add('dimgrey',              TAlphaColor($FF696969));
  GColorLookup.Add('dodgerblue',           TAlphaColor($FF1E90FF));
  GColorLookup.Add('firebrick',            TAlphaColor($FFB22222));
  GColorLookup.Add('floralwhite',          TAlphaColor($FFFFFAF0));
  GColorLookup.Add('forestgreen',          TAlphaColor($FF228B22));
  GColorLookup.Add('fuchsia',              TAlphaColor($FFFF00FF));
  GColorLookup.Add('gainsboro',            TAlphaColor($FFDCDCDC));
  GColorLookup.Add('ghostwhite',           TAlphaColor($FFF8F8FF));
  GColorLookup.Add('gold',                 TAlphaColor($FFFFD700));
  GColorLookup.Add('goldenrod',            TAlphaColor($FFDAA520));
  GColorLookup.Add('gray',                 TAlphaColor($FF808080));
  GColorLookup.Add('green',                TAlphaColor($FF008000));
  GColorLookup.Add('greenyellow',          TAlphaColor($FFADFF2F));
  GColorLookup.Add('grey',                 TAlphaColor($FF808080));
  GColorLookup.Add('honeydew',             TAlphaColor($FFF0FFF0));
  GColorLookup.Add('hotpink',              TAlphaColor($FFFF69B4));
  GColorLookup.Add('indianred',            TAlphaColor($FFCD5C5C));
  GColorLookup.Add('indigo',               TAlphaColor($FF4B0082));
  GColorLookup.Add('ivory',                TAlphaColor($FFFFFFF0));
  GColorLookup.Add('khaki',                TAlphaColor($FFF0E68C));
  GColorLookup.Add('lavender',             TAlphaColor($FFE6E6FA));
  GColorLookup.Add('lavenderblush',        TAlphaColor($FFFFF0F5));
  GColorLookup.Add('lawngreen',            TAlphaColor($FF7CFC00));
  GColorLookup.Add('lemonchiffon',         TAlphaColor($FFFFFACD));
  GColorLookup.Add('lightblue',            TAlphaColor($FFADD8E6));
  GColorLookup.Add('lightcoral',           TAlphaColor($FFF08080));
  GColorLookup.Add('lightcyan',            TAlphaColor($FFE0FFFF));
  GColorLookup.Add('lightgoldenrodyellow', TAlphaColor($FFFAFAD2));
  GColorLookup.Add('lightgray',            TAlphaColor($FFD3D3D3));
  GColorLookup.Add('lightgreen',           TAlphaColor($FF90EE90));
  GColorLookup.Add('lightgrey',            TAlphaColor($FFD3D3D3));
  GColorLookup.Add('lightpink',            TAlphaColor($FFFFB6C1));
  GColorLookup.Add('lightsalmon',          TAlphaColor($FFFFA07A));
  GColorLookup.Add('lightseagreen',        TAlphaColor($FF20B2AA));
  GColorLookup.Add('lightskyblue',         TAlphaColor($FF87CEFA));
  GColorLookup.Add('lightslategray',       TAlphaColor($FF778899));
  GColorLookup.Add('lightslategrey',       TAlphaColor($FF778899));
  GColorLookup.Add('lightsteelblue',       TAlphaColor($FFB0C4DE));
  GColorLookup.Add('lightyellow',          TAlphaColor($FFFFFFE0));
  GColorLookup.Add('lime',                 TAlphaColor($FF00FF00));
  GColorLookup.Add('limegreen',            TAlphaColor($FF32CD32));
  GColorLookup.Add('linen',                TAlphaColor($FFFAF0E6));
  GColorLookup.Add('magenta',              TAlphaColor($FFFF00FF));
  GColorLookup.Add('maroon',               TAlphaColor($FF800000));
  GColorLookup.Add('mediumaquamarine',     TAlphaColor($FF66CDAA));
  GColorLookup.Add('mediumblue',           TAlphaColor($FF0000CD));
  GColorLookup.Add('mediumorchid',         TAlphaColor($FFBA55D3));
  GColorLookup.Add('mediumpurple',         TAlphaColor($FF9370DB));
  GColorLookup.Add('mediumseagreen',       TAlphaColor($FF3CB371));
  GColorLookup.Add('mediumslateblue',      TAlphaColor($FF7B68EE));
  GColorLookup.Add('mediumspringgreen',    TAlphaColor($FF00FA9A));
  GColorLookup.Add('mediumturquoise',      TAlphaColor($FF48D1CC));
  GColorLookup.Add('mediumvioletred',      TAlphaColor($FFC71585));
  GColorLookup.Add('midnightblue',         TAlphaColor($FF191970));
  GColorLookup.Add('mintcream',            TAlphaColor($FFF5FFFA));
  GColorLookup.Add('mistyrose',            TAlphaColor($FFFFE4E1));
  GColorLookup.Add('moccasin',             TAlphaColor($FFFFE4B5));
  GColorLookup.Add('navajowhite',          TAlphaColor($FFFFDEAD));
  GColorLookup.Add('navy',                 TAlphaColor($FF000080));
  GColorLookup.Add('oldlace',              TAlphaColor($FFFDF5E6));
  GColorLookup.Add('olive',                TAlphaColor($FF808000));
  GColorLookup.Add('olivedrab',            TAlphaColor($FF6B8E23));
  GColorLookup.Add('orange',               TAlphaColor($FFFFA500));
  GColorLookup.Add('orangered',            TAlphaColor($FFFF4500));
  GColorLookup.Add('orchid',               TAlphaColor($FFDA70D6));
  GColorLookup.Add('palegoldenrod',        TAlphaColor($FFEEE8AA));
  GColorLookup.Add('palegreen',            TAlphaColor($FF98FB98));
  GColorLookup.Add('paleturquoise',        TAlphaColor($FFAFEEEE));
  GColorLookup.Add('palevioletred',        TAlphaColor($FFDB7093));
  GColorLookup.Add('papayawhip',           TAlphaColor($FFFFEFD5));
  GColorLookup.Add('peachpuff',            TAlphaColor($FFFFDAB9));
  GColorLookup.Add('peru',                 TAlphaColor($FFCD853F));
  GColorLookup.Add('pink',                 TAlphaColor($FFFFC0CB));
  GColorLookup.Add('plum',                 TAlphaColor($FFDDA0DD));
  GColorLookup.Add('powderblue',           TAlphaColor($FFB0E0E6));
  GColorLookup.Add('purple',               TAlphaColor($FF800080));
  GColorLookup.Add('rebeccapurple',        TAlphaColor($FF663399));
  GColorLookup.Add('red',                  TAlphaColor($FFFF0000));
  GColorLookup.Add('rosybrown',            TAlphaColor($FFBC8F8F));
  GColorLookup.Add('royalblue',            TAlphaColor($FF4169E1));
  GColorLookup.Add('saddlebrown',          TAlphaColor($FF8B4513));
  GColorLookup.Add('salmon',               TAlphaColor($FFFA8072));
  GColorLookup.Add('sandybrown',           TAlphaColor($FFF4A460));
  GColorLookup.Add('seagreen',             TAlphaColor($FF2E8B57));
  GColorLookup.Add('seashell',             TAlphaColor($FFFFF5EE));
  GColorLookup.Add('sienna',               TAlphaColor($FFA0522D));
  GColorLookup.Add('silver',               TAlphaColor($FFC0C0C0));
  GColorLookup.Add('skyblue',              TAlphaColor($FF87CEEB));
  GColorLookup.Add('slateblue',            TAlphaColor($FF6A5ACD));
  GColorLookup.Add('slategray',            TAlphaColor($FF708090));
  GColorLookup.Add('slategrey',            TAlphaColor($FF708090));
  GColorLookup.Add('snow',                 TAlphaColor($FFFFFAFA));
  GColorLookup.Add('springgreen',          TAlphaColor($FF00FF7F));
  GColorLookup.Add('steelblue',            TAlphaColor($FF4682B4));
  GColorLookup.Add('tan',                  TAlphaColor($FFD2B48C));
  GColorLookup.Add('teal',                 TAlphaColor($FF008080));
  GColorLookup.Add('thistle',              TAlphaColor($FFD8BFD8));
  GColorLookup.Add('tomato',               TAlphaColor($FFFF6347));
  GColorLookup.Add('transparent',          TAlphaColor($00000000));
  GColorLookup.Add('turquoise',            TAlphaColor($FF40E0D0));
  GColorLookup.Add('violet',               TAlphaColor($FFEE82EE));
  GColorLookup.Add('wheat',                TAlphaColor($FFF5DEB3));
  GColorLookup.Add('white',                TAlphaColor($FFFFFFFF));
  GColorLookup.Add('whitesmoke',           TAlphaColor($FFF5F5F5));
  GColorLookup.Add('yellow',               TAlphaColor($FFFFFF00));
  GColorLookup.Add('yellowgreen',          TAlphaColor($FF9ACD32));

  SetLength(GNamedColors, GColorLookup.Count);
  LIndex := 0;

  for LPair in GColorLookup do
  begin
    GNamedColors[LIndex].Name := LPair.Key;
    GNamedColors[LIndex].Color := LPair.Value;
    Inc(LIndex);
  end;

  TArray.Sort<TS4YHTMLNamedColor>(GNamedColors,
    TComparer<TS4YHTMLNamedColor>.Construct(
      function(const ALeft, ARight: TS4YHTMLNamedColor): Integer
      begin
        Result := CompareStr(ALeft.Name, ARight.Name);
      end));

  // Build reverse lookup (color -> canonical name).
  // Aliases sharing the same value are resolved to a single canonical name.
  GColorReverseLookup := TDictionary<TAlphaColor, string>.Create(160);

  for LPair in GColorLookup do
    GColorReverseLookup.AddOrSetValue(LPair.Value, LPair.Key);

  // Canonical names for aliased colors (grey -> gray, etc.)
  GColorReverseLookup.AddOrSetValue(TAlphaColor($FF808080), 'gray');
  GColorReverseLookup.AddOrSetValue(TAlphaColor($FF00FFFF), 'aqua');
  GColorReverseLookup.AddOrSetValue(TAlphaColor($FFFF00FF), 'fuchsia');
  GColorReverseLookup.AddOrSetValue(TAlphaColor($FFA9A9A9), 'darkgray');
  GColorReverseLookup.AddOrSetValue(TAlphaColor($FF2F4F4F), 'darkslategray');
  GColorReverseLookup.AddOrSetValue(TAlphaColor($FF696969), 'dimgray');
  GColorReverseLookup.AddOrSetValue(TAlphaColor($FFD3D3D3), 'lightgray');
  GColorReverseLookup.AddOrSetValue(TAlphaColor($FF778899), 'lightslategray');
  GColorReverseLookup.AddOrSetValue(TAlphaColor($FF708090), 'slategray');
end;

initialization
  BuildColorTable;

finalization
  GColorLookup.Free;
  GColorReverseLookup.Free;

end.
