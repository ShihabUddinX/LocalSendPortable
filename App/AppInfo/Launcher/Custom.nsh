${SegmentFile}
!include WinMessages.nsh
!include StrFunc.nsh
!include LogicLib.nsh
!include ProcFunc.nsh
${StrRep}

${SegmentInit}
	ReadRegStr $0 HKLM "HARDWARE\DESCRIPTION\System" "Identifier"
	StrCpy $1 $0 3 0

	${If} $1 == "ARM"
		${ReadLauncherConfig} $ProgramExecutable Launch ProgramExecutableARM64
		${SetEnvironmentVariablesPath} FullAppDir "$EXEDIR\App\LocalSendarm64"
	${Else}
		${If} $Bits = 64
			${SetEnvironmentVariablesPath} FullAppDir "$EXEDIR\App\LocalSend64"
		${Else}
			${If} $Bits = 32
				MessageBox MB_OK|MB_ICONSTOP "LocalSend doesn't have any 32-bit Edition/Version!"
				Abort
			${EndIf}
		${EndIf}
	${EndIf}
!macroend

${Segment.onInit}
	ReadRegStr $0 HKLM "Software\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"

	${If} $0 < 10240
		MessageBox MB_OK|MB_ICONSTOP "LocalSend only runs on Windows 10 or later!"
		Abort
	${EndIf}
!macroend

${SegmentPre}
	${If} ${FileExists} "$EXEDIR\Data\settings\settings.json"
		; Determine if running from the PortableApps.com Menu
		ReadEnvStr $0 "PortableApps.comLocaleCode2_INTERNAL"

		${IfNot} $0 == ""
			; Update the existing language setting using jq
			nsExec::ExecToStack '$\"$EXEDIR\App\Bin\jq.exe$\" --arg key $\"flutter.ls_locale$\" --arg locale $\"$0$\" $\".[$$key] = $$locale$\" $\"$EXEDIR\Data\settings\settings.json$\"'

			Pop $6 ; Exit code
			Pop $7 ; Updated JSON output

			${If} $6 == "0"
				FileOpen $0 "$EXEDIR\Data\settings\settings.json" w
				FileWrite $0 $7
				FileClose $0
			${EndIf}
		${EndIf}

	${Else}
		; Create settings.json if it does not exist
		CreateDirectory "$EXEDIR\Data\settings"

		FileOpen $2 "$EXEDIR\Data\settings\settings.json" w
		FileWrite $2 "{$\n"
		FileWrite $2 "    $\"flutter.ls_locale$\": $\"$0$\"$\n"
		FileWrite $2 "}"
		FileClose $2
	${EndIf}



; ==========================================
; LocalSend - Set Download Directory
; ==========================================

StrCpy $0 ""
StrCpy $1 ""
StrCpy $2 ""
StrCpy $3 ""

; Read DownloadDir from INI
${If} ${FileExists} "$EXEDIR\LocalSendPortable.ini"
    ReadINIStr $0 "$EXEDIR\LocalSendPortable.ini" "LocalSendPortable" "DownloadDir"
${EndIf}

; Default download directory
${If} $0 == ""
    StrCpy $0 "$EXEDIR\Data\Downloads"
    CreateDirectory "$0"
${Else}
    ; Check second character for drive colon
    StrCpy $3 $0 1 1

    ${If} $3 != ":"
        ; Relative path: prepend EXEDIR drive
        StrCpy $3 $EXEDIR 2
        StrCpy $0 "$3\$0"
    ${EndIf}
${EndIf}

; ==========================================
; Update Settings.json using jq
; ==========================================

${If} ${FileExists} "$EXEDIR\Data\Settings\Settings.json"

    ; Create jq filter
    FileOpen $2 "$EXEDIR\Data\Settings\UpdateDestination.jq" w
    FileWrite $2 ".[$\"flutter.ls_destination$\"] = $$destination"
    FileClose $2

    ; Remove previous temporary output
    Delete "$EXEDIR\Data\Settings\Settings.tmp"

    ; Execute jq through CMD
    nsExec::ExecToStack '"$SYSDIR\cmd.exe" /D /C ""$EXEDIR\App\Bin\jq.exe" --arg destination "$0" -f "$EXEDIR\Data\Settings\UpdateDestination.jq" "$EXEDIR\Data\Settings\Settings.json" > "$EXEDIR\Data\Settings\Settings.tmp""'

    Pop $1
    Pop $2

    ; Check jq exit code
    ${If} $1 == 0
        ${If} ${FileExists} "$EXEDIR\Data\Settings\Settings.tmp"

            ; Backup original settings
            Delete "$EXEDIR\Data\Settings\Settings.bak"
            Rename "$EXEDIR\Data\Settings\Settings.json" "$EXEDIR\Data\Settings\Settings.bak"

            ; Replace original with updated JSON
            Rename "$EXEDIR\Data\Settings\Settings.tmp" "$EXEDIR\Data\Settings\Settings.json"

            ${If} ${FileExists} "$EXEDIR\Data\Settings\Settings.json"
                Delete "$EXEDIR\Data\Settings\Settings.bak"
            ${Else}
                Rename "$EXEDIR\Data\Settings\Settings.bak" "$EXEDIR\Data\Settings\Settings.json"
            ${EndIf}

        ${EndIf}
    ${EndIf}

    ; Cleanup
    Delete "$EXEDIR\Data\Settings\Settings.tmp"
    Delete "$EXEDIR\Data\Settings\UpdateDestination.jq"

${EndIf}
!macroend