program sd_client;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads, {$ENDIF} {$ENDIF}
  Classes,
  SysUtils,
  CustApp,
  Sockets { you can add units after this };

type

  { TMyApplication }

  TMyApplication = class(TCustomApplication)
  protected
      sockerr: integer;
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
    function PortCheck(pttype: string; ptnumber: integer): boolean;
    function SendToDBServer(ServerIp, SendData: string): word;
  end;

  {-------------------------------------------------------------------}
  { TMyApplication }

  procedure TMyApplication.DoRun;
  var
    ErrorMsg, cmd, confirm, instr, ip: string;
    i, sendres: word;
    cfgf: TextFile;
    cfgdata, cfgstr, port_proto, port_num: TStringList;
    no_db, no_ports, port_data: boolean;
    interval: integer;
    port_state: char;
  begin

    // Paramstr(1) - will read param 1

    // quick check parameters
    ErrorMsg := CheckOptions('h', 'help');
    if ErrorMsg <> '' then
    begin
      ShowException(Exception.Create(ErrorMsg));
      Terminate;
      Exit;
    end;

    // parse parameters
    if HasOption('h', 'help') then
    begin
      WriteHelp;
      Terminate;
      Exit;
    end;

    { add your program here }
    writeln('Server Dispatcher by scadl');
    writeln('--------------------------');

    Write('Loading config...' );

    {$I-}//  I\O Cather start
    AssignFile(cfgf, ExtractFilePath(ExeName) + 'config.txt');
    Reset(cfgf);
    {$I+}//  I\O Cather end
    if (IOResult = 0) then
    begin
      writeln('Done!');

      cfgdata := TStringList.Create;
      cfgstr := TStringList.Create;
      port_proto := TStringList.Create;
      port_num := TStringList.Create;

      while not EOF(cfgf) do
      begin
        readln(cfgf, instr);
        cfgdata.Add(instr);
      end;

      no_db := True;
      no_ports := True;

      if (cfgdata.Count = 0) then
      begin
        writeln('Config is empty!');
        writeln('Use -h key, to learn how to fill it.');
      end
      else
      begin
        Write('Parsing & Scaning...');
        interval := 900;

        for i := 0 to cfgdata.Count - 1 do
        begin

          if (Pos('DB_SERVER:', cfgdata[i]) > 0) then
          begin
            cfgstr.Delimiter := ':';
            cfgstr.DelimitedText := cfgdata[i];
            ip := cfgstr[1];

            no_db := False;
          end;

          if (Pos('SCAN_INTERVAL:', cfgdata[i]) > 0) then
          begin
            cfgstr.Delimiter := ':';
            cfgstr.DelimitedText := cfgdata[i];
            interval := StrToInt(cfgstr[1]) * 1000;
          end;

          if (Pos('PORT_SCAN:', cfgdata[i]) > 0) then
          begin
            writeln('');
            no_ports := False;
          end;

          if ((Pos('TCP:', cfgdata[i]) > 0) or (Pos('UDP:', cfgdata[i]) > 0)) then
          begin

            cfgstr.Delimiter := ':';
            cfgstr.DelimitedText := cfgdata[i];

            port_proto.Add(cfgstr[0]);
            port_num.Add(cfgstr[1]);

          end;
        end;

        if (no_db = False) and (no_ports = False) and (interval > 900) then
        begin

          repeat

            for i := 0 to port_num.Count - 1 do
            begin

              port_data := PortCheck(port_proto[i], StrToInt(port_num[i]));
              if (port_data) then
              begin
                instr := 'ONLINE ';
                port_state := '1';
              end
              else
              begin
                instr := 'OFFLINE ';
                port_state := '0';
              end;

              writeln('Port check <' + DateTimeToStr(Now) + '> ' +
                port_proto[i] + ':' + port_num[i] + ' --> ' + instr);

              // + 'E'+ inttostr(sockerr)

              Write('Sending to DB...');
              sendres := SendToDBServer(ip, 'SRV_DATA:' + port_proto[i] + ':' + port_num[i] + ':' + port_state);
              if (sendres <> 1) then
              begin
                writeln('Error:', sendres);
              end
              else
              begin
                writeln('Sent!');
              end;

              Sleep(interval);
            end;

          until False;
        end;

        if (no_db = True) then
        begin
          Write('No DB ip found! ');
        end;
        if (no_ports = True) then
        begin
          Write('No scanable ports found! ');
        end;
        if (interval = 900) then
        begin
          Write('Scan interval not set! ');
        end;

      end;

    end
    else
    begin
      writeln('');
      writeln('Err_1: Config File not exist');
    end;

    Write('Press any key, to exit.');
    readln(cmd);

    // stop program loop
    Terminate;
  end;

  {-------------------------------------------------------------------}

  constructor TMyApplication.Create(TheOwner: TComponent);
  begin
    inherited Create(TheOwner);
    StopOnException := True;
  end;

  destructor TMyApplication.Destroy;
  begin
    inherited Destroy;
  end;

  procedure TMyApplication.WriteHelp;
  begin
    { add your help code here }
    writeln('Server Dispatcher help system');
    writeln('--------------------------');
    writeln('This is simple sockets client, with simple portscan capabilities.');
    writeln('To work right, it requires 2 things:');
    writeln('1) List of scanable local ports and addres of DB (to report gathred data), stored in "config.txt", next to this exe location');
    writeln('2) Opened TCP-port 10001, and running Server Dispatcher listener, on DB side');
    writeln('');
    writeln('Config file format:');
    writeln('--------------------------');
    writeln('DB_SERVER:<db_host_ip>');
    writeln('SCAN_INTERVAL:<interval_seconds>');
    writeln('PORT_SCAN:');
    writeln('<TCP/UDP:port_number1> ');
    writeln('<TCP/UDP:port_number2> ');
    writeln('etc... ');
  end;

  function TMyApplication.PortCheck(pttype: string; ptnumber: integer): boolean;
  var
    SockAddr: TInetSockAddr;
    SockBuff: string[255];
    Sock, udpsend: longint;
    domain, xtype, protocol, sl, sv: integer;
  begin

    if (pttype = 'TCP') then
    begin
      domain := PF_INET;
      xtype := SOCK_STREAM;
      protocol := 0;
    end;

    if (pttype = 'UDP') then
    begin
      domain := AF_INET;
      xtype := SOCK_DGRAM;
      protocol := IPPROTO_UDP;
    end;

    PortCheck := True;

    Sock := fpSocket(domain, xtype, protocol);
    if (Sock < 0) then
    begin
      //writeln('Socket Err: ', socketerror);
      // Solcket not created
      PortCheck := False;
    end
    else
    begin
      SockAddr.sin_family := domain;                                // socket family
      SockAddr.sin_port := htons(ptnumber);                         // socket port
      SockAddr.sin_addr := HostToNet(StrToHostAddr('127.0.0.1'));   // socket ip
      if (fpConnect(Sock, @SockAddr, sizeof(SockAddr)) < 0) then
      begin
        //writeln('Connect Err: ', socketerror);
        // Sicket occupied
        PortCheck := False;
      end
      else
      begin
        if (pttype = 'UDP') then
        begin

          SockBuff := 'UDP_TEST';

          // Trying to send test message
          fpsend(Sock, @SockBuff, SizeOf(SockBuff), 0);

          // Setting socket timeout: 0.25 second.
          sv := 250;
          fpsetsockopt(Sock, SOL_SOCKET, SO_RCVTIMEO, @sv, SizeOf(SockAddr));

          // Trying to recive response (15 bytes long)
          udpsend := fprecv(Sock, @SockBuff, 15, 0);
          if (socketerror = 10060) OR (socketerror = 110) then
          begin
            // Winsock WSAETIMEDOUT - 10060 - Connection timed out.
            // UnixSock: ETIMEDOUT - 110 - Connection timed out
            // This means that some server listening for incoming connection
            PortCheck := True;
          end;

          if (socketerror = 10054) OR (socketerror = 111) then
          begin
            // WInsock: WSAECONNRESET - 10054 - Connection reset by peer.
            // UnixSock: ECONNREFUSED - 111 - Connection refused
            // This means, that none listning here, so connection reset
            PortCheck := False;
          end;

          sockerr := socketerror;

        end;
      end;
    end;

    fpshutdown(Sock, 4);

  end;

  function TMyApplication.SendToDBServer(ServerIp, SendData: string): word;
  var
    SockAddr: TInetSockAddr;
    SockBuff: string[255];
    Sock: longint;
    SockIN, SockOUT: Text;
  begin

    // Creating socket...
    Sock := fpsocket(AF_INET, SOCK_STREAM, 0);
    if (Sock = -1) then
    begin
      //Socket Creation Error, socketerror;
      SendToDBServer := socketerror;
    end
    else
    begin
      SockAddr.sin_family := AF_INET;
      SockAddr.sin_port := htons(10001);
      SockAddr.sin_addr := HostToNet(StrToHostAddr(ServerIp));
      if not (Connect(Sock, SockAddr, SockIN, SockOUT)) then
      begin
        //Connection Error, socketerror
        SendToDBServer := socketerror;
      end
      else
      begin
        //Sending your msg;
        Rewrite(SockOUT);               // Open stream (file) for writing

        Writeln(SockOUT, SendData);     // Writing data to stream (file)
        Flush(SockOUT);                 // Write to disk stream to socket (file to disk)

        Writeln(SockOUT, 'quit');     // Writing data to stream (file)
        Flush(SockOUT);                 // Write to disk stream to socket (file to disk)

        Close(SockOUT);                 // Closing stream (file)

        SendToDBServer := 1;         // Reporting data send ok.
      end;
    end;

  end;

var
  Application: TMyApplication;

{$R *.res}

begin
  Application := TMyApplication.Create(nil);
  Application.Title := 'Server Dispatcher CLIENT';
  Application.Run;
  Application.Free;
end.
