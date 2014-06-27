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

unit ProgressWindow;

interface

uses Config, hlavni, SysUtils;

procedure ProgressWindowAddMessage(Msg: String);
procedure ProgressWindowAddListMessage(Msg: String);
procedure ProgressWindowProgress(CurrentFilesSize: int64; TotalFilesSize: int64);

implementation

procedure ProgressWindowAddMessage(Msg: String);
begin
  Form1.StaticText6.Caption:= Msg;
end;

procedure ProgressWindowAddListMessage(Msg: String);
begin
  Form1.ListBox3.Items.Add(Msg);
end;

procedure ProgressWindowProgress(CurrentFilesSize: int64; TotalFilesSize: int64);
var Position: integer;
begin
  if (CurrentFilesSize = 0) or (TotalFilesSize = 0) then
    begin
      Position:= 0;
    end
  else
    begin
      Position:= Round ((CurrentFilesSize / TotalFilesSize) * 100);
      if (Position > 100) then
        begin
          Position:= 100;
        end;
    end;
  Form1.ProgressBar1.Position:= Position; 
end;

end.
