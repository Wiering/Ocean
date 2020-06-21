unit Screen;

interface

  uses
    Windows,
    Messages,
    OpenGL,
    Utils;


  { ---------- TColor ---------- }

  type
    TColor = class
      private
        FRGBA: array[0..3] of Byte;
        function FGetRGBA (Index: Integer): Integer;
        procedure FSetRGBA (Index: Integer; Value: Integer);
        function FLimitRGB (x: Integer): Byte;
      public
        constructor Create (RGBA: Integer);
        destructor Destroy; override;
        procedure SetRGB (R, G, B: Integer);
        procedure SetRGBA (R, G, B, A: Integer);
        property R: Byte read FRGBA[0] write FRGBA[0];
        property G: Byte read FRGBA[1] write FRGBA[1];
        property B: Byte read FRGBA[2] write FRGBA[2];
        property A: Byte read FRGBA[3] write FRGBA[3];
        property RGBA: Integer index 0 read FGetRGBA write FSetRGBA;
        property RGB: Integer index 1 read FGetRGBA write FSetRGBA;
      end;


  { ---------- TGameWindow ---------- }

  const
    WINDOW_CLASS_NAME = 'GameWindow';


  type
    TWndProc = function (hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT;

  type
    TGameWindow = class
      private
        FHWnd: HWND;
        FHDC: HDC;
        FHRC: HGLRC;
        FWndProc: TWndProc;
        FInitialized: Boolean;
        FWidth: Integer;
        FHeight: Integer;
        FActualWidth: Integer;
        FActualHeight: Integer;
        FVirtualWidth: Integer;
        FVirtualHeight: Integer;
        FPixelDepth: Integer;
        FFullScreen: Boolean;
        FFSMinFreq: Integer;
        FFSDefFreq: Integer;
        FFSMaxFreq: Integer;
        FFSFreq: Integer;
        FStretch: Boolean;
        FBufferCount: Integer;
        FBackgroundColor: TColor;
        FWindowTitle: string;
        procedure FSetFullScreen (NewFullScreen: Boolean);
        procedure FSetWindowTitle (NewTitle: string);

      public
        constructor Create (WndProc: TWndProc);
        destructor Destroy; override;
        property Width: Integer read FWidth write FWidth;
        property Height: Integer read FHeight write FHeight;
        property ActualWidth: Integer read FActualWidth write FActualWidth;
        property ActualHeight: Integer read FActualHeight write FActualHeight;
        property VirtualWidth: Integer read FVirtualWidth write FVirtualWidth;
        property VirtualHeight: Integer read FVirtualHeight write FVirtualHeight;
        property PixelDepth: Integer read FPixelDepth write FPixelDepth;
        property FullScreen: Boolean read FFullScreen write FSetFullScreen stored FALSE;
        property FSMinFreq: Integer read FFSMinFreq write FFSMinFreq;
        property FSDefFreq: Integer read FFSDefFreq write FFSDefFreq;
        property FSMaxFreq: Integer read FFSMaxFreq write FFSMaxFreq;
        property FSFreq: Integer read FFSFreq write FFSFreq;
        property Stretch: Boolean read FStretch write FStretch stored FALSE;
        property BufferCount: Integer read FBufferCount stored 2;
        property BackgroundColor: TColor read FBackgroundColor write FBackgroundColor;
        property WindowTitle: string read FWindowTitle write FSetWindowTitle;
        property Handle: HWND read FHWND;
        procedure FillArea (X, Y, W, H: Integer; Color: TColor);
        procedure Draw;
        procedure Flip;
        procedure Initialize;
        procedure Finalize;

      end;

implementation

  { ---------- TColor ---------- }

  constructor TColor.Create (RGBA: Integer);
  begin
    Move (RGBA, FRGBA, SizeOf (FRGBA));
  end;

  destructor TColor.Destroy;
  begin
    inherited Destroy;
  end;

  function TColor.FGetRGBA (Index: Integer): Integer;
  begin
    Result := 0;
    Move (FRGBA, Result, SizeOf (Result) - Index);
  end;

  procedure TColor.FSetRGBA (Index: Integer; Value: Integer);
  begin
    Move (Value, FRGBA, SizeOf (FRGBA) - Index);
  end;

  function TColor.FLimitRGB (x: Integer): Byte;
  begin
    if x < 0 then
      x := 0
    else
      if x > 255 then
        x := 255;
    Result := Lo (x);
  end;

  procedure TColor.SetRGB (R, G, B: Integer);
  begin
    SetRGBA (R, G, B, 255);
  end;

  procedure TColor.SetRGBA (R, G, B, A: Integer);
  begin
    FRGBA[0] := FLimitRGB (R);
    FRGBA[1] := FLimitRGB (G);
    FRGBA[2] := FLimitRGB (B);
    FRGBA[3] := FLimitRGB (A);
  end;


  { ---------- TGameWindow ---------- }

  constructor TGameWindow.Create (WndProc: TWndProc);
  begin
    FInitialized := FALSE;
    FWndProc := WndProc;

    FBackgroundColor := TColor.Create (0);

  end;

  destructor TGameWindow.Destroy;
  begin
    if FInitialized then
      Finalize;

    FBackgroundColor.Destroy;

    inherited Destroy;
  end;

  procedure TGameWindow.Initialize;
    var
      XPos, YPos: Integer;
      wndClass: TWndClass;
      dwStyle: DWORD;
      dwExStyle: DWORD;
      dmScreenSettings: TDEVMODE;
      PixelFormat: Integer;
      hInstance: HINST;
      pfd: TPIXELFORMATDESCRIPTOR;
      FrameWidth, FrameHeight, TitleBarHeight: Integer;
      WindowW, WindowH: Integer;
      ModeOk: Boolean;
  begin
    if FInitialized then
      Exit;
    hInstance := GetModuleHandle (nil);
    ZeroMemory (@wndClass, SizeOf (wndClass));
    with wndClass do
    begin
      style         := CS_HREDRAW or CS_VREDRAW or CS_OWNDC;
      lpfnWndProc   := @FWndProc;
      hInstance     := hInstance;
      hCursor       := LoadCursor (0, IDC_ARROW);
      lpszClassName := WINDOW_CLASS_NAME;
      hIcon         := LoadIcon (hInstance, 'MAINICON');
    end;
    RegisterClass (wndClass);

    if FFullScreen then
    begin
      ZeroMemory (@dmScreenSettings, SizeOf (dmScreenSettings));
      with dmScreenSettings do
      begin
        dmSize             := SizeOf (dmScreenSettings);
        dmPelsWidth        := FActualWidth;
        dmPelsHeight       := FActualHeight;
        dmBitsPerPel       := FPixelDepth;
        dmFields           := DM_PELSWIDTH or DM_PELSHEIGHT or DM_BITSPERPEL or DM_DISPLAYFREQUENCY;

        ModeOk := FALSE;
        if FFSDefFreq > 0 then
        begin
          dmDisplayFrequency := FFSDefFreq;
          ModeOk := ChangeDisplaySettings (dmScreenSettings, CDS_TEST) = DISP_CHANGE_SUCCESSFUL;
        end;

        if not ModeOk then
          if FFSMaxFreq >= FFSMinFreq then
          begin
            dmDisplayFrequency := FFSMaxFreq;
            ModeOk := FALSE;
            while (not ModeOk) and (dmDisplayFrequency >= FFSMinFreq) do
            begin
              if (ChangeDisplaySettings (dmScreenSettings, CDS_TEST) = DISP_CHANGE_SUCCESSFUL) then
                ModeOk := TRUE
              else
                Dec (dmDisplayFrequency);
            end;
          end;

        if ModeOk then
          FFSFreq := dmDisplayFrequency
        else
        begin
          FFSFreq := 0;
          dmFields := dmFields and (not DM_DISPLAYFREQUENCY);
        end;
      end;

      if (ChangeDisplaySettings (dmScreenSettings, CDS_FULLSCREEN) <> DISP_CHANGE_SUCCESSFUL) then
      begin
        MessageBox(0, 'Cannot switch to fullscreen mode', 'Error', MB_OK or MB_ICONERROR);
        FFullscreen := False;
      end;
    end;

    if FullScreen then
    begin
      FrameWidth := 0;
      FrameHeight := 0;
      TitleBarHeight := 0;
    end
    else
    begin
      FrameWidth := GetSystemMetrics (SM_CXDLGFRAME);
      FrameHeight := GetSystemMetrics (SM_CYDLGFRAME);
      TitleBarHeight := GetSystemmetrics (SM_CYCAPTION);
    end;
    WindowW := FActualWidth + 2 * FrameWidth;
    WindowH := FActualHeight + 2 * FrameHeight + TitleBarHeight;

    XPos := 0;
    YPos := 0;
    if not FFullScreen then
    begin
      XPos := (GetSystemMetrics (SM_CXFULLSCREEN) - WindowW) div 2;
      YPos := (GetSystemMetrics (SM_CYFULLSCREEN) - WindowH) div 2;
    end;

    if FFullScreen then
    begin
      dwStyle := WS_POPUP or
                 WS_CLIPCHILDREN or
                 WS_CLIPSIBLINGS;
      dwExStyle := WS_EX_APPWINDOW;
      ShowCursor (False);
    end
    else
    begin
      dwStyle := WS_DLGFRAME or
                 WS_CAPTION or
                 WS_SYSMENU or
                 WS_MINIMIZEBOX or
                 WS_CLIPCHILDREN or
                 WS_CLIPSIBLINGS;
      dwExStyle := WS_EX_APPWINDOW or
                   WS_EX_WINDOWEDGE;
    end;

    FHWnd := CreateWindowEx (dwExStyle, WINDOW_CLASS_NAME, PChar (FWindowTitle),
                 dwStyle, XPos, YPos, WindowW, WindowH, 0, 0, hInstance, nil);

    if FHWnd <> 0 then
    begin
      FHDC := GetDC (FHWnd);
      if (FHDC <> 0) then
      begin
        with pfd do
        begin
          nSize           := SizeOf(TPIXELFORMATDESCRIPTOR);
          nVersion        := 1;
          dwFlags         := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
          iPixelType      := PFD_TYPE_RGBA;
          cColorBits      := FPixelDepth;
          cRedBits        := 0;
          cRedShift       := 0;
          cGreenBits      := 0;
          cGreenShift     := 0;
          cBlueBits       := 0;
          cBlueShift      := 0;
          cAlphaBits      := 0;
          cAlphaShift     := 0;
          cAccumBits      := 0;
          cAccumRedBits   := 0;
          cAccumGreenBits := 0;
          cAccumBlueBits  := 0;
          cAccumAlphaBits := 0;
          cDepthBits      := 16;
          cStencilBits    := 16;  // bug fix!
          cAuxBuffers     := 0;
          iLayerType      := PFD_MAIN_PLANE;
          bReserved       := 0;
          dwLayerMask     := 0;
          dwVisibleMask   := 0;
          dwDamageMask    := 0;
        end;

        PixelFormat := ChoosePixelFormat (FHDC, @pfd);
        if PixelFormat <> 0 then
        begin
          if SetPixelFormat (FHDC, PixelFormat, @pfd) then
          begin
            FHRC := wglCreateContext (FHDC);
            if FHRC <> 0 then
            begin
              if wglMakeCurrent(FHDC, FHRC) then
              begin
                ShowWindow (FHWnd, SW_SHOW);
                SetForegroundWindow (FHWnd);
                SetFocus (FHWnd);

                glDisable (GL_DEPTH_TEST);
                glDisable (GL_CULL_FACE);
                glLoadIdentity ();

                FInitialized := TRUE;
              end;
            end;
          end;
        end;

      end;
    end;

    if not FInitialized then
    begin
      MessageBox(0, 'Cannot create game window', 'Error', MB_OK or MB_ICONERROR);
      Finalize;
    end;
  end;

  procedure TGameWindow.Flip;
  begin
    SwapBuffers (FHDC);
  end;

  procedure TGameWindow.Draw;
  begin
    FillArea (0, 0, FVirtualWidth, FVirtualHeight, BackgroundColor);
  end;

  procedure TGameWindow.Finalize;
  begin
    if FFullscreen then
    begin
      ChangeDisplaySettings (tdevmode (nil^), CDS_FULLSCREEN);
      ShowCursor (TRUE);
    end;

    wglMakeCurrent (FHDC, 0);
    wglDeleteContext (FHRC);
    FHRC := 0;

    ReleaseDC (FHWnd, FHDC);
    FHDC := 0;
    if (FHWnd <> 0) then
      DestroyWindow (FHWnd);
    FHWnd := 0;
    UnRegisterClass (WINDOW_CLASS_NAME, hInstance);
    hInstance := 0;
    FInitialized := FALSE;
  end;

  procedure TGameWindow.FillArea (X, Y, W, H: Integer; Color: TColor);
    var
      x1, y1, x2, y2: Integer;
  begin
    x1 := X;
    y1 := Y;
    x2 := X + W;
    y2 := Y + H;
    glDisable (GL_TEXTURE);
    glDisable (GL_BLEND);
    glBegin (GL_QUADS);
      glColor3ub (Color.R, Color.G, Color.B);
      glVertex2i (x1, y1);
      glVertex2i (x2, y1);
      glVertex2i (x2, y2);
      glVertex2i (x1, y2);
    glEnd ();
  end;

  procedure TGameWindow.FSetFullScreen (NewFullScreen: Boolean);
  begin
    if NewFullScreen <> FFullScreen then
    begin
      if FInitialized then
        Finalize;
      FFullScreen := NewFullScreen;
      Initialize;
    end;
  end;

  procedure TGameWindow.FSetWindowTitle (NewTitle: string);
  begin
    if (not FFullScreen) and (NewTitle <> FWindowTitle) then
      SetWindowText (FHWnd, PChar (NewTitle + ' '));
    FWindowTitle := NewTitle;
  end;

end.
