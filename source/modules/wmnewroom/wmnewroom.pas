unit WmNewRoom;

{$mode objfpc}
{$H+}

interface

uses
	Classes,
	FpImage,
	FpCanvas,
	FpImgCanv,
	HttpDefs,
	FpHttp,
	FpWeb;

type
	TCanvas = class(TFpImageCanvas)
	protected
		procedure DoCopyRect(
			x                : Integer;
			y                : Integer;
			Canvas           : TFpCustomCanvas;
			const SourceRect : TRect); override;
		procedure DoDraw(
			x         : Integer;
			y         : Integer;
			const Img : TFpCustomImage); override;
	end;

	TNewRoomModule = class(TFpWebModule)
	private
		FData : string;
		FId   : string;
		procedure ReplaceTags(
			Sender          : TObject;
			const TagString : string;
			TagParams       : TStringList;
			out ReplaceText : string);
	published
		procedure Request(
			Sender      : TObject;
			ARequest    : TRequest;
			AResponse   : TResponse;
			var Handled : Boolean);
	end;

var
	NewRoomModule : TNewRoomModule;

implementation

{$R *.lfm}

uses
	FpWritePng,	
	FtFont,
	Base64,
	IniFiles;

procedure TCanvas.DoCopyRect(
	x                : Integer;
	y                : Integer;
	Canvas           : TFpCustomCanvas;
	const SourceRect : TRect);
begin
end;

procedure TCanvas.DoDraw(
	x         : Integer;
	y         : Integer;
	const Img : TFpCustomImage);
begin
end;

procedure TNewRoomModule.ReplaceTags(
	Sender          : TObject;
	const TagString : string;
	TagParams       : TStringList;
	out ReplaceText : string);
begin
	case TagString of
		'CaptchaId'   : ReplaceText := FId;
		'CaptchaData' : ReplaceText := FData
	end
end;

procedure TNewRoomModule.Request(
	Sender      : TObject;
	ARequest    : TRequest;
	AResponse   : TResponse;
	var Handled : Boolean);
const
	CaptchaDir = 'res/captcha/';
	Chars      = '0123456789abcdefghijklmnopqrstuvwxyz';
	FontPath   = '/Library/Fonts/';

var
	Ini    : TIniFile;
	Allow  : Boolean;

procedure GenerateCaptcha;
var
	Image       : TFpCustomImage;
	Canvas      : TCanvas;
	Writer      : TFpCustomImageWriter;
	AFont       : TFreeTypeFont;
	CaptchaText : string;
	i           : Integer;
	x           : Integer;
	y           : Integer;
	x2          : Integer;
	y2          : Integer;
	AChar       : Char;
	AFile       : Text;
begin
	Image  := TFpMemoryImage.Create(132, 46);
	Canvas := TCanvas.Create(Image);

	FtFont.InitEngine;
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
	Writer := TFpWriterPng.Create;
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

	Handled := True
end;

initialization
	RegisterHttpModule('new', TNewRoomModule)
end.
