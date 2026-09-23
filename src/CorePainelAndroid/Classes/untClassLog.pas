unit untClassLog;

interface

uses
  SysUtils, Variants, Classes, math, StrUtils, TypInfo, System.IoUtils,
  System.JSON, System.Zlib, FMX.Types, System.SyncObjs, Pkg.Json.DTO;

type
  {Classe responsável pela geração de LOG!}
  TGeraLog = Class
    private
      FCritical : TCriticalSection;

      class var FArquivoLog : string; // = '.\arquivo_log.txt';
      class var FArquivoJSon : String;
      {Indica o arquivo em que o LOG será gerado, no caso, no mesmo diretório do executável!}
      Class var FInstance : TGeraLog;
      {Instância única do objeto!}
      Class function GetInstancia: TGeraLog; static;
      {Método responsável por instanciar o objeto singleton!}
    public
      procedure AfterConstruction; override;
      procedure BeforeDestruction; override;
      procedure GeraLog(Const AReferencia: String; Const AData: TDateTime; Const ATextoLog: String);
      {AReferencia..: Referência à Thread chamadora.}
      {AData........: Data e Hora da geração do LOG.}
      {ATextoLog....: Texto a ser escrito no arquivo de LOG.}
      function TryGeraLog(Const AReferencia: String; Const ATextoLog: String): Boolean;
      function TryGravaJSon(const AReferencia: String; const AData: TDateTime; const ATextoLog: String): Boolean;

      {Método que TENTA gerar uma nova linha de LOG!}
      {AReferencia..: Referência à Thread chamadora.}
      {AData........: Data e Hora da geração do LOG.}
      {ATextoLog....: Texto a ser escrito no arquivo de LOG.}
      Class property Instancia: TGeraLog read GetInstancia;
      {Referência à instância singleton!}
  end;

implementation

{ TGeraLog }

procedure TGeraLog.AfterConstruction;
begin
  inherited;
  DeleteFile(Self.FArquivoLog);
  Self.FCritical := TCriticalSection.Create;
end;

procedure TGeraLog.BeforeDestruction;
begin
  inherited;
  Self.FCritical.Free;
end;

procedure TGeraLog.GeraLog(const AReferencia: string; const AData: TDateTime; const ATextoLog: string);
var
  _arquivo   : TextFile;
  sNovaLinha : String;
begin
  sNovaLinha := Format('%s|%s|%s', [AReferencia, DateTimeToStr(AData), ATextoLog]);

  {Entra na seção crítica!}
  Self.FCritical.Enter;
  try
    AssignFile(_arquivo, Self.FArquivoLog);
    if (FileExists(Self.FArquivoLog)) then
    begin
      Append(_arquivo);
    end
    else
    begin
      Rewrite(_arquivo);
    end;

    Writeln(_arquivo, sNovaLinha);

    CloseFile(_arquivo);
  finally
    {Sai da seção crítica}
    Self.FCritical.Release;
  end;
end;

Class function TGeraLog.GetInstancia: TGeraLog;
begin
  if not(Assigned(FInstance)) then
    begin
      FInstance := TGeraLog.Create;
    end;

  Result := FInstance;
end;

function TGeraLog.TryGeraLog(const AReferencia: String; const ATextoLog: String): Boolean;
var
  _arquivo   : TextFile;
  strCaminho : string;
  sNovaLinha : String;
begin
  {$IFDEF Android}
    strCaminho := TPath.Combine(tpath.GetDocumentsPath, 'CuiabaSoftware');
  {$ELSE}
    strCaminho := TPath.Combine(ExtractFilePath(ParamStr(0)), 'CuiabaSoftware');
  {$ENDIF}

  if not DirectoryExists(strCaminho) then
    CreateDir(strCaminho);

  if not DirectoryExists(TPath.Combine(strCaminho, 'log')) then
    CreateDir(TPath.Combine(strCaminho, 'Log'));

  strCaminho := TPath.Combine(strCaminho, 'Log');

  strCaminho := TPath.Combine(strCaminho, FormatDateTime('yyyymmdd', Date) + '_SERVIDOR-API.log');

  FArquivoLog := strCaminho;

  sNovaLinha := Format('[%s] - [%s] -> %s', [FormatDateTime('yyyymmdd', Date) + '-' + TimeToStr(Time), AReferencia, ATextoLog]);

  {Tenta entrar na seção crítica!}
  Result := Self.FCritical.TryEnter;
  if (Result = True) then
  begin
    try
      AssignFile(_arquivo, Self.FArquivoLog);
      if (FileExists(Self.FArquivoLog)) then
      begin
        Append(_arquivo);
      end
      else
      begin
        Rewrite(_arquivo);
      end;

      Writeln(_arquivo, sNovaLinha);

      CloseFile(_arquivo);
    finally
      {Sai da seção crítica}
      Self.FCritical.Release;
    end;
  end;
end;

function TGeraLog.TryGravaJSon(const AReferencia: String; const AData: TDateTime; const ATextoLog: String): Boolean;
  var
    arq   : TextFile;
    sNovaLinha : String;
begin
  sNovaLinha := Format('%s|%s|%s', [AReferencia, DateTimeToStr(AData), ATextoLog]);

  {Tenta entrar na seção crítica!}
  Result := Self.FCritical.TryEnter;

  if (Result = True) then
  begin
    try
      AssignFile(arq, Self.FArquivoLog);
      if (FileExists(Self.FArquivoLog)) then
      begin
        Append(arq);
      end
      else
      begin
        Rewrite(arq);
      end;

      Writeln(arq, sNovaLinha);

      CloseFile(arq);
    finally
      {Sai da seção crítica}
      Self.FCritical.Release;
    end;
  end;
end;

initialization

finalization

  TGeraLog.Instancia.Free;

end.
