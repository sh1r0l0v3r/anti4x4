unit unit_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

type
  { TForm1 }

  TForm1 = class(TForm)
    Label1:TLabel;
    Timer1:TTimer;
    procedure Timer1Timer(Sender:TObject);
  private
    { private declarations }
  public
    { public declarations }
    procedure ConvertImage(Sender: TObject);
  end;

var Form1: TForm1;

implementation

{$R *.lfm}

uses unit_YCbCr, BGRABitmap, BGRABitmapTypes, FPWriteJPEG;

{ TForm1 }

procedure TForm1.ConvertImage(Sender: TObject);
var image: TBGRABitmap;
    writer: TFPWriterJPEG;
    split_image: TCustomImage;
    block_4x4_data: TPixelData;
    lv: Integer;
    fname: String;
begin
  if ParamCount < 1 then fname := 'default.jpg' // default
                    else fname := ParamStr(1);

  if not FileExists(fname) then
  begin
    ShowMessage('Usage: ' + ParamStr(0) + ' <filename.jpg>');
    Application.Terminate;
    Exit;
  end;

  image := TBGRABitmap.Create(fname);

  extract_channels(image, split_image); // also sets array size!
//  render_individual_channels(split_image, Image_source_split);
//  render_individual_channels_RGB(Image_source, Image_source_split);

  for lv := 1 to 16 do
  begin
    redistribute_4x4_blocks(split_image.Width, split_image.Height, split_image.Cb);
  end;

  extract_average_4x4_blocks(split_image.Width, split_image.Height, split_image.Cb, block_4x4_data); // also sets array size!
  weighted_average_3x3(split_image.Width div 4, split_image.Height div 4, block_4x4_data);
  replace_average_4x4_blocks(split_image.Width, split_image.Height, 1.0, block_4x4_data, split_image.Cb);

  median_3x3(split_image.Width, split_image.Height, split_image.Cb);
  weighted_average_3x3(split_image.Width, split_image.Height, split_image.Cb);
  median_3x3(split_image.Width, split_image.Height, split_image.Cb);

  median_3x3(split_image.Width, split_image.Height, split_image.Cr);

  add_noise(split_image.Width, split_image.Height, 1, false, split_image.Cb, split_image.Cr);

  combine_channels(1.003, split_image, image);
//  render_individual_channels(split_image, Image_reconstruct_split);
//  render_individual_channels_RGB(Image_reconstruct, Image_reconstruct_split);

  writer := TFPWriterJPEG.Create;
  writer.CompressionQuality := 100;
  writer.ProgressiveEncoding := false;

  image.SaveToFile('x4_' + ExtractFileNameWithoutExt(fname) + '.jpg', writer);

  FreeAndNil(image);
  FreeAndNil(writer);
end;

procedure TForm1.Timer1Timer(Sender:TObject);
begin
  Timer1.Enabled := false;
  Application.ProcessMessages;
  ConvertImage(Sender);
  Application.Terminate;
end;

end.

