unit Utils;

interface

  uses
    OpenGL;

  type
    ByteArrayPtr = ^ByteArray;
    ByteArray = array[0..$7FFFFFFE] of Byte;

    WordArrayPtr = ^WordArray;
    WordArray = array[0..$3FFFFFFE] of Word;

    SmallIntArrayPtr = ^SmallIntArray;
    SmallIntArray = array[0..$3FFFFFFE] of SmallInt;

    IntArrayPtr = ^IntArray;
    IntArray = array[0..$1FFFFFFE] of Integer;

    PointerArrayPtr = ^PointerArray;
    PointerArray = array[0..$1FFFFFFE] of Pointer;

  type
    BooleanPtr = ^Boolean;
    BytePtr = ^Byte;
    WordPtr = ^Word;
    IntegerPtr = ^Integer;
    StringPtr = ^string;

  function IntToStr (Number: Integer): String;

  function Sign (X: Real): Integer;

  function LimitRGB (Value: Integer): Integer;

implementation

  function IntToStr (Number: Integer): String;
  begin
    Str (Number, Result);
  end;

  function Sign (X: Real): Integer;
  begin
    if X > 0 then
      Sign := 1
    else
      if X < 0 then
        Sign := -1
      else
        Sign := 0;
  end;

  function LimitRGB (Value: Integer): Integer;
  begin
    if Value < 0 then
      LimitRGB := 0
    else
      if Value > 255 then
        LimitRGB := 255
      else
        LimitRGB := Value;
  end;

end.
