unit WmInfo;

{$mode objfpc}{$h+}{$r *.lfm}

interface

uses
  HttpDefs,
  FpHttp,
  FpWeb;

type
  TInfoModule = class(TFpWebModule)
  published
    procedure Request(
      Sender      : TObject;
      ARequest    : TRequest;
      AResponse   : TResponse;
      var Handled : Boolean);
  end;

var
  InfoModule : TInfoModule;

implementation

procedure TInfoModule.Request(
  Sender      : TObject;
  ARequest    : TRequest;
  AResponse   : TResponse;
  var Handled : Boolean);
begin
  AResponse.Contents.LoadFromFile('templates/pages/info.htm');
  
  Handled := True
end;

initialization
  RegisterHttpModule('info', TInfoModule)
end.
