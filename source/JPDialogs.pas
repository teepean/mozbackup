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

unit JPDialogs;

interface

function showInfoDialog (caption: String; dialogMsg: String):Integer;
function showWarningDialog (caption: String; dialogMsg: String):Integer;
function showErrorDialog (caption: String; dialogMsg: String):Integer;
function showQuestionDialog (caption: String; dialogMsg: String):Integer;

implementation

uses Forms, Windows;

function showInfoDialog (caption: String; dialogMsg: String):Integer;
begin
  Result:= Application.MessageBox (pchar (dialogMsg), pchar (caption),
                          MB_OK + MB_ICONINFORMATION);
end;

function showWarningDialog (caption: String; dialogMsg: String):Integer;
begin
  Result:= Application.MessageBox (pchar (dialogMsg), pchar (caption),
                          MB_OK + MB_ICONWARNING);
end;

function showErrorDialog (caption: String; dialogMsg: String):Integer;
begin
  Result:= Application.MessageBox (pchar (dialogMsg), pchar (caption),
                          MB_OK + MB_ICONERROR);
end;

function showQuestionDialog (caption: String; dialogMsg: String):Integer;
begin
  Result:= Application.MessageBox(pchar (dialogMsg), pchar (caption), MB_YESNO + MB_ICONQUESTION);
end;

end.
