unit Ground;

interface

  uses
    Windows, OpenGL, Noise, Utils;

  const
    FRAMES = 32;

  type
    TGround = class
      private
        FTexWidth,
        FTexHeight: Integer;
        FTex: array[0..FRAMES - 1] of GLUInt;
        FInitialized: Boolean;

        FSeed: Integer;

        FX: Real;
        FY: Real;
        FZ: Real;
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

        property X: Real read FX write FX;
        property Y: Real read FY write FY;
        property Z: Real read FZ write FZ;
        property W: Real read FW write FW;
        property H: Real read FH write FH;

        property N: Integer read FN write FN;
        property D: Integer read FD write FD;

      end;



  procedure glBindTexture (target: glEnum; texture: glUint); stdcall; external opengl32;
  procedure glGenTextures (n: glSizei; var textures: glUint); stdcall; external opengl32;
  procedure glDeleteTextures (n: glSizei; var textures: glUint); stdcall; external opengl32;

implementation

constructor TGround.Create;
begin

  FInitialized := FALSE;
end;

destructor TGround.Destroy;
begin
  if FInitialized then
    Finalize;

  inherited Destroy;
end;


procedure TGround.Initialize;
  var
    bap: ByteArrayPtr;
    P, TotalSize: Integer;
    i, j, k: Integer;
    X: Real;
    R, G, B: Integer;
begin
  TotalSize := FTexWidth * FTexHeight * 3;
  GetMem (bap, TotalSize);

  for k := 0 to FRAMES - 1 do
  begin
    RandSeed := FSeed;
    InitNoise;

    NoiseSizeZ := 2;

    for i := 0 to FTexWidth - 1 do
      for j := 0 to FTexHeight - 1 do
      begin
        P := (i + j * FTexWidth) * 3;
        NoiseSizeX := FTexWidth div 32;
        NoiseSizeY := FTexHeight div 32;
        X := Noise3 (i / 32, j / 32, k * NoiseSizeZ / FRAMES) / 1;
        NoiseSizeX := FTexWidth div 4;
        NoiseSizeY := FTexHeight div 4;
        X := X + Noise3 (i / 4, j / 4, k * NoiseSizeZ / FRAMES) / 2;

        R := 64 + Round (32 * X);
        G := 128 + Round (128 * X);
        B := 128 - Round (32 * X);


        R :=  40 + Round (22 * X);
        G :=  95 + Round (45 * X);
        B := 125 + Round (42 * X);


        bap^[P + 0] := Byte (LimitRGB (R));
        bap^[P + 1] := Byte (LimitRGB (G));
        bap^[P + 2] := Byte (LimitRGB (B));
      end;

    glEnable (GL_TEXTURE_2D);
    glGenTextures (1, FTex[k]);
    glBindTexture (GL_TEXTURE_2D, FTex[k]);
   // glTexEnvi (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D (GL_TEXTURE_2D, 0, 4, FTexWidth, FTexHeight, 0, GL_RGB,
                  GL_UNSIGNED_BYTE, @bap^);
  end;

  FreeMem (bap, TotalSize);
  FInitialized := TRUE;
end;

procedure TGround.Finalize;
  var
    k: Integer;
begin
  if FInitialized then
  begin
    for k := FRAMES - 1 downto 0 do
      glDeleteTextures (1, FTex[k]);
    FInitialized := FALSE;
  end;
end;


procedure TGround.Draw;
  var
    i, j: Integer;
    ZF, ZD: Real;
  const
    CurFrame: Integer = 0;
begin
  if not FInitialized then
    Exit;

  glEnable (GL_TEXTURE_2D);
  glBindTexture (GL_TEXTURE_2D, FTex[(CurFrame div (100 div FRAMES)) mod FRAMES]);
  Inc (CurFrame);

  {
    glEnable (GL_BLEND);
    glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  }

 // glDisable (GL_CULL_FACE);
  glDisable (GL_DEPTH_TEST);

  //  glEnable (GL_BLEND);
  //  glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


  ZF := (FZ / FH - Int (FZ / FH)) * FH;

  for j := D - 1 downto 0 do
    for i := -N to N do
    begin
      if j = D - 1 then
        ZD := 0
      else
        ZD := ZF;
      glBegin (GL_QUADS);
       //   glColor3f (0.8, 0.8, 0.8);
        glTexCoord2f (1.0, 0.0);  glVertex3f (X + i * FW + FW / 2, FY+1, ZD + -j * FH);
        glTexCoord2f (0.0, 0.0);  glVertex3f (X + i * FW - FW / 2, FY+1, ZD + -j * FH);
        glTexCoord2f (0.0, 1.0);  glVertex3f (X + i * FW - FW / 2, FY+1, ZF + -(j - 1) * FH);
        glTexCoord2f (1.0, 1.0);  glVertex3f (X + i * FW + FW / 2, FY+1, ZF + -(j - 1) * FH);
      glEnd;
    end;

end;

end.
