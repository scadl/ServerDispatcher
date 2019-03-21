program sd_admin;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads, {$ENDIF} {$ENDIF}
  Classes,
  SysUtils,
  CustApp,
  Sockets,
  sqldb { you can add units after this };

type

  { TMyApplication }

  TMyApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
    function SocketSend(cmd_str, sock_ip: string): string;
    function MySQLSend(command, sock_ip: string): string;
  end;

  { TMyApplication }

  procedure TMyApplication.DoRun;
  var
    ErrorMsg, cmd, confirm, ip: string;
    i: integer;
  begin

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
    writeln('Server Dispatcher (by scadl) ADMIN Tool');
    writeln('------------------------------------------------');
    writeln('Currently you can use these commadnds:');
    writeln(' QUIT - Just disconnect from DB server');
    writeln(' SHUTDOWN - Shutdwon DB server, then disconnect');
    //writeln(' STATUS - Print all data, gatherd by DB side');
    writeln('------------------------------------------------');

    Write('Server IP: ');
    readln(ip);

    repeat

      Write('SEND CMD: ');
      readln(cmd);

      writeln(SocketSend(cmd, ip));

    until (cmd = 'quit') or (cmd = 'shutdown');

    // stop program loop
    Terminate;
  end;

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
    writeln('Server Dispatcher ADMIN Tool');
    writeln('--------------------------');
    writeln('This is simple sockets client, able o control SD_Client server.');
    writeln('To work right, it requires :');
    writeln('1) Opened TCP-port 10001, and runned Server Dispatcher listener, on DB side');
    writeln('2) Knowing and understanding sence of admin commands');
  end;

  function TMyApplication.SocketSend(cmd_str, sock_ip: string): string;
  var
    SockAddr: TInetSockAddr;
    SockBuff: string[255];
    Sock: longint;
    SockIN, SockOUT: Text;
    SResponse: string;
  begin

    SResponse := 'Connecting...';
    Sock := fpsocket(AF_INET, SOCK_STREAM, 0);
    if (Sock = -1) then
    begin
      SResponse := SResponse + 'Socket Err: ' + IntToStr(socketerror);
    end
    else
    begin
      SockAddr.sin_family := AF_INET;
      SockAddr.sin_port := htons(10001);
      SockAddr.sin_addr := HostToNet(StrToHostAddr(sock_ip));
      if not (Connect(Sock, SockAddr, SockIN, SockOUT)) then
      begin
        SResponse := SResponse + 'Connect Err: ' + IntToStr(socketerror);
      end
      else
      begin
        SResponse := SResponse + 'Done!' + #13;

          Rewrite(SockOUT);     // Open for writing
          Reset(SockIN);        // Open for reading

          SResponse := SResponse + 'Sending your msg...' + #13;

          SockBuff := cmd_str;
          Writeln(SockOUT, SockBuff);
          Flush(SockOUT);      // Write to disk or stream

        if (cmd_str <> 'quit') and (cmd_str <> 'shutdown') then
        begin

          ReadLn(SockIN, SockBuff);
          SResponse := SResponse + 'Server response:' + '-' + SockBuff;

          Writeln(SockOUT, 'quit');
          Flush(SockOUT);

        end else begin
           Writeln(SockOUT, 'quit');
          Flush(SockOUT);
        end;

        Close(SockOUT);
        Close(SockIN);

      end;
    end;

    SocketSend := SResponse;
  end;

  function TMyApplication.MySQLSend(command, sock_ip: string): string;
  var
    //DBName, DBUser, DBPassword: string;
    DBContext: TSQLConnector;
    DBQuerry: TSQLQuery;
    DBTransaction: TSQLTransaction;
  begin

    DBContext := TSQLConnector.Create(nil);
    DBQuerry := TSQLQuery.Create(nil);
    DBTransaction := TSQLTransaction.Create(nil);

    DBContext.HostName := sock_ip;
    DBContext.DatabaseName := '_peronal';
    DBContext.UserName := 'root';
    DBContext.Password := '198864';

    DBContext.ConnectorType := '';

    DBQuerry.Close;
    DBQuerry.SQL.Text := 'SELECT * FROM users;';

    DBContext.Connected := True;
    DBTransaction.Active := True;

    DBQuerry.Open;

    DBQuerry.Close;
    DBTransaction.Active := False;
    DBContext.Connected := False;

    MySQLSend := '';
  end;

var
  Application: TMyApplication;
begin
  Application := TMyApplication.Create(nil);
  Application.Title := 'Server Dispatcher ADMIN';
  Application.Run;
  Application.Free;
end.
