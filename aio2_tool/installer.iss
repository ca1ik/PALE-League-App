; ============================================================
;  Natroff AIO - Inno Setup Installer Script
;  Kullanım: Inno Setup Compiler ile "Build > Compile" yap
;  Çıktı: Output\NatroffAIO_Setup.exe
; ============================================================

#define AppName      "Natroff AIO"
#define AppVersion   "6.0.0"
#define AppPublisher "PALE League"
#define AppExeName   "natroff_aio.exe"
#define SourceDir    "build\windows\x64\runner\Release"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir=Output
OutputBaseFilename=NatroffAIO_Setup
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes
LZMANumBlockThreads=4
WizardStyle=modern
PrivilegesRequired=admin
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
MinVersion=10.0

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Masaüstü kısayolu oluştur"; GroupDescription: "Ek ikonlar:"

[Files]
; Ana uygulama dosyaları (Release klasörünün tamamı)
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Kurulum başlamadan önce çalışan uygulamayı kapat
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Exec('taskkill', '/F /IM natroff_aio.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := True;
end;
