; JadoSoft Admin Installer
; Produced by JadoSoft

#define MyAppName "JadoSoft Admin"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "JadoSoft"
#define MyAppURL "https://jadosoft.com"
#define MyAppExeName "AdminPanel.exe"
#define MyAppId "{{A3F7B2E1-5C90-4D8A-B1E3-6F2D55C3ACED}}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
AppCopyright=Copyright (C) 2024 JadoSoft
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
DefaultDirName={autopf64}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=D:\Projects\Barick Phamacy\jadosoft-admin\installer
OutputBaseFilename={#MyAppName}_Setup_{#MyAppVersion}
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/max
SolidCompression=yes
LZMAUseSeparateProcess=yes
LZMANumBlockThreads=4
WizardStyle=modern
CloseApplications=yes
CloseApplicationsFilter=*.exe,*.dll
RestartApplications=no
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}
VersionInfoDescription=JadoSoft Admin - Pharmacy Management Platform
VersionInfoCopyright=Copyright (C) 2024 JadoSoft

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "startupicon"; Description: "Launch {#MyAppName} at Windows startup"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Debug\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{group}\Open App Data"; Filename: "{userdocs}\JadoSoftAdmin"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: startupicon

[Run]
Filename: "netsh"; Parameters: "advfirewall firewall delete rule name=""JadoSoft Admin"""; Flags: runhidden waituntilterminated
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""JadoSoft Admin"" dir=out action=allow program=""{app}\{#MyAppExeName}"" enable=yes profile=any"; Flags: runhidden waituntilterminated
Filename: "netsh"; Parameters: "advfirewall firewall add rule name=""JadoSoft Admin"" dir=in action=allow program=""{app}\{#MyAppExeName}"" enable=yes profile=any"; Flags: runhidden waituntilterminated

; Launch app after install (normal user context, not admin)
Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent runasoriginaluser

[Code]
var
  ExistingDataFound: Boolean;
  ExistingDataPath:  String;

function InitializeSetup(): Boolean;
begin
  Result            := True;
  ExistingDataPath  := ExpandConstant('{userdocs}\JadoSoftAdmin');
  ExistingDataFound := DirExists(ExistingDataPath);

  if ExistingDataFound then
    MsgBox(
      'Existing JadoSoft Admin data detected.' + #13#10#13#10 +
      'Your pharmacy records and settings will be preserved.' + #13#10 +
      'Data location: ' + ExistingDataPath,
      mbInformation, MB_OK
    );
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
    if not DirExists(ExistingDataPath) then
      CreateDir(ExistingDataPath);

  if CurStep = ssPostInstall then
    MsgBox(
      'JadoSoft Admin installed successfully.' + #13#10#13#10 +
      'Your app data folder:' + #13#10 + ExistingDataPath,
      mbInformation, MB_OK
    );
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
begin
  if CurUninstallStep = usPostUninstall then
    if DirExists(ExistingDataPath) then
      if MsgBox(
        'Do you want to KEEP your JadoSoft Admin data?' + #13#10#13#10 +
        'Select YES to keep your data (recommended).' + #13#10 +
        'Select NO to permanently delete all app data.',
        mbConfirmation, MB_YESNO
      ) = IDNO then
        Exec(
          ExpandConstant('{cmd}'),
          '/c rmdir /s /q "' + ExistingDataPath + '"',
          '',
          SW_HIDE,
          ewWaitUntilTerminated,
          ResultCode
        );
end;

function InitializeUninstall(): Boolean;
begin
  Result := True;
end;
