{/* ***** BEGIN LICENSE BLOCK *****
* Version: MPL 1.1/GPL 2.0/LGPL 2.1
*
* The contents of this file are subject to the Mozilla Public License Version
* 1.1 (the "License"); you may not use this file except in compliance with
* the License. You may obtain a copy of the License at
* http://www.mozilla.org/MPL/
*
* Software distributed under the License is distributed on an "AS IS" basis,
* WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
* for the specific language governing rights and limitations under the
* License.
*
* Original author:
* - Pavel Cvrcek <jasnapaka@jasnapaka.com>
*
* Contributor(s):
*
* Alternatively, the contents of this file may be used under the terms of
* either of the GNU General Public License Version 2 or later (the "GPL"),
* or the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
* in which case the provisions of the GPL or the LGPL are applicable instead
* of those above. If you wish to allow use of your version of this file only
* under the terms of either the GPL or the LGPL, and not to allow others to
* use your version of this file under the terms of the MPL, indicate your
* decision by deleting the provisions above and replace them with the notice
* and other provisions required by the GPL or the LGPL. If you do not delete
* the provisions above, a recipient may use your version of this file under
* the terms of any one of the MPL, the GPL or the LGPL.
*
* ***** END LICENSE BLOCK ***** */}

unit funkce;

interface

uses Registry;

// provede se inicializace dialogu (krom hlavniho)
procedure Dialogy_init;
// vytvori novy profil Mozilly
procedure Create_profil;
// provede detekci aplikaci, ktere se mohou zalohovat
procedure DetekceKomponent;
// provede detekci profilu Mozilly
procedure DetekceProfilu;
// detekuje potrebne soubory pro funkci programu
procedure DetekceSouboru;
// detekuje soucasti, ktere lze zalohovat
procedure DetekceSoucasti;
// detekuje soucasti, ktere lze obnovit
procedure DetekceSoucastiSoubor;
// zjisti, jaky program byl vybran
procedure GetTypeProgram;
// vyber Open ci Save Dialogu
procedure ChooseDialog;
// detekce spustene Mozilly
function IsRunning: boolean;
// detekuje, zda-li se jedna o soubor se zalohou
function IsValidFile (Soubor: string):boolean;
// is backup for selected app?
function IsValidFileForApp (Filename: String; ProgramId: byte):boolean;
// "vynuluje" checkboxy
procedure NastavCheckboxy;
// nastavi vystupni soubor
procedure NastavSoubor;
// overi a zvalidni cestu k souboru
function Over_platnost (Cesta: string):string;
// overi platnost profilu
function Over_profil (Adresar: string):boolean;
// overi, zda-li byl nalezen nejaky program
procedure Over_program;
// overi, zda-li je vybrana aplikace na provedeni zalohy
procedure Over_vyber;
// overi, zda-li je vybran nejaky profil
procedure Over_vyber_profilu;
// p�i obnovov�n� se dot�zat, zda p�epsat data v existuj�c�m profilu
function Prepsat_profil: boolean;
// select portable profile
procedure selectPortableProfile();
// ukonceni programu  - krizek na formulari
procedure Ukonceni_programu (var CanClose: boolean);
// zjisteni, zda-li se muze zacit se zalohovanim (resp. obnovou)
function Zacatek_zalohovani: boolean;
// oreze adresarovou cestu
function Zkraceny_adresar (S: string):string;

// temporary
procedure SearchProgram (Registr: TRegistry; Cesta: string; Klic: string; Typ: byte; Vstup: byte; Adresar: boolean);
procedure SearchDirectory (Registr: TRegistry; Cesta: string; Klic: string; Typ: byte);

implementation

uses Classes, controls, dialogs, forms, hlavni, chyby, input_dialog,
     WinUtils, ShellApi, StdCtrls, StrUtils, sysutils, windows,
     okna, zaloha, IniFiles, jp_registry, Config, ZipFactory, UnknowItem,
     FileCtrl, JPDialogs, Functions, CmdLine;


//******************************************************************************
// procedure Dialogy_init
//
// - provede jazykovou inicializaci dialogu (krom hlavniho)
//******************************************************************************

procedure Dialogy_init;
begin
  Form2.Caption:= Config.l10n.getL10nString ('TForm1', 'LANG_NEW_PROFIL');
  Form2.Label1.Caption:= Config.l10n.getL10nString ('TForm1', 'LANG_NEW_PROFIL_NAME');
  Form2.Label2.Caption:= Config.l10n.getL10nString ('TForm1', 'LANG_DIR_DEFAULT');
  Form2.Button1.Caption:= Config.l10n.getL10nString ('TForm1', 'LANG_BUTTON_OK');
  Form2.Button2.Caption:= Config.l10n.getL10nString ('TForm1', 'LANG_BUTTON_2');
  Form2.Button3.Caption:= Config.l10n.getL10nString ('TForm1', 'LANG_CHOOSE');
  Form2.GroupBox1.Caption := Config.l10n.getL10nString ('TForm1', 'LANG_LOCATION');
  Form2.Label1.Font.Name:= Config.l10n.getL10nString ('Common', 'Font');
  Form2.Edit1.Text:= '';
  Form2.Label2.Hint:= '';
  Form2.Potvrzeno:= false;
  Form2.Font.Charset:= Config.l10n.getDefaultCharset();
end;

//******************************************************************************
// procedure Create_profil
//
// - vytvori novy profil Mozilly
//******************************************************************************

procedure Create_profil;
var Retezec: string;
    Vysledek: boolean;
    ExeName: String;
begin
  // Vytvoreni noveho profilu
  Dialogy_init;                 // inicializace dialogu
