program Ocean;

{$DEFINE SHOW_FPS}

  uses
    Windows, Messages, OpenGL, Utils, Screen, Ground, Noise, Sky;

{$R *.RES}

  const
    WINDOW_TITLE = 'Ocean';

  {$IFDEF SHOW_FPS}
  const
    FPS_TIMER = 1;
    FPS_INTERVAL = 1000;
    FPSCount: Integer = 0;
    CurFPS: Integer = 0;
    NewFPS: Integer = 0;
  {$ENDIF}

  procedure glBindTexture (target: glEnum; texture: glUint); stdcall; external opengl32;
  procedure glGenTextures (n: glSizei; var textures: glUint); stdcall; external opengl32;
  procedure glDeleteTextures (n: glSizei; var textures: glUint); stdcall; external opengl32;

  var
    keys: array[0..255] of Boolean;  // buffer for keystrokes



  var
    bActive: Boolean;
    bSwitchingModes: Boolean;
    GameWindow: TGameWindow;
    Grnd: TGround;
    Sk: TSky;


  procedure SetPerspective;
  begin
    glMatrixMode (GL_PROJECTION);
    glLoadIdentity ();
    gluPerspective (45, 4/3, 0.0, 100.0);
    glMatrixMode (GL_MODELVIEW);
    glLoadIdentity ();
  end;

  function WndProc (hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
  begin
    Result := 0;

    case (Msg) of
      WM_DESTROY,
      WM_CLOSE:
        if not bSwitchingModes then
        begin
          PostQuitMessage (0);
          Exit;
        end;

      WM_ACTIVATE:
        begin
          bActive := LOWORD (wParam) <> WA_INACTIVE;
          with GameWindow do
            if bActive then
            begin
              WindowTitle := WINDOW_TITLE;

             { RedrawBorder; }
            end
            else
              WindowTitle := WINDOW_TITLE + ' (paused)';
          Exit;
        end;

      WM_SYSCOMMAND:
        begin
          if (wParam = SC_SCREENSAVE) or (wParam = SC_MONITORPOWER) then
            Exit;
        end;

      WM_SYSKEYDOWN:
        begin
          keys[wParam] := True;
          if (keys[VK_MENU]) and (wParam = VK_RETURN) then
            with GameWindow do
            begin
              bSwitchingModes := TRUE;

             // ___.Finalize;
              Sk.Finalize;
              Grnd.Finalize;


              PostMessage (Handle, WM_ACTIVATE, WA_INACTIVE, 0);
              FullScreen := not FullScreen;
              PostMessage (Handle, WM_ACTIVATE, WA_ACTIVE, 0);

             // ___.Initialize;
              Grnd.Initialize;
              Sk.Initialize;

              SetPerspective;

              bSwitchingModes := FALSE;
              Exit;
            end;
        end;
      WM_SYSKEYUP:
        begin
          keys[wParam] := False;

        end;

      WM_KEYDOWN:
        begin
          keys[wParam] := True;

        {
          if wParam = VK_LEFT then
            XSpeed := XSpeed - X_ACC;
          if wParam = VK_RIGHT then
            XSpeed := XSpeed + X_ACC;
          if wParam = VK_DOWN then
            YSpeed := YSpeed + Y_ACC;
          if wParam = VK_UP then
            YSpeed := YSpeed - Y_ACC;
        }

          Exit;
        end;
      WM_KEYUP:
        begin
          keys[wParam] := False;
          Exit;
        end;

      WM_TIMER:
        begin
      {$IFDEF SHOW_FPS}
          if wParam = FPS_TIMER then
          begin
            NewFPS := Round (FPSCount * 1000 / FPS_INTERVAL);
            FPSCount := 0;
            Exit;
          end;
      {$ENDIF}
        end;
      WM_MOVE:
        begin

         { GameWindow.RedrawBorder; }

          Exit;
        end;
    end;
    Result := DefWindowProc (hWnd, Msg, wParam, lParam);
  end;


  //var
  //  S: string[255];

  function WinMain (hInstance: HINST; hPrevInstance: HINST;
                    lpCmdLine: PChar; nCmdShow: Integer): Integer; stdcall;
    var
      Msg: TMsg;
      Done: Boolean;
      ddh: HINST;

      Pos: Real;

    var
      FogColor: array[0..3] of glFloat;

  begin
    { avoid DDHELP.EXE error }
    ddh := LoadLibrary ('DDRAW.DLL');
    if Pointer (ddh) <> nil then
      FreeLibrary (ddh);

  {
    AssignFile (F, s);
    FileMode := 0;
    Reset (F, 1);
    Seek (F, 0);
    BlockRead (F, Buf, 2);
    CloseFile (F);
    Caption := Buf[0] + Buf[1];
  }

   // NoiseSizeX := 2;
   // NoiseSizeY := 2;

    bSwitchingModes := FALSE;

    GameWindow := TGameWindow.Create (@WndProc);
   { InitMidiSound (GameWindow.Handle); }

    with GameWindow do
    begin
      Width := 640; // 512;
      Height := 480; // 384;
      ActualWidth := Width;
      ActualHeight := Height;
      VirtualWidth := Width; // Width div 2;
      VirtualHeight := Height; // Height div 2;
      FSMinFreq :=  60;
      FSDefFreq :=  85;
      FSMaxFreq := 100;
      BackGroundColor.RGB := $FFDFBF;
      PixelDepth := 32;
      FullScreen := FALSE;
      WindowTitle := WINDOW_TITLE;
      Initialize;
    end;

    SetPerspective;

    Grnd := TGround.Create;
    with Grnd do
    begin
      TexWidth := 64;
      TexHeight := 64;

      Seed := 5316;

      X := 0;
      Y := 0;
      Z := 0;

      W := 20;
      H := 20;

      N := 3;
      D := 7;

      Initialize;
    end;

    Sk := TSky.Create;
    with Sk do
    begin
      TexWidth := 64;
      TexHeight := 64;

      Seed := 543210;

      W := 100;
      H :=  50;

      N :=  32;
      D := 100;

      Initialize;
    end;


  {$IFDEF SHOW_FPS}
    SetTimer (GameWindow.Handle, FPS_TIMER, FPS_INTERVAL, nil);
  {$ENDIF}

    Done := False;
    bActive := TRUE;

 //   with GameWindow do
 //     glOrtho (-100, 100, -100, 100, +100.0, -100.0);
 //   with GameWindow do
 //     glViewport (0, Height div 2, Width, Height div 2);

    Pos := 0;

    repeat
      if (PeekMessage (Msg, 0, 0, 0, PM_REMOVE)) then
      begin
        if (Msg.message = WM_QUIT) then
          Done := True
        else
        begin
          TranslateMessage (Msg);
          DispatchMessage (Msg);
        end;
      end
      else
        if bActive then
        begin

         // glDisable (GL_BLEND);
         // glDisable (GL_TEXTURE_2D);



          glClearColor (0.65, 0.285, 0.195, 1);
          glClear ({ GL_COLOR_BUFFER_BIT or } GL_DEPTH_BUFFER_BIT);

         // glEnable (GL_DEPTH_TEST);

        {
          with GameWindow do
            glOrtho (0, VirtualWidth, VirtualHeight, 0, -1.0, 1.0);
          GameWindow.Draw;
        }


           FogColor[0] := 0.8;
           FogColor[1] := 0.9;
           FogColor[2] := 1.0;
           FogColor[3] := 1;

           FogColor[0] := 0.9;
           FogColor[1] := 0.95;
           FogColor[2] := 1.0;
           FogColor[3] := 1;

           glFogi (GL_FOG_MODE, GL_LINEAR);
           glFogfv (GL_FOG_COLOR, @FogColor);
           glFogf (GL_FOG_START, 25);
           glFogf (GL_FOG_END, 100);
           glEnable (GL_FOG);

          glLoadIdentity;
        {
          with GameWindow do
            glViewport (0, Height div 2, Width, Height div 2);

          glColor3ub (255, 255, 255);
          glRotatef (Cos (Pos / 32) * 10, 0, 0, 1);
          glTranslatef (0, -3 - Sin (Pos / 21) * 3, 0);
          Grnd.Draw;

          glLoadIdentity;

          with GameWindow do
            glViewport (0, 0, Width, Height div 2);
        }
          glColor3ub (255, 255, 255);
          glRotatef (Cos (Pos / 22) * 10, 0, 0, 1);
          glTranslatef (0, -7 - Sin (Pos / 30) * 3, 0);


          Sk.Draw;
          Grnd.Draw;


          Pos := Pos + 0.25;
          Grnd.Z := Pos;

         // glColor3ub (255, 255, 255);

         // glMatrixMode (GL_MODELVIEW);

         // glColor3ub (255, 255, 255);

       {
          glEnable (GL_TEXTURE_2D);
          if TileSet.Transparent then
          begin
            glEnable (GL_BLEND);
            glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
          end;
         // glEnable (GL_BLEND);
         // glBlendFunc (1, 1);

         // glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
         // glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
          glBindTexture (GL_TEXTURE_2D, TileSet.Textures[ 17]);
          glBegin (GL_QUADS);
            glTexCoord2f(0.0, 0.0); glVertex2f(32+   0.0, 32+   0.0);
            glTexCoord2f(1.0, 0.0); glVertex2f(32+ 128.0, 32+   0.0);
            glTexCoord2f(1.0, 1.0); glVertex2f(32+ 128.0, 32+ 128.0);
            glTexCoord2f(0.0, 1.0); glVertex2f(32+   0.0, 32+ 128.0);
          glEnd;
        }


        {$IFDEF SHOW_FPS}
          if NewFPS <> CurFPS then
          begin
            CurFPS := NewFPS;
            GameWindow.WindowTitle := WINDOW_TITLE + ' (' + IntToStr (CurFPS) + ' fps)';
          end;
          Inc (FPSCount);
        {$ENDIF}


          GameWindow.Flip;


          if (keys[VK_ESCAPE]) then
            Done := True;

          if keys[VK_RETURN] then
          begin
            bSwitchingModes := TRUE;
            Grnd.Finalize;
            Sk.Finalize;
            Sk.Initialize;
            Grnd.Initialize;
            bSwitchingModes := FALSE;
            keys[VK_RETURN] := FALSE;
          end;
         // else
         //   ProcessKeys;
        end;

     //   S := IntToStr (Rnd (1000, Seed)) + ' ' + S;

     //   GameWindow.WindowTitle := S;

    until Done;

  {$IFDEF SHOW_FPS}
    KillTimer (GameWindow.Handle, FPS_TIMER);
  {$ENDIF}

   { MidiSoundDone; }

    Sk.Finalize;
    Grnd.Finalize;
    GameWindow.Finalize;

    Sk.Free;
    Grnd.Free;
    GameWindow.Free;

    Result := Msg.wParam;
  end;

begin
  WinMain (hInstance, hPrevInst, CmdLine, CmdShow);
end.


