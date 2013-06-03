unit WmInfo;

interface
uses
	HTTPDefs,
	fpHTTP,
	fpWeb;

type
	TWmInfo = Class(TFPWebModule)
	published
		procedure DoRequest(
			Sender     : TObject;
			ARequest   : TRequest;
			AResponse  : TResponse;
			var Handle : Boolean);
	end;

var
	AWmInfo : TWmInfo;

implementation
{$R *.lfm}

procedure TWmInfo.DoRequest(
	Sender     : TObject;
	ARequest   : TRequest;
	AResponse  : TResponse;
	var Handle : Boolean);
begin
	AResponse.Contents.LoadFromFile('templates/pages/info.htm');
	
	Handle := True
end;

initialization
	RegisterHTTPModule('info', TWmInfo)
end.