//  Profil_okno;


  Form2.ShowModal;

  Retezec:= LowerCase (Form2.Edit1.Text);
  if Form2.Potvrzeno = true then
    begin
      Vysledek:= true;

      if Pos ('\', Retezec) > 0 then Vysledek:= false;
      if Pos ('/', Retezec) > 0 then Vysledek:= false;
      if Pos ('!', Retezec) > 0 then Vysledek:= false;
      if Pos ('?', Retezec) > 0 then Vysledek:= false;
      if Pos ('<', Retezec) > 0 then Vysledek:= false;
      if Pos ('>', Retezec) > 0 then Vysledek:= false;
      if Pos ('*', Retezec) > 0 then Vysledek:= false;
      if Pos (':', Retezec) > 0 then Vysledek:= false;
      if Pos ('"', Retezec) > 0 then Vysledek:= false;

      if (Vysledek = true) and (Length (Retezec) > 0) then  // byl zadan nejaky profil
        begin
          if not DirectoryExists (Form1.Slozka_data + 'Profiles\' + Retezec) then
            begin
              case Form1.Typ_programu of
                1: ExeName:= 'seamonkey.exe';
                2: ExeName:= 'firefox.exe';
                3: ExeName:= 'thunderbird.exe';
                4: ExeName:= 'sunbird.exe';
                5: ExeName:= 'flock.exe';
                6: ExeName:= 'netscape.exe';
                7: ExeName:= 'messenger.exe';
                8: ExeName:= 'spicebird.exe';
                9: ExeName:= 'songbird.exe';
                11: ExeName:= 'postbox.exe';
                12: ExeName:= 'wyzo.exe';
              end;
              
              if Length (Form2.Label2.Hint) = 0 then
                begin
                  ShellExecute (Application.handle, 'open', Pchar (Programy[Form1.Typ_programu].Cesta + '\' + ExeName),
                       Pchar ('-CreateProfile ' + Retezec), Nil, SW_SHOWNORMAL );
                end
              else
                begin
                  ShellExecute (Application.handle, 'open', Pchar (Programy[Form1.Typ_programu].Cesta + '\' + ExeName),
                        Pchar ('-CreateProfile "' + Retezec + ' ' + Form2.Label2.Hint + '"'), Nil, SW_SHOWNORMAL );
                end;
            end
         else Application.MessageBox (pchar (Config.l10n.getL10nString ('TForm1', 'LANG_PROFIL_EXIST')),
                      pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_OK + MB_ICONWARNING);
        end
      else Application.MessageBox (pchar (Config.l10n.getL10nString ('TForm1', 'LANG_NO_NAME')),
                pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_OK + MB_ICONWARNING);
    end;
end;


//******************************************************************************
// procedure ProfilesDirectory
//
// - vyhleda slozku s profilama, pokud existuje
//
// Vstup: Typ - typ aplikace
//        Vstup - ???
//******************************************************************************

procedure ProfilesDirectory (typ: integer; vstup: byte);
begin
  case Typ of
    1: begin
         if ((DirectoryExists (GetSpecialDir (11) + '\Mozilla\Profiles') = true) or
              (DirectoryExists (GetSpecialDir (11) + '\Mozilla\SeaMonkey\Profiles') = true) or
         ((DirectoryExists (GetWindowsDir + '\Mozilla\Profiles') = true))) and (Programy[1].Nalezen = false)
            then Form1.ListBox1.Items.Add('SeaMonkey/Mozilla ' + Config.l10n.getL10nString ('TForm1', 'LANG_ONLYPROFIL'));
       end;
    2: if ((DirectoryExists (GetSpecialDir (11) + '\Mozilla\Firefox\Profiles') = true) or (DirectoryExists (GetSpecialDir (11) + '\Firefox\Profiles') = true) or ((DirectoryExists (GetSpecialDir (11) + '\Phoenix\Profiles') = true)) or ((DirectoryExists (GetWindowsDir + '\Phoenix\Profiles') = true))) and (Programy[2].Nalezen = false) and (Vstup = 0)
       then Form1.ListBox1.Items.Add('Mozilla Firefox ' + Config.l10n.getL10nString ('TForm1', 'LANG_ONLYPROFIL'));
    3: if ((DirectoryExists (GetSpecialDir (11) + '\Thunderbird\Profiles') = true) or ((DirectoryExists (GetWindowsDir + '\Thunderbird\Profiles') = true))) and (Programy[3].Nalezen = false)
       then Form1.ListBox1.Items.Add('Mozilla Thunderbird ' + Config.l10n.getL10nString ('TForm1', 'LANG_ONLYPROFIL'));

    4: if ((DirectoryExists (GetSpecialDir (11) + '\Mozilla\Sunbird\Profiles') = true) or ((DirectoryExists (GetWindowsDir + '\Sunbird\Profiles') = true))) and (Programy[4].Nalezen = false)
       then Form1.ListBox1.Items.Add('Mozilla Sunbird ' + Config.l10n.getL10nString ('TForm1', 'LANG_ONLYPROFIL'));
    5: if ((DirectoryExists (GetSpecialDir (11) + '\Flock\Browser\Profiles') = true)) and (Programy[5].Nalezen = false)
       then Form1.ListBox1.Items.Add('Flock ' + Config.l10n.getL10nString ('TForm1', 'LANG_ONLYPROFIL'));
    6: if ((DirectoryExists (GetSpecialDir (11) + '\Netscape\Navigator\Profiles') = true)) and (Programy[6].Nalezen = false)
       then Form1.ListBox1.Items.Add('Netscape ' + Config.l10n.getL10nString ('TForm1', 'LANG_ONLYPROFIL'));
    7: if ((DirectoryExists (GetSpecialDir (11) + '\Netscape\Messenger\Profiles') = true)) and (Programy[7].Nalezen = false)
       then Form1.ListBox1.Items.Add('Netscape Messenger ' + Config.l10n.getL10nString ('TForm1', 'LANG_ONLYPROFIL'));
    8: if ((DirectoryExists (GetSpecialDir (11) + '\Spicebird\Profiles') = true)) and (Programy[8].Nalezen = false)
       then Form1.ListBox1.Items.Add('Spicebird ' + Config.l10n.getL10nString ('TForm1', 'LANG_ONLYPROFIL'));
    9: if ((DirectoryExists (GetSpecialDir (11) + '\Songbird2\Profiles') = true)) and (Programy[8].Nalezen = false)
       then Form1.ListBox1.Items.Add('Songbird ' + Config.l10n.getL10nString ('TForm1', 'LANG_ONLYPROFIL'));

    11: if ((DirectoryExists (GetSpecialDir (11) + '\PostBox\Profiles') = true)) and (Programy[11].Nalezen = false)
       then Form1.ListBox1.Items.Add('PostBox ' + Config.l10n.getL10nString ('TForm1', 'LANG_ONLYPROFIL'));
    12: if ((DirectoryExists (GetSpecialDir (11) + '\Radical Software Ltd\Wyzo\Profiles\') = true)) and (Programy[12].Nalezen = false)
       then Form1.ListBox1.Items.Add('Wyzo ' + Config.l10n.getL10nString ('TForm1', 'LANG_ONLYPROFIL'));
  end;
end;


//******************************************************************************
// procedure SearchProgram
//
// - vyhleda program v registru (pokud tam je)
//
// Vstup: Cesta - cesta v registrech
//        Klic - klic, ktery se prohledava
//        Typ - cislo aplikace, ktera se prohledava
//        Vstup - 
//        Program - typ programu
//        Adresar - ma se hleat i adresar s profilem?
//******************************************************************************

procedure SearchProgram (Registr: TRegistry; Cesta: string; Klic: string; Typ: byte; Vstup: byte; Adresar: boolean);
var ApplicationDetected: boolean;
begin
  ApplicationDetected:= false;
  if Registr.OpenKey(Cesta, false) then
    begin
      if Registr.ValueExists (Klic)then
        begin
          Programy[Typ].Nalezen:= true;
          Programy[Typ].Verze:= Registr.ReadString (Klic);

          case Typ of
            1: Form1.ListBox1.Items.Add ('SeaMonkey' + Programy[Typ].Verze);
            2: Form1.ListBox1.Items.Add ('Mozilla Firefox '+ Programy[Typ].Verze);
            3: Form1.ListBox1.Items.Add ('Mozilla Thunderbird '+ Programy[Typ].Verze);
            4: Form1.ListBox1.Items.Add ('Mozilla Sunbird '+ Programy[Typ].Verze);
            5: Form1.ListBox1.Items.Add ('Flock '+ Programy[Typ].Verze);
            6: Form1.ListBox1.Items.Add ('Netscape '+ Programy[Typ].Verze);
            7: Form1.ListBox1.Items.Add ('Netscape Messenger '+ Programy[Typ].Verze);
            8: Form1.ListBox1.Items.Add ('Spicebird '+ Programy[Typ].Verze);
            9: Form1.ListBox1.Items.Add ('Songbird '+ Programy[Typ].Verze);
            11: Form1.ListBox1.Items.Add ('PostBox '+ Programy[Typ].Verze);
            12: Form1.ListBox1.Items.Add ('Wyzo '+ Programy[Typ].Verze);
          end;

          ApplicationDetected:= true;
        end
    end;

  //** nalezeni profilu odinstalovane aplikace
  if (Adresar) and (ApplicationDetected = false) then ProfilesDirectory (typ, vstup);

  Registr.CloseKey;
end;


//******************************************************************************
// procedure SearchDirectory
//
// - vyhleda cestu k zadanemu programu
//
// Vstup: Cesta - cesta v registrech
//        Klic - klic, ktery se prohledava
//        Program - typ programu
//******************************************************************************

procedure SearchDirectory (Registr: TRegistry; Cesta: string; Klic: string; Typ: byte);
begin
  if Registr.OpenKey(Cesta, false) then
    begin
      if Registr.ValueExists(Klic) then
        begin
          Programy[Typ].Cesta:= Registr.ReadString (Klic);
        end;
    end;
  Registr.CloseKey;
end;


//******************************************************************************
// procedure DetekceEmails
//
// - detekce emailovych schranek
//
// Vstup: Slozka_data - cesta ke konfiguracnimu souboru
//******************************************************************************

function DetectEmails (Slozka_data: string):boolean;
var F: textfile;
    Nalezeno: boolean;
    S: string;
begin
  Nalezeno:= false;
  AssignFile (F, Slozka_Data + 'prefs.js');
  Reset (F);
  Repeat
    Readln (F, S);
    if Pos ('user_pref("mail.identity.', S) > 0 then Nalezeno:= true;
    if (Pos ('user_pref("mail.server.server', S) > 0) and (Pos ('rss', S) > 0) then Nalezeno:= true;
  Until Eof (F) or (Nalezeno = true);
  CloseFile (F);

  Result:= Nalezeno;
end;


//******************************************************************************
// procedure DetekceKomponent
//
// - detekce komponent, ktere jsou vhodne k zalohovani (programy)
//******************************************************************************

procedure DetekceKomponent;
var Registr: TRegistry;
begin
  // vynulovani cest
  Programy[1].Cesta:= '';
  Programy[2].Cesta:= '';
  Programy[3].Cesta:= '';
  Programy[4].Cesta:= '';
  Programy[5].Cesta:= '';
  Programy[6].Cesta:= '';
  Programy[7].Cesta:= '';
  Programy[8].Cesta:= '';
  Programy[9].Cesta:= '';
  Programy[10].Cesta:= '';  
  Programy[11].Cesta:= '';
  Programy[12].Cesta:= '';

  Form1.Typ_programu:= 0;
  Form1.Slozka_data:= '';

  // otevreni registru
  Registr:= TRegistry.Create;
  Registr.Access:= KEY_READ;
  Registr.RootKey:= HKEY_LOCAL_MACHINE;

  // ** Detekce SeaMonkey / Mozilly
  Form1.ListBox1.Clear;
  SearchProgram (Registr, 'SOFTWARE\mozilla\SeaMonkey\', 'CurrentVersion', 1, 0, false);
  SearchDirectory (Registr, 'SOFTWARE\mozilla\SeaMonkey\' + Programy[1].Verze + '\Main', 'Install Directory', 1);

  if Length (Programy[1].Cesta) = 0 then
    begin
      SearchProgram (Registr, 'SOFTWARE\mozilla.org\SeaMonkey', 'CurrentVersion', 1, 0, true);
      SearchDirectory (Registr, 'SOFTWARE\mozilla.org\SeaMonkey\' + Programy[1].Verze + '\Main', 'Install Directory', 1);
    end;

  // ** Detekce Mozilly Firefox
  SearchProgram (Registr, 'SOFTWARE\mozilla\Mozilla Firefox', 'CurrentVersion', 2, 1, false);
  SearchDirectory (Registr, 'SOFTWARE\mozilla\Mozilla Firefox\'+ Programy[2].Verze + '\Main', 'Install Directory', 2);

  // Detekce starsi verze
  if Length (Programy[2].Cesta) = 0 then
    begin
      SearchProgram (Registr, 'SOFTWARE\mozilla.org\Mozilla Firefox', 'CurrentVersion', 2, 0, true);
      SearchDirectory (Registr, 'SOFTWARE\mozilla.org\Mozilla Firefox\'+ Programy[2].Verze + '\Main', 'Install Directory', 2);
    end;

  // ** Detekce Mozilly Thunderbird
  SearchProgram (Registr, 'SOFTWARE\mozilla\Mozilla Thunderbird', 'CurrentVersion', 3, 0, false);
  SearchDirectory (Registr, 'SOFTWARE\mozilla\Mozilla Thunderbird\' + Programy[3].Verze + '\Main', 'Install Directory', 3);

  if Length (Programy[3].Cesta) = 0 then
    begin
      SearchProgram (Registr, 'SOFTWARE\mozilla.org\Mozilla Thunderbird', 'CurrentVersion', 3, 0, true);
      SearchDirectory (Registr, 'SOFTWARE\mozilla.org\Mozilla Thunderbird\' + Programy[3].Verze + '\Main', 'Install Directory', 3);
    end;

  // ** Detekce Mozilly Sunbird
  SearchProgram (Registr, 'SOFTWARE\mozilla\Mozilla Sunbird', 'CurrentVersion', 4, 0, true);
  SearchDirectory (Registr, 'SOFTWARE\mozilla\Mozilla Sunbird\'+ Programy[4].Verze + '\Main', 'Install Directory', 4);

  // ** Detekce Flock
  SearchProgram (Registr, 'SOFTWARE\Flock', 'CurrentVersion', 5, 0, true);
  SearchDirectory (Registr, 'SOFTWARE\Flock\Flock\'+ Programy[5].Verze + '\Main', 'Install Directory', 5);

  // ** Detekce Netscape 9
  SearchProgram (Registr, 'SOFTWARE\mozilla\Netscape Navigator', 'CurrentVersion', 6, 0, true);
  SearchDirectory (Registr, 'SOFTWARE\mozilla\Netscape Navigator\'+ Programy[6].Verze + '\Main', 'Install Directory', 6);

  // ** Detekce Netscape Messenger 9
  SearchProgram (Registr, 'SOFTWARE\mozilla\Netscape Messenger', 'CurrentVersion', 7, 0, true);
  SearchDirectory (Registr, 'SOFTWARE\mozilla\Netscape Messenger\'+ Programy[7].Verze + '\Main', 'Install Directory', 7);

  // ** Spicebird detection
  SearchProgram (Registr, 'SOFTWARE\mozilla\Spicebird', 'CurrentVersion', 8, 0, true);
  SearchDirectory (Registr, 'SOFTWARE\mozilla\Spicebird\'+ Programy[8].Verze + '\Main', 'Install Directory', 8);

  // ** Songbird detection
  SearchProgram (Registr, 'SOFTWARE\mozilla\Spicebird', 'CurrentVersion', 9, 0, true);
  SearchDirectory (Registr, 'SOFTWARE\mozilla\Spicebird\'+ Programy[9].Verze + '\Main', 'Install Directory', 9);

  // ** PostBox detection
  SearchProgram (Registr, 'SOFTWARE\PostBox\PostBox', 'CurrentVersion', 11, 0, true);
  SearchDirectory (Registr, 'SOFTWARE\PostBox\PostBox\'+ Programy[11].Verze + '\Main', 'Install Directory', 11);

  // ** Wyzo detection
  SearchProgram (Registr, 'SOFTWARE\mozilla\Wyzo', 'CurrentVersion', 12, 0, true);
  SearchDirectory (Registr, 'SOFTWARE\mozilla\Wyzo\'+ Programy[12].Verze + '\Main', 'Install Directory', 12);

  // Portable Applications
  Form1.ListBox1.Items.Add (Config.l10n.getL10nString('MozBackup14', 'LANG_PORTABLE_APPS'));

  // ukonceni prace s registry
  Registr.CloseKey;
  Registr.Destroy;
end;

//******************************************************************************
// function ReadString
//
// - nacte retezec z binarniho souboru
//******************************************************************************

function ReadString(FStream: TFileStream; dwPos, dwLen: DWord): String;
var
  sTemp: String;
  intA: Integer;
begin
  Result := '';
  SetLength(sTemp, dwLen);
  FStream.Seek(dwPos, soFromBeginning);
  FStream.Read(PChar(sTemp)^, dwLen);

  for intA := 1 to dwLen do begin
    if sTemp[intA] <> #0 then
      Result := Result + sTemp[intA];
  end;
end;

//******************************************************************************
// function GetProfiles
//
// - nacte data z registry.dat
//
// Vstup: Cesta - cesta k souboru
//******************************************************************************

function GetProfiles (Cesta: string): boolean;
var FStream: TFileStream;
    I, J, K, L: integer;
    Jmeno, Location, S: string;
    P, Posledni: TProfily;
    IsRelative: byte;
    Path: string;
    ini:TIniFile;
    ProfileExist: boolean;
    Nacteno: boolean;
begin
  Result:= true;
  Form1.Prvni_profil:= nil;
  Posledni:= nil;
  Nacteno:= false;

  // nalezeni novejsiho typu souboru s profily
  if FileExists (Cesta + 'profiles.ini') then
    begin
      i:= 0; ProfileExist:= true; Form1.Prvni_profil:= nil; Posledni:= nil;
      // nacteni INI souboru
      ini:= TIniFile.Create(Cesta + 'profiles.ini');

      Repeat
        S:= 'Profile' + IntToStr (I);

        if (ini.SectionExists(s)) then
          begin
            if (ini.ValueExists(S, 'name')) and (ini.ValueExists(S, 'path')) then
              begin
                New (P);
                P^.Jmeno:= Utf8ToAnsi(ini.ReadString (S, 'name', ''));
                IsRelative:= ini.ReadInteger(S, 'IsRelative', 0);
                Path:= Utf8ToAnsi (ini.ReadString (S, 'path', ''));
                if IsRelative = 0 then P^.Cesta:= Path
                else
                  begin
                    // upravi se cesta podle OS
                    P^.Cesta:= Cesta + StringReplace (Path, '/', '\', [rfReplaceAll]);
                  end;

                P^.Dalsi:= nil;

                if Posledni <> nil then Posledni.Dalsi:= P;
                Posledni:= P;
                if Form1.Prvni_profil = nil then Form1.Prvni_profil:= P;
                Form1.ListBox2.Items.Add(P^.Jmeno);
              end;
          end
        else ProfileExist:= false;
        I:= i + 1;
      Until ProfileExist = false;

      ini.Free;
      Nacteno:= true;
    end;


  // nacteni registroveho souboru
  if (FileExists (Cesta + 'registry.dat')) and (Nacteno = false) then
    begin
      FStream:= TFileStream.Create(Cesta + 'registry.dat', fmOpenRead);

      FStream.Seek(12,soFromBeginning);                                         // 1
      FStream.Read(i, SizeOf (i));;

      // nacteni "/"
      FStream.Seek(I + 16, soFromBeginning);                                    // 2
      FStream.Read(i, SizeOf (i));

      // nasleduje presun na key "users"                                        // 3
      FStream.Seek(I + 12, soFromBeginning);
      FStream.Read(i, SizeOf (i));

      // nasleduje presun na sekci "common"                                     // 4
      FStream.Seek(I + 16, soFromBeginning);
      FStream.Read(i, SizeOf (i));

      // nasleduje presun na sekci "CurrentProfile"                             
      FStream.Seek(I, soFromBeginning);
      FStream.Read(i, SizeOf (i));

      FStream.Seek(I+16, soFromBeginning);                                      // 5
      FStream.Read(i, SizeOf (i));

      // ** I nyni ukazuje na prvni profil
      if I <> 0 then
        begin
          While I<>0 do
            begin
              J:= I;

              FStream.Seek(I+4, soFromBeginning);
              FStream.Read(i, SizeOf (i));
              K:= I;

              S:= ReadString (FStream, K, J-K);
              Jmeno:= Utf8ToAnsi(S);

              // odkaz na konec retezce
              FStream.Seek(J+20,soFromBeginning);
              FStream.Read(i, SizeOf (i));

              Location:= '';
              Repeat
                Location:= Location + ReadString (FStream, I-1, 1);
                I:= I-1;
                FStream.Seek(I,soFromBeginning);
                FStream.Read(K, SizeOf (K));
              Until J = K;
             // Location:= Trim (Location);

              New (P);
              P^.Jmeno:= Utf8ToAnsi(S);

              S:='';
              for I:=Length(Location) downto 1 do S:=S+Location[i];

              // prekopane mazani retezce ze souboru
              // puvodni: Delete (S, 1, 11);
              L:= Pos ('directory', S);
              if (L = 0) then Delete (S, 1, 11)
              else
                begin
                  Delete (S, 1, L-1);
                  Delete (S, 1, 9);
                end;


              P^.Cesta:= Utf8ToAnsi(S);
              
              if (Pos ('.slt', Utf8ToAnsi(S)) > 0) then Form1.ListBox2.Items.Add(Jmeno);
              P^.Dalsi:= nil;

              if Posledni <> nil then Posledni^.Dalsi:= P;

              Posledni:= P;
              if Form1.Prvni_profil = nil then Form1.Prvni_profil:= P;

              // odkaz na dalsi?
              FStream.Seek(J+12,soFromBeginning);
              FStream.Read(i, SizeOf (i));
            end;
        end
      else Result:= false;

      FStream.Destroy;
    end;
end;


//******************************************************************************
// procedure DetekceProfilu
//
// - detekce profilu Mozilly
//******************************************************************************

procedure DetekceProfilu;
begin
  // vymazani listboxu pro profily
  Form1.ListBox2.Clear;

  // urceni programu
  case (Form1.Typ_programu) of
    // Zde se detekuj� profily SeaMonkey 2.0, 1.x se z�lohuje n�e
    1: Form1.Slozka_data:= GetSpecialDir (11) + '\Mozilla\SeaMonkey\';
    2: Form1.Slozka_data:= GetSpecialDir (11) + '\Mozilla\Firefox\';
    3: Form1.Slozka_data:= GetSpecialDir (11) + '\Thunderbird\';
    4: Form1.Slozka_data:= GetSpecialDir (11) + '\Mozilla\Sunbird\';
    5: Form1.Slozka_data:= GetSpecialDir (11) + '\Flock\Browser\';
    6: Form1.Slozka_data:= GetSpecialDir (11) + '\Netscape\Navigator\';
    7: Form1.Slozka_data:= GetSpecialDir (11) + '\Netscape\Messenger\';
    8: Form1.Slozka_data:= GetSpecialDir (11) + '\Spicebird\';
    9: Form1.Slozka_data:= GetSpecialDir (11) + '\Songbird2\';
    11: Form1.Slozka_data:= GetSpecialDir (11) + '\PostBox\';
    12: Form1.Slozka_data:= GetSpecialDir (11) + '\Radical Software Ltd\Wyzo\';
  end;

  // nacteni obsahu souboru s profily
  GetProfiles (Form1.Slozka_data);

  // Detekce profil� SeaMonkey 1.x
  if (Form1.Typ_programu = 1) and (Form1.Prvni_profil = nil) then
    begin
      GetProfiles (GetSpecialDir (11) + '\Mozilla\');
    end;

  // Load portable profile
  if (Length (Form1.PortableDirectory) > 0) then
    begin
      Form1.ListBox2.Items.Add(Config.l10n.getL10nString ('MozBackup14', 'LANG_PORTABLE_PROFILE'));
    end;
end;

//******************************************************************************
// procedure DetekceSouboru
//
// - detekuje soubory, ktere jsou potrebne pro funkci programu
//******************************************************************************
procedure DetekceSouboru;
var Cesta: string;
    Nenalezeno: boolean;
begin
  Nenalezeno:= false;
  Cesta:= ExtractFilePath (Application.ExeName); 

  if FileExists (Cesta + 'dll\DelZip190.dll') = false then Nenalezeno:= true;
  if FileExists (Cesta + '\Default.lng') = false then Nenalezeno:= true;
  if FileExists (Cesta + '\Backup.ini') = false then Nenalezeno:= true;
  if FileExists (Cesta + '\Profilefiles.txt') = false then Nenalezeno:= true;  

  if Nenalezeno = true then
    begin
      Application.MessageBox (pchar (Config.l10n.getL10nString ('TForm1', 'LANG_NO_FILES')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_OK + MB_ICONWARNING);
      Application.Terminate;
    end;
end;

//******************************************************************************
// procedure DetekceSoucasti
//
// - detekuje soucasti, ktere lze zalohovat
//******************************************************************************

procedure DetekceSoucasti;
var Slozka_data1: string;
    Vyhledej: TSearchRec;
    Pozice: integer;
    Nalezeno: boolean; 
    P: TProfily;
begin
    try
      if not IsRunCommandLineVersion() then
        begin
          Pozice:= Form1.ListBox2.ItemIndex;
          P:= Form1.Prvni_profil;

          Nalezeno:= false;
          if (P <> nil) then
            begin
              Repeat
                if P^.Jmeno = Form1.ListBox2.Items.Strings[Pozice] then Nalezeno:= true
                else P:= P^.Dalsi;
              Until (Nalezeno = true) or (P = nil);
             end;

          // Profil nebyl nalezen, nejedna se o externi?
          if (P = nil) then
            begin
              if (Length (Form1.PortableDirectory) = 0) then
                begin
                  raise Exception.Create('Exception');
                end
              else
                begin
                  Slozka_data1:= Form1.PortableDirectory + '\';
                  Form1.Slozka_data:= Slozka_data1;
                end;
            end
           else
            begin
              Slozka_data1:= Trim (P^.Cesta) + '\';
              Form1.Slozka_data:= Slozka_data1;
            end;
        end
      else
        begin
          Slozka_data1:= GetProfileLocation();
        end;

      if (FileExists (Slozka_data1 + 'prefs.js') = false) then raise Exception.Create('Exception');

      // ** nyni se vyhledaji soucasti
      // obecna konfigurace

      if FileExists (Slozka_data1 + 'prefs.js') then Form1.CheckBox1.Checked:= true
      else Form1.CheckBox1.Enabled:= false;

      // ****** novy typ detekce
      if DetectEmails (Slozka_data1) then Form1.CheckBox2.Checked:= true
      else Form1.CheckBox2.Enabled:= false; 

      // kontakty
      if FileExists (Slozka_data1 + 'abook.mab') then Form1.CheckBox3.Checked:= true
      else Form1.CheckBox3.Enabled:= false;

      // bookmarky
      if FileExists (Slozka_data1 + 'bookmarks.html') or FileExists (Slozka_data1 + 'bookmarks_history.sqlite')
      or FileExists (Slozka_data1 + 'places.sqlite') then Form1.CheckBox4.Checked:= true
      else Form1.CheckBox4.Enabled:= false;

      // historie
      if FileExists (Slozka_data1 + 'history.dat') or FileExists (Slozka_data1 + 'bookmarks_history.sqlite')
      or FileExists (Slozka_data1 + 'places.sqlite') then Form1.CheckBox5.Checked:= true
      else Form1.CheckBox5.Enabled:= false;

      // panely
      if FileExists (Slozka_data1 + 'panels.rdf') then Form1.CheckBox6.Checked:= true
      else Form1.CheckBox6.Enabled:= false;

      // uzivatelske styly
      if FileExists (Slozka_data1 + 'chrome' + '\' + 'userChrome.css') or FileExists (Slozka_data1 + 'chrome' + '\' + 'userContent.css')
      then Form1.CheckBox8.Checked:= true else Form1.CheckBox8.Enabled:= false;

      // ulozena hesla
      if (FindFirst (Slozka_data1 + '*.s', faAnyFile, Vyhledej) = 0) or (FileExists (Slozka_data1 + 'signons.txt') or
      (FileExists (Slozka_data1 + 'signons2.txt')) or (FileExists (Slozka_data1 + 'signons3.txt')) or
      (FileExists (Slozka_data1 + 'signons4.txt')) or (FileExists (Slozka_data1 + 'signons.sqlite')))
      then Form1.CheckBox9.Checked:= true
      else Form1.CheckBox9.Enabled:= false;
      SysUtils.FindClose(Vyhledej);

      // cookies
      if (FileExists (Slozka_data1 + 'cookies.txt')) or (FileExists (Slozka_data1 + 'cookies.sqlite'))
      then Form1.CheckBox10.Checked:= true
      else Form1.CheckBox10.Enabled:= false;

      // doplnene formulare
      if (FindFirst (Slozka_data1 + '*.w', faAnyFile, Vyhledej) = 0) or (FileExists (Slozka_data1 + 'formhistory.dat')
      or FileExists (Slozka_data1 + 'formhistory.sqlite')) then Form1.CheckBox11.Checked:= true
      else Form1.CheckBox11.Enabled:= false;
      SysUtils.FindClose(Vyhledej);

      // stahovani souboru
      if (FileExists (Slozka_data1 + 'downloads.rdf')) or (FileExists (Slozka_data1 + 'downloads.sqlite'))
      then Form1.CheckBox12.Checked:= true
      else Form1.CheckBox12.Enabled:= false;

      // certifikatu
      if FileExists (Slozka_data1 + 'key3.db') or FileExists (Slozka_data1 + 'cert7.db') or
         FileExists (Slozka_data1 + 'cert8.db') or FileExists (Slozka_data1 + 'secmod.db')
      then Form1.CheckBox13.Checked:= true else Form1.CheckBox13.Enabled:= false;

      // rozsireni
      if DirectoryExists (Slozka_data1 + 'Extensions') then
        begin
          Form1.CheckBox14.ShowHint:= false;
          Form1.CheckBox14.Enabled:= true;
          Form1.CheckBox14.Checked:= true;
        end
      else
        begin
          Form1.CheckBox14.ShowHint:= true;
          Form1.CheckBox14.Enabled:= false;
          Form1.CheckBox14.Checked:= false;
        end;

      // diskova pamet
      if DirectoryExists (Slozka_data1 + 'Cache') then
        begin
          Form1.CheckBox15.Checked:= false;
          Form1.CheckBox15.Enabled:= true;
        end
      else Form1.CheckBox15.Enabled:= false;

      // pouze e-maily
      if Form1.CheckBox2.Enabled = false then Form1.CheckBox7.Enabled:= false;

  except
      // uzivatelsky profil je poskozen
      Application.MessageBox (pchar (Config.l10n.getL10nString ('TForm1', 'LANG_BAD_PROFIL')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_OK + MB_ICONWARNING);
      Halt (1);
    end;
end;


//******************************************************************************
// procedure DetekceSoucastiSoubor
//
// - detekuje soucasti, ktere obsahuje zalozni soubor
//******************************************************************************

procedure DetekceSoucastiSoubor;
var F: textfile;
    S, S1, S2: string;
    I: byte;
    zipFactory: TZipFactory;
    AppVersion: String;
begin
try
  // stary format souboru
  IsValidFile (Form1.Vyst_soubor);

  if Form1.Verze_souboru = 1 then AssignFile (F, Form1.Vyst_soubor);
  if Form1.Verze_souboru = 2 then
    begin
      zipFactory:= TZipFactory.Create(Form1.Vyst_soubor, '');
      zipFactory.extractFile('indexfile.txt', GetSpecialDir (2));
      zipFactory.Free;

      AssignFile (F, GetSpecialDir (2) + '\' + 'indexfile.txt');
    end;
  Reset (F);
  for I:= 1 to 2 do
    Readln (F, S);

  // get backup app version
  AppVersion:= SysUtils.StringReplace (S, 'Revize: ', '', [rfReplaceAll]);
  try
    Form1.BackupAppVersion:= StrToInt (AppVersion);
  except
    Form1.BackupAppVersion:= 0;
  end;

  for I:= 1 to 3 do
    Readln (F, S);

  Readln (F, S1);
  // nacteni externich cest
  Form1.Pocet_extern:= 0;
  Repeat
    Readln (F, S1);
    if S1 <> '****////\\\\****' then
      begin
        Form1.Extern_ucty[Form1.Pocet_extern]:= S1;
        Form1.Pocet_extern:= Form1.Pocet_extern + 1;
      end;     
  Until S1 = '****////\\\\****';

  // load unknow files in profile
  Form1.UnknowFiles:= TList.Create();
  Repeat
    Readln (F, S1);
    if (S1 <> '****////\\\\****') then
      begin
        Readln (F, S2);
        if (Pos ('dir', S1) = 1) then
          begin
            Form1.UnknowFiles.Add(TUnknowItem.Create (S2, true));
          end
        else
          begin
            Form1.UnknowFiles.Add(TUnknowItem.Create (S2, false));
          end;        
      end;
  Until (eof (F)) or (S1 = '****////\\\\****');

  CloseFile (F);
  S:= Trim (S);

  if S[1] = 'Y' then
    begin
      Form1.CheckBox1.Checked:= true;
      Form1.CheckBox1.Enabled:= true;
    end
  else
    begin
      Form1.CheckBox1.Checked:= false;
      Form1.CheckBox1.Enabled:= false;
    end;

  if S[2] = 'Y' then
    begin
      Form1.CheckBox2.Checked:= true;
      Form1.CheckBox2.Enabled:= true;
    end
  else
    begin
      Form1.CheckBox2.Checked:= false;
      Form1.CheckBox2.Enabled:= false;
    end;

  if S[3] = 'Y' then
    begin
      Form1.CheckBox3.Checked:= true;
      Form1.CheckBox3.Enabled:= true;
    end
  else
    begin
      Form1.CheckBox3.Checked:= false;
      Form1.CheckBox3.Enabled:= false;
    end;

  if S[4] = 'Y' then
    begin
      Form1.CheckBox4.Checked:= true;
      Form1.CheckBox4.Enabled:= true;
    end
  else
    begin
      Form1.CheckBox4.Checked:= false;
      Form1.CheckBox4.Enabled:= false;
    end;

  if S[5] = 'Y' then
    begin
      Form1.CheckBox5.Checked:= true;
      Form1.CheckBox5.Enabled:= true;
    end
  else
    begin
      Form1.CheckBox5.Checked:= false;
      Form1.CheckBox5.Enabled:= false;
    end;

  if S[6] = 'Y' then
    begin
      Form1.CheckBox6.Checked:= true;
      Form1.CheckBox6.Enabled:= true;
    end
  else
    begin
      Form1.CheckBox6.Checked:= false;
      Form1.CheckBox6.Enabled:= false;
    end;

  if S[7] = 'Y' then
    begin
      Form1.CheckBox8.Checked:= true;
      Form1.CheckBox8.Enabled:= true;
    end
  else
    begin
      Form1.CheckBox8.Checked:= false;
      Form1.CheckBox8.Enabled:= false;
    end;

  if S[8] = 'Y' then
    begin
      Form1.CheckBox9.Checked:= true;
      Form1.CheckBox9.Enabled:= true;
    end
  else
    begin
      Form1.CheckBox9.Checked:= false;
      Form1.CheckBox9.Enabled:= false;
    end;

  if S[9] = 'Y' then
    begin
      Form1.CheckBox10.Checked:= true;
      Form1.CheckBox10.Enabled:= true;
    end
  else
    begin
      Form1.CheckBox10.Checked:= false;
      Form1.CheckBox10.Enabled:= false;
    end;

  if S[10] = 'Y' then
    begin
      Form1.CheckBox11.Checked:= true;
      Form1.CheckBox11.Enabled:= true;
    end
  else
    begin
      Form1.CheckBox11.Checked:= false;
      Form1.CheckBox11.Enabled:= false;
    end;

  if S[11] = 'Y' then
    begin
      Form1.CheckBox12.Checked:= true;
      Form1.CheckBox12.Enabled:= true;
    end
  else
    begin
      Form1.CheckBox12.Checked:= false;
      Form1.CheckBox12.Enabled:= false;
    end;

  // certifikat - byl dodan pozdeji
  if (Length (S) > 11) and (S[12] = 'Y') then
    begin
      Form1.CheckBox13.Checked:= true;
      Form1.CheckBox13.Enabled:= true;
    end
  else
    begin
      Form1.CheckBox13.Checked:= false;
      Form1.CheckBox13.Enabled:= false;
    end;

  // rozsireni - bylo dodano pozdeji
  if (Length (S) > 12) and (S[13] = 'Y') then
    begin
      Form1.CheckBox14.Checked:= true;
      Form1.CheckBox14.Enabled:= true;
    end
  else
    begin
      Form1.CheckBox14.Checked:= false;
      Form1.CheckBox14.Enabled:= false;
    end;

  // cache - bylo dodano pozdeji
  if (Length (S) > 13) and (S[14] = 'Y') then
    begin
      Form1.CheckBox15.Checked:= true;
      Form1.CheckBox15.Enabled:= true;
    end
  else
    begin
      Form1.CheckBox15.Checked:= false;
      Form1.CheckBox15.Enabled:= false;
    end;

except
  on E:EInOutError do     // nastala nejaka vyjimka
    begin
      Application.MessageBox (pchar (Config.l10n.getL10nString ('TForm1', 'LANG_NOT_FOUND')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_OK + MB_ICONWARNING);
      Halt (1);
    end;
end;
end;


//******************************************************************************
// function GetDefaultFileName
//
// - vraci vychozi jmeno pro zalozni soubor
//******************************************************************************

function GetDefaultFilename: string;
var Cesta, Vystup: string;
    RegCesta: string;
    Adresar: string;
    Pozice: integer;
    S: string;
begin
  // ** Je prednastavena cesta k zaloze? (adresar)
  // Nejprve se hleda vychozi adresar v konfiguracnim souboru
  Adresar:= Trim(Form1.GeneralDir);

  case Form1.Typ_programu of
    1: S:= Form1.SuiteDir;
    2: S:= Form1.FirefoxDir;
    3: S:= Form1.ThunderbirdDir;
    4: S:= Form1.SunbirdDir;
    5: S:= Form1.FlockDir;
    6: S:= Form1.NetscapeDir;
    7: S:= Form1.NetscapeMessengerDir;
    8: S:= Form1.SpicebirdDir;
    9: S:= Form1.SongbirdDir;
    11: S:= Form1.PostBoxDir;
    12: S:= Form1.WyzoDir;
  end;

  S:= Trim (S);
  if Length (S) > 0 then
    begin
      Adresar:= S;
    end;

  // Check, if directory is set and if exists
  if DirectoryExists (Adresar) = false then
    begin
      Adresar:= '';
    end;

  // - nejpve se zkusi registry
  if Length (Adresar) = 0 then
    begin
      RegCesta:= LoadDirectory (Form1.Typ_programu);
      if (Length (RegCesta) > 0) and (DirectoryExists (RegCesta)) then Adresar:= RegCesta else Adresar:= '';
    end;

  // do ktereho adresare - windows
  if (Length (Adresar) = 0) then Cesta:= GetSpecialDir (2) else Cesta:= Adresar;

  // Je adresar zakoncen lomitkem?
  Pozice:= Length(Cesta);
  if (Cesta[Pozice] <> '\') then Cesta:= Cesta + '\';
  
  // Je ve jmene vystupniho souboru uvedeno jmeno profilu?
  if (Pos ('<profile>', Form1.VystupniFormat) > 0) then Form1.IsProfileInName:= true
  else Form1.IsProfileInName:= false;

  // Sestavi se vystupni soubor
  Vystup:= Cesta + Form1.VystupniFormat;

  Result:= ReplacePlaceholdersInPath (Vystup, Form1.PortableDirectory);
end;


//******************************************************************************
// procedure GetTypeProgram
//
// - zjisti, jaky program byl vybran
//******************************************************************************

procedure GetTypeProgram;
begin
  // detekce Mozilly
  if Pos ('SeaMonkey', Form1.ListBox1.Items.Strings[Form1.ListBox1.ItemIndex]) > 0 then
    begin
      Form1.ProgramName:= 'Mozilla';
      Form1.Typ_programu:= 1;
    end;

  // detekce Firefoxe
  if Pos ('Firefox', Form1.ListBox1.Items.Strings[Form1.ListBox1.ItemIndex]) > 0 then
    begin
      Form1.ProgramName:= 'Firefox';
      Form1.Typ_programu:= 2;
    end;

  // detekce Thunderbirdu
  if Pos ('Thunderbird', Form1.ListBox1.Items.Strings[Form1.ListBox1.ItemIndex]) > 0 then
    begin
      Form1.ProgramName:= 'Thunderbird';
      Form1.Typ_programu:= 3;
    end;

  // detekce Sunbirdu
  if Pos ('Sunbird', Form1.ListBox1.Items.Strings[Form1.ListBox1.ItemIndex]) > 0 then
    begin
      Form1.ProgramName:= 'Sunbird';
      Form1.Typ_programu:= 4;
    end;

  // detekce Flocku
  if Pos ('Flock', Form1.ListBox1.Items.Strings[Form1.ListBox1.ItemIndex]) > 0 then
    begin
      Form1.ProgramName:= 'Flock';
      Form1.Typ_programu:= 5;
    end;

  // dektece Netscape Messenger
  if Pos ('Netscape Messenger', Form1.ListBox1.Items.Strings[Form1.ListBox1.ItemIndex]) > 0 then
    begin
      Form1.ProgramName:= 'Netscape Messenger';
      Form1.Typ_programu:= 7;
    end;  

  // detekce Netscape
  if (Pos ('Netscape', Form1.ListBox1.Items.Strings[Form1.ListBox1.ItemIndex]) > 0) and
      (Pos ('Netscape Messenger', Form1.ListBox1.Items.Strings[Form1.ListBox1.ItemIndex]) = 0) then
    begin
      Form1.ProgramName:= 'Netscape';
      Form1.Typ_programu:= 6;
    end;

  // detection of Spicebird
  if Pos ('Spicebird', Form1.ListBox1.Items.Strings[Form1.ListBox1.ItemIndex]) > 0 then
    begin
      Form1.ProgramName:= 'Spicebird';
      Form1.Typ_programu:= 8;
    end;

  if Pos ('Songbird', Form1.ListBox1.Items.Strings[Form1.ListBox1.ItemIndex]) > 0 then
    begin
      Form1.ProgramName:= 'Songbird';
      Form1.Typ_programu:= 9;
    end;

  if Pos (Config.l10n.getL10nString('MozBackup14', 'LANG_PORTABLE_APPS'),
            Form1.ListBox1.Items.Strings[Form1.ListBox1.ItemIndex]) > 0 then
    begin
      Form1.ProgramName:= 'Portable';
      Form1.Typ_programu:= 10;
    end;

  if Pos ('PostBox', Form1.ListBox1.Items.Strings[Form1.ListBox1.ItemIndex]) > 0 then
    begin
      Form1.ProgramName:= 'PostBox';
      Form1.Typ_programu:= 11;
    end;

  if Pos ('Wyzo', Form1.ListBox1.Items.Strings[Form1.ListBox1.ItemIndex]) > 0 then
    begin
      Form1.ProgramName:= 'Wyzo';
      Form1.Typ_programu:= 12;
    end;
    
end;  


//******************************************************************************
// procedure ChooseDialog
//
// - vyber Open ci Save dialogu
//******************************************************************************

procedure ChooseDialog;
var Soubor: string;
begin
  // vyber souboru                       
  if Form1.Akce = 1 then
    begin
      // setting default path and localization
      Form1.SaveDialog1.Filter:= Config.l10n.getL10nString('TForm1', 'LANG_DIALOGS');
      Form1.SaveDialog1.InitialDir:= ExtractFilePath (Form1.Vyst_soubor);
      Soubor:= SysUtils.StringReplace (Form1.Vyst_soubor, '<profile>', '', [rfReplaceAll]);
      if Length (Soubor) < 5 then Soubor:= 'backup' + Soubor;
      Form1.SaveDialog1.FileName:= Over_platnost (ExtractFileName (Soubor));

      if Form1.SaveDialog1.Execute then
        begin
           // !!! Zmena s lomitkama
           //Form1.Vyst_soubor:= ChangeFileExt(Form1.SaveDialog1.FileName,'.pcv');
           Form1.Vyst_soubor:= SysUtils.StringReplace(ChangeFileExt(Form1.SaveDialog1.FileName,'.pcv'), '\\', '\', [rfReplaceAll]);
           Form1.StaticText3.Hint:= Form1.Vyst_soubor;
           if Length (Form1.Vyst_soubor) < 40 then Form1.StaticText3.Caption:= Form1.Vyst_soubor
           else Form1.StaticText3.Caption:= Copy (Form1.Vyst_soubor, 1, 3) + '...' + Copy (Form1.Vyst_soubor, Length (Form1.Vyst_soubor) - 32, 33);
        end;
    end
  else
    begin
      // setting default path and localization
      Form1.OpenDialog1.Filter:= Config.l10n.getL10nString('TForm1', 'LANG_DIALOGS');
      Form1.OpenDialog1.InitialDir:= ExtractFilePath (Form1.Vyst_soubor);
      Form1.OpenDialog1.FileName:= Over_platnost (ExtractFileName (Form1.Vyst_soubor));

      if Form1.OpenDialog1.Execute then

      if FileExists (Form1.OpenDialog1.FileName) and IsValidFile (Form1.OpenDialog1.FileName) then
        begin
           // !!! zmena s lomitkama
           //Form1.Vyst_soubor:= ChangeFileExt(Form1.OpenDialog1.FileName,'.pcv');
           Form1.Vyst_soubor:= SysUtils.StringReplace(ChangeFileExt(Form1.OpenDialog1.FileName,'.pcv'), '\\', '\', [rfReplaceAll]);
           Form1.StaticText3.Hint:= Form1.Vyst_soubor;

           if Length (Form1.Vyst_soubor) < 40 then Form1.StaticText3.Caption:= Form1.Vyst_soubor
           else Form1.StaticText3.Caption:= Copy (Form1.Vyst_soubor, 1, 3) + '...' + Copy (Form1.Vyst_soubor, Length (Form1.Vyst_soubor) - 32, 33);
        end
      else Application.MessageBox (pchar (Config.l10n.getL10nString ('TForm1', 'LANG_BAD_FILE2')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_OK + MB_ICONWARNING);
    end;

  // ** pokus o opravu bugu
  Form1.Vyst_soubor:= SysUtils.StringReplace (Form1.Vyst_soubor, '\\', '\', [rfReplaceAll]);
  Form1.StaticText3.Caption:= SysUtils.StringReplace (Form1.StaticText3.Caption, '\\', '\', [rfReplaceAll]);
  Form1.StaticText3.Hint:= SysUtils.StringReplace (Form1.StaticText3.Hint, '\\', '\', [rfReplaceAll]);

  // je to v siti?
  if Pos ('\', Form1.StaticText3.Caption) = 1 then
    begin
      Form1.StaticText3.Caption:= '\' + Form1.StaticText3.Caption;
      Form1.StaticText3.Hint:= '\' + Form1.StaticText3.Hint;
      Form1.Vyst_soubor:= '\' + Form1.Vyst_soubor; 
    end;

  Form1.Vyst_soubor:= SysUtils.StringReplace (Form1.Vyst_soubor, '/', '-', [rfReplaceAll]);
  Form1.StaticText3.Caption:= SysUtils.StringReplace (Form1.StaticText3.Caption, '/', '-', [rfReplaceAll]);
  Form1.StaticText3.Hint:= SysUtils.StringReplace (Form1.StaticText3.Hint, '/', '-', [rfReplaceAll]);

end;


//******************************************************************************
// function IsRunning
//
// - detekce spustene Mozilly
//******************************************************************************

function IsRunning: boolean;
var Procesy: TStringList;
    I: integer;
    Vysledek: boolean;
begin
  I:= 0; Vysledek:= false;

  if TESTOVAT_PROCESY = 1 then
    begin
      if OSVersion = 7 then Procesy:= GetProcessListNT else Procesy:= GetProcessList;
      While I <= Procesy.Count-1 do
        begin
          case Form1.Typ_programu of
            1: begin
                 if Procesy[I] = 'mozilla.exe' then Vysledek:= true;
                 if Procesy[I] = 'seamonkey.exe' then Vysledek:= true;
                 if Procesy[I] = 'Netscp.exe' then Vysledek:= true;
               end;
            2: begin
                 if Procesy[I] = 'MozillaFirebird' then Vysledek:= true;
                 if Procesy[I] = 'MozillaFirebird.exe' then Vysledek:= true;
                 if Procesy[I] = 'MOZILL~1.EXE' then Vysledek:= true;
                 if Procesy[I] = 'firefox.exe' then Vysledek:= true;
               end;
            3: if Procesy[I] = 'thunderbird.exe' then Vysledek:= true;
            4: if Procesy[I] = 'sunbird.exe' then Vysledek:= true;
            5: if Procesy[I] = 'flock.exe' then Vysledek:= true;
            6: if Procesy[I] = 'navigator.exe' then Vysledek:= true;
            7: if Procesy[I] = 'messenger.exe' then Vysledek:= true;
            8: if Procesy[I] = 'spicebird.exe' then Vysledek:= true;
            9: if Procesy[I] = 'songbird.exe' then Vysledek:= true;
            11: if Procesy[I] = 'postbox.exe' then Vysledek:= true;
            12: if Procesy[I] = 'wyzo.exe' then Vysledek:= true;
          end;
          I:= I + 1;
        end;
    end;
    
  Result:= Vysledek;
end;


//******************************************************************************
// function IsValidFile
//
// - detekce platnosti souboru zalohy
//******************************************************************************

function IsValidFile (Soubor: string):boolean;
var F: textfile;
    S: string;
    Revize: byte;
    Vystup: boolean;
    zipFactory: TZipFactory;
begin
  Result:= false;
  Vystup:= false;
  try
    if FileExists (Soubor) = true then begin
    // testovani na stary typ souboru
    AssignFile (F, Soubor);
    Reset (F);
      Readln (F, S);
      S:= Trim (S);
      if S = 'Mozilla Backup' then
        begin
          Readln (F, S);
          S:= Trim (S);
          Delete (S, 1, 7);
          S:= Trim (S);
          Revize:= StrToInt (S);
          if Form1.Typ_programu = Revize then
            begin
              Form1.Verze_souboru:= 1;
              Vystup:= true;
            end;
        end;
    CloseFile (F);


    if Vystup = false then
      begin
        // testovani na novy typ souboru
        zipFactory:= TZipFactory.Create(Soubor, '');
        if zipFactory.extractFile('indexfile.txt', GetSpecialDir (2)) = 1 then
          begin
            SysUtils.DeleteFile(GetSpecialDir (2) + '\indexfile.txt');
            Form1.Verze_souboru:= 2;
            Vystup:= true;
          end;
        zipFactory.Destroy;
      end;

    // prirazeni vysledku
    Result:= Vystup;

    end;

  except
    on E:EInOutError do     // nastala nejaka vyjimka
      begin
        Application.MessageBox (pchar (Config.l10n.getL10nString ('TForm1', 'LANG_NOT_FOUND')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_OK + MB_ICONWARNING);
        Halt (1);
      end;
  end;
end;

// Is backup file for selected app?
function IsValidFileForApp (Filename: String; ProgramId: byte):boolean;
begin
  DetekceSoucastiSoubor;

  // We dont want to check app version for backups from Portable version
  if ((Form1.BackupAppVersion > 0) and (Form1.BackupAppVersion <> Form1.Typ_programu)
        and (Form1.BackupAppVersion <> 10)) then
    begin
      Result:= false;
    end
  else
    begin
      Result:= true;
    end;
end;


//******************************************************************************
// procedure NastavCheckboxy
//
// - nastavi checkboxy
//******************************************************************************

procedure NastavCheckboxy;
var I: integer;
begin
  for I:= 1 to Form1.GroupBox3.ControlCount - 1 do
    begin
      if Form1.GroupBox3.Controls[I] is TCheckBox then
      TCheckBox(Form1.GroupBox3.Controls[I]).Checked:= false;
    end;

  for I:= 1 to Form1.GroupBox3.ControlCount - 1 do
    begin
      if Form1.GroupBox3.Controls[I] is TCheckBox then
      TCheckBox(Form1.GroupBox3.Controls[I]).Enabled:= true;
    end;
end;


//******************************************************************************
// function NastavSoubor
//
// - funkce nastavi vystupni soubor
//******************************************************************************

procedure NastavSoubor;
var Soubor: string;
begin
  Soubor:= GetDefaultFileName;
  Form1.Vyst_soubor:= Soubor;
  Form1.StaticText3.Hint:= Soubor;
  if Length (Soubor) < 40 then Form1.StaticText3.Caption:= Soubor
  else Form1.StaticText3.Caption:= Copy (Soubor, 1, 3) + '...' + Copy (Soubor, Length (Soubor) - 35, 36);
end;


//******************************************************************************
// function Prepsat_profil
//
// - 
//******************************************************************************
function Prepsat_profil:boolean;
begin
  if (Form1.Akce = 1) then Result:= true
  else if (Application.MessageBox(pchar (Config.l10n.getL10nString('MozBackup14', 'LANG_OVERWRITE_PROFILE')),
      pchar (Config.l10n.getL10nString ('TForm1', 'LANG_QUESTION')),
      MB_YESNO + MB_ICONQUESTION) = IDYES) then Result:= true
  else Result:= false;
end;


//******************************************************************************
// function Over_platnost
//
// - funkce overi platnost vystupniho souboru a navrati spravnou 
//
// Vstup: Cesta - cesta k souboru
// Vystup: - platna cesta
//******************************************************************************

function Over_platnost (Cesta: string):string;
begin
  Cesta:= SysUtils.StringReplace (Cesta, '<', '', [rfReplaceAll]);
  Cesta:= SysUtils.StringReplace (Cesta, '>', '', [rfReplaceAll]);
  Cesta:= SysUtils.StringReplace (Cesta, '?', '', [rfReplaceAll]);
  Cesta:= SysUtils.StringReplace (Cesta, '|', '', [rfReplaceAll]);
  Cesta:= SysUtils.StringReplace (Cesta, '^', '', [rfReplaceAll]);
//  Cesta:= SysUtils.StringReplace (Cesta, '(', '', [rfReplaceAll]);
//  Cesta:= SysUtils.StringReplace (Cesta, ')', '', [rfReplaceAll]);
//  Cesta:= SysUtils.StringReplace (Cesta, ';', '', [rfReplaceAll]);
//  Cesta:= SysUtils.StringReplace (Cesta, '&', '', [rfReplaceAll]);
//  Cesta:= SysUtils.StringReplace (Cesta, '$', '', [rfReplaceAll]);
  Result:= Cesta;
end;


//******************************************************************************
// function Over_profil
//
// - funkce overi, zda-li je zadany profil platny
//
// Vstup: Adresar - adresar s profilem
// Vystup: - je platny ci neni
//******************************************************************************

function Over_profil (Adresar: string):boolean;
var Vyhledej: TSearchRec;
begin
  Over_profil:= false;
  if FindFirst (Adresar + '\*.*', $00000010, Vyhledej) = 0 then
    begin
      Repeat
        if FileExists (Adresar + '\' + Vyhledej.Name + '\prefs.js') then Over_profil:= true;
      Until FindNext (Vyhledej) <> 0;
      SysUtils.FindClose (Vyhledej);
    end;
end;


//******************************************************************************
// procedure Over_program
//
// - detekce, zda-li byl nalezen nejaky program. Kdyz ne, program je ukoncen
//******************************************************************************

procedure Over_program;
begin
  if Form1.ListBox1.Count = 0 then
    begin
      Form1.Chyba:= true;
      Form1.ListBox1.Items.Add(Config.l10n.getL10nString ('TForm1', 'LANG_NO_PROGRAM'));
      Form1.Button1.Visible:= false;
      Form1.Button3.Visible:= false;
      Form1.Button2.Caption:= Config.l10n.getL10nString ('TForm1', 'LANG_BUTTON_KONEC');
    end;                                         
end;


//******************************************************************************
// procedure Over_vyber
//
// - overi, zda-li je vybrana nejaka aplikace pro zalohovani (resp. obnovu)
//******************************************************************************

procedure Over_vyber;
begin
  if Form1.ListBox1.Items.Strings[0] <> Config.l10n.getL10nString ('TForm1', 'LANG_NO_PROGRAM') then
    begin
      if not Form1.ListBox1.ItemIndex >= 0 then Form1.Button1.Enabled:= false
      else Form1.Button1.Enabled:= true;
    end;
end;


//******************************************************************************
// procedure Over_vyber_profilu
//
// - overi, zda-li je vybran nejaky profil
//******************************************************************************

procedure Over_vyber_profilu;
begin
  if Form1.ListBox2.ItemIndex >= 0 then
    begin
      Form1.Button1.Enabled:= true
    end
  else
    begin
      Form1.Button1.Enabled:= false;
    end;
end;

procedure selectPortableProfile();
var choosenDirectory: String;
    portableStr: String;
    I: integer;
    find: boolean;
begin
  if SelectDirectory (Config.l10n.getL10nString ('MozBackup14', 'LANG_PORTABLE_SELECT_PROFILE'), '', choosenDirectory) then
    begin
      if not FileExists (choosenDirectory + '\prefs.js') then
        begin
          showErrorDialog (Config.l10n.getL10nString ('MozBackup14', 'LANG_ERROR'), Config.l10n.getL10nString ('MozBackup14', 'LANG_NO_PROFIL2'));
        end
      else
        begin
          portableStr:= Config.l10n.getL10nString ('MozBackup14', 'LANG_PORTABLE_PROFILE');
          find:= false;

          for I := 0 to Form1.ListBox2.Items.Count - 1 do
            begin
              if portableStr = Form1.ListBox2.Items.Strings[i] then
                begin
                  find:= true;
                end;              
            end;
            
          if (find = false) then
            begin
              Form1.ListBox2.Items.Add(portableStr);
              Form1.PortableDirectory:= choosenDirectory;
            end;
        end;
    end;
end;

//******************************************************************************
// procedure Ukonceni_pogramu
//
// - ukonci programu stisknutim krizku na formulari
//
// Vstup: CanClose - informace o uzavreni formulare
//******************************************************************************

procedure Ukonceni_programu (var CanClose: boolean);
begin
  if (Form1.Panel6.Visible = false) and (Form1.Chyba = false) then
    begin
      if Application.MessageBox (pchar (Config.l10n.getL10nString ('TForm1', 'LANG_END_TEXT')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_END_PROGRAM')), MB_YESNO + MB_ICONQUESTION) = IDNO then
      CanClose:= false else Halt (1);
    end;
end;


//******************************************************************************
// function Zacatek_zalohovani
//
// - informace o tom, zda-li se muze zacit se zalohovanim (resp. obnovou)
//******************************************************************************

function Zacatek_zalohovani: boolean;
var Detekce: boolean;
begin
  Detekce:= false;
  While (IsRunning) and (Detekce = false) do
    begin
      case Form1.Typ_programu of
        1: if Application.MessageBox(pchar (Config.l10n.getL10nString ('MozBackup14', 'LANG_DETEKCE', 'SeaMonkey')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_RETRYCANCEL + MB_ICONERROR) = IDCANCEL then Detekce:= true;
        2: if Application.MessageBox(pchar (Config.l10n.getL10nString ('MozBackup14', 'LANG_DETEKCE', 'Firefox')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_RETRYCANCEL + MB_ICONERROR) = IDCANCEL then Detekce:= true;
        3: if Application.MessageBox(pchar (Config.l10n.getL10nString ('MozBackup14', 'LANG_DETEKCE', 'Thunderbird')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_RETRYCANCEL + MB_ICONERROR) = IDCANCEL then Detekce:= true;
        4: if Application.MessageBox(pchar (Config.l10n.getL10nString ('MozBackup14', 'LANG_DETEKCE', 'Sunbird')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_RETRYCANCEL + MB_ICONERROR) = IDCANCEL then Detekce:= true;
        5: if Application.MessageBox(pchar (Config.l10n.getL10nString ('MozBackup14', 'LANG_DETEKCE', 'Flock')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_RETRYCANCEL + MB_ICONERROR) = IDCANCEL then Detekce:= true;
        6: if Application.MessageBox(pchar (Config.l10n.getL10nString ('MozBackup14', 'LANG_DETEKCE', 'Netscape')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_RETRYCANCEL + MB_ICONERROR) = IDCANCEL then Detekce:= true;
        7: if Application.MessageBox(pchar (Config.l10n.getL10nString ('MozBackup14', 'LANG_DETEKCE', 'Netscape Messenger')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_RETRYCANCEL + MB_ICONERROR) = IDCANCEL then Detekce:= true;
        8: if Application.MessageBox(pchar (Config.l10n.getL10nString ('MozBackup14', 'LANG_DETEKCE', 'Spicebird')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_RETRYCANCEL + MB_ICONERROR) = IDCANCEL then Detekce:= true;
        9: if Application.MessageBox(pchar (Config.l10n.getL10nString ('MozBackup14', 'LANG_DETEKCE', 'Songbird')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_RETRYCANCEL + MB_ICONERROR) = IDCANCEL then Detekce:= true;
        11: if Application.MessageBox(pchar (Config.l10n.getL10nString ('MozBackup14', 'LANG_DETEKCE', 'PostBox')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_RETRYCANCEL + MB_ICONERROR) = IDCANCEL then Detekce:= true;
        12: if Application.MessageBox(pchar (Config.l10n.getL10nString ('MozBackup14', 'LANG_DETEKCE', 'Wyzo')), pchar (Config.l10n.getL10nString ('TForm1', 'LANG_WARNING')), MB_RETRYCANCEL + MB_ICONERROR) = IDCANCEL then Detekce:= true;
      end;
    end;
  if Detekce = true then Result:= false else Result:= true;
end;


//******************************************************************************
// function Zkraceny_adresar
//
// - oreze adresarovou cestu
//******************************************************************************

function Zkraceny_adresar (S: string):string;
begin
  if Length (S) > 31 then Result:= Copy (S, 1, 3) + '...' + Copy (S, Length (S) - 30, 31)
  else Result:= S;
end;

end.

