unit WmNewRoom;

interface
uses
	Classes,
	FPWritePng,
	FPImage,
	FPCanvas,
	FPImgCanv,
	FTFont,
	Base64,
	IniFiles,
	HTTPDefs,
	fpHTTP,
	fpWeb;

type
	TCanvas = Class(TFPImageCanvas)
	protected
		procedure DoCopyRect(
			x                : Integer;
			y                : Integer;
			Canvas           : TFPCustomCanvas;
			const SourceRect : TRect); override;
		procedure DoDraw(
			x         : Integer;
			y         : Integer;
			const Img : TFPCustomImage); override;
	end;

	TWmNewRoom = Class(TFPWebModule)
	private
		FData : String;
		FId   : String;
		procedure ReplaceTags(
			Sender          : TObject;
			const TagString : String;
			TagParams       : TStringList;
			out ReplaceText : String);
	published
		procedure DoRequest(
			Sender     : TObject;
			ARequest   : TRequest;
			AResponse  : TResponse;
			var Handle : Boolean);
	end;

var
	AWmNewRoom : TWmNewRoom;

implementation
{$R *.lfm}

procedure TCanvas.DoCopyRect(
	x                : Integer;
	y                : Integer;
	Canvas           : TFPCustomCanvas;
	const SourceRect : TRect);
begin
end;

procedure TCanvas.DoDraw(
	x         : Integer;
	y         : Integer;
	const Img : TFPCustomImage);
begin
end;

procedure TWmNewRoom.ReplaceTags(
	Sender          : TObject;
	const TagString : String;
	TagParams       : TStringList;
	out ReplaceText : String);
begin
	case TagString of
		'CaptchaId'   : ReplaceText := FId;
		'CaptchaData' : ReplaceText := FData
	end
end;

procedure TWmNewRoom.DoRequest(
	Sender     : TObject;
	ARequest   : TRequest;
	AResponse  : TResponse;
	var Handle : Boolean);
const
	CaptchaDir = 'res/captcha/';
	Chars      = '0123456789abcdefghijklmnopqrstuvwxyz';
	FontPath   = '/Library/Fonts/';

var
	Ini    : TIniFile;
	Allow  : Boolean;

procedure GenerateCaptcha;
var
	Image       : TFPCustomImage;
	Canvas      : TCanvas;
	Writer      : TFPCustomImageWriter;
	AFont       : TFreeTypeFont;
	CaptchaText : String;
	i           : Integer;
	x           : Integer;
	y           : Integer;
	x2          : Integer;
	y2          : Integer;
	AChar       : Char;
	AFile       : Text;
begin
	Image  := TFPMemoryImage.Create(132, 46);
	Canvas := TCanvas.Create(Image);

	FTFont.InitEngine;
	FontMgr.SearchPath := FontPath;
	AFont := TFreeTypeFont.Create;

	CaptchaText := '';
	for i := 1 to 5 do
		CaptchaText := CaptchaText+Chars[Random(Length(Chars))+1];
	x := Random(Image.Width  div 3);
	y := Random(Image.Height div 2) + Image.Height div 2;

	Canvas.Brush.FPColor := colWhite;
	Canvas.Brush.Style   := bsSolid;
	Canvas.Rectangle(0, 0, Image.Width - 1, Image.Height - 1);

	Canvas.Font := AFont;
	Canvas.Font.Name := 'Arial';
	Canvas.Font.Size := 13;	

	Canvas.TextOut(x, y, CaptchaText);

	for i := 1 to 12 do
	begin
		x  := Random(Image.Width);
		y  := Random(Image.Height);
		x2 := Random(Image.Width);
		y2 := Random(Image.Height);
		Canvas.Line(x, y, x2, y2)
	end;

	Str(Random($FF), FId);
	Writer := TFPWriterPng.Create;
	Image.SaveToFile(CaptchaDir + FId + '.png', Writer);

	FData := '';

	AssignFile(AFile, CaptchaDir + FId + '.png');
	Reset(AFile);

	repeat
		Read(AFile, AChar);
		FData := FData + Achar
	until EOF(AFile);

	Close(AFile);
	Erase(AFile);

	FData := EncodeStringBase64(FData);

	AssignFile(AFile, CaptchaDir + FId + '.cap');
	Rewrite(AFile);
	WriteLn(AFile, CaptchaText);
	Close(AFile);

	Writer.Free;
	Canvas.Free;
	Image.Free
end;

begin
	Randomize;
	
	Ini := TIniFile.Create('data/rooms.ini');
	Allow := Ini.ReadString('security','allownew','false')='true';
	Ini.Free;

	if not Allow then
		AResponse.Contents.LoadFromFile(
			'templates/pages/error/newroom.htm')
	else
	begin
		GenerateCaptcha;
		
		ModuleTemplate.FileName := 'templates/pages/newroom.htm';
		ModuleTemplate.AllowTagParams := True;
		ModuleTemplate.OnReplaceTag := @ReplaceTags;

		AResponse.Content := ModuleTemplate.GetContent
	end;

	Handle := True
end;

initialization
	RegisterHTTPModule('new', TWmNewRoom)
end.
