unit Sky;

interface
  uses
    Windows, OpenGL, Noise, Utils;

  type
    TSky = class
      private
        FTexWidth,
        FTexHeight: Integer;
        FTex: GLUInt;
        FInitialized: Boolean;

        FSeed: Integer;

        FW: Real;
        FH: Real;

        FN: Integer;
        FD: Integer;

      public
        constructor Create;
        destructor Destroy; override;

        procedure Initialize;
        procedure Finalize;

        procedure Draw;

        property TexWidth: Integer read FTexWidth write FTexWidth;
        property TexHeight: Integer read FTexHeight write FTexHeight;

        property Seed: Integer read FSeed write FSeed;

        property W: Real read FW write FW;
        property H: Real read FH write FH;

        property N: Integer read FN write FN;
        property D: Integer read FD write FD;

      end;

  procedure glBindTexture (target: glEnum; texture: glUint); stdcall; external opengl32;
  procedure glGenTextures (n: glSizei; var textures: glUint); stdcall; external opengl32;
  procedure glDeleteTextures (n: glSizei; var textures: glUint); stdcall; external opengl32;

implementation

constructor TSky.Create;
begin
  FInitialized := FALSE;
end;

destructor TSky.Destroy;
begin
  if FInitialized then
    Finalize;

  inherited Destroy;
end;

procedure TSky.Initialize;
  var
    bap: ByteArrayPtr;
    P, TotalSize: Integer;
    i, j: Integer;
    X: Real;
    R, G, B: Integer;
begin
  TotalSize := FTexWidth * FTexHeight * 3;
  GetMem (bap, TotalSize);

  RandSeed := FSeed;
  InitNoise;

  for i := 0 to FTexWidth - 1 do
    for j := 0 to FTexHeight - 1 do
    begin
      P := (i + j * FTexWidth) * 3;
      NoiseSizeX := FTexWidth div 32;
      NoiseSizeY := FTexHeight div 32;
      X := Noise2 (i / 32, j / 32) / 2;
      NoiseSizeX := FTexWidth div 4;
      NoiseSizeY := FTexHeight div 4;
      X := X + Noise2 (i / 4, j / 4) / 2;

      R :=  50 + Round ( 50 * X);
      G :=  80 + Round (100 * X);
      B := 100 + Round (200 * X);

      bap^[P + 0] := Byte (LimitRGB (R));
      bap^[P + 1] := Byte (LimitRGB (G));
      bap^[P + 2] := Byte (LimitRGB (B));
    end;

  glEnable (GL_TEXTURE_2D);
  glGenTextures (1, FTex);
  glBindTexture (GL_TEXTURE_2D, FTex);
 // glTexEnvi (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
  glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexImage2D (GL_TEXTURE_2D, 0, 4, FTexWidth, FTexHeight, 0, GL_RGB,
                GL_UNSIGNED_BYTE, @bap^);

  FreeMem (bap, TotalSize);
  FInitialized := TRUE;
end;

procedure TSky.Finalize;
begin
  if FInitialized then
  begin
    glDeleteTextures (1, FTex);
    FInitialized := FALSE;
  end;
end;

procedure TSky.Draw;
  var
    i, j: Integer;
    ZF: Real;
begin
  if not FInitialized then
    Exit;

  glEnable (GL_TEXTURE_2D);
  glBindTexture (GL_TEXTURE_2D, FTex);

  {
    glEnable (GL_BLEND);
    glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  }

 // glDisable (GL_CULL_FACE);
  glDisable (GL_DEPTH_TEST);

  //  glEnable (GL_BLEND);
  //  glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


  glBegin (GL_QUADS);
   // glColor3f (0.6, 0.8, 0.9);
    glTexCoord2f (1.0, 0.0);  glVertex3f (- FW, + FH, -(D - N));
    glTexCoord2f (0.0, 0.0);  glVertex3f (+ FW, + FH, -(D - N));
   // glColor3f (1.0, 1.0, 1.0);
    glTexCoord2f (0.0, 1.0);  glVertex3f (+ FW, - 0 , -(D + D/N));
    glTexCoord2f (1.0, 1.0);  glVertex3f (- FW, - 0 , -(D + D/N));

  glEnd;

end;

end.
