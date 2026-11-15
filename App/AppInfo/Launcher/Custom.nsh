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
!macroend