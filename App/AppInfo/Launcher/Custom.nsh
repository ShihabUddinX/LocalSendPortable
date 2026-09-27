${SegmentFile}
!include WinMessages.nsh

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
				MessageBox MB_OK|MB_ICONSTOP "LocalSend dosen't have any 32bit Edition/Version!"
				Abort
			${EndIf}
		${EndIf}
	${EndIf}
!macroend

${Segment.onInit}
	ReadRegStr $0 HKLM "Software\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"	
	${If} $0 < 10240 ;Windows 10
		MessageBox MB_OK|MB_ICONSTOP "LocalSend only runs on Windows 10 or later!"
		Abort
	${EndIf}
!macroend