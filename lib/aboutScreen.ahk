; About Screen for my projects v0.0.5
; TODO: Add social media icons (github, youtube, linkedin, instagram, twitter?)
FileCreateDir % A_Temp "/font"
FileInstall, res\font\BaiJamjuree.ttf, % A_Temp "\font\BaiJamjuree.ttf", 0
global fnt := A_Temp "\font\BaiJamjuree.ttf"
global font1 := New CustomFont(fnt)
FileCreateDir % A_Temp "/img"
FileInstall, res\img\github.png, % A_Temp "\img\github.png", 0
FileInstall, res\img\youtube.png, % A_Temp "\img\youtube.png", 0
FileInstall, res\img\linkedin.png, % A_Temp "\img\linkedin.png", 0
FileInstall, res\img\instagram.png, % A_Temp "\img\instagram.png", 0
FileInstall, res\img\twitter.png, % A_Temp "\img\twitter.png", 0
FileInstall, res\img\discord.png, % A_Temp "\img\discord.png", 0
FileInstall, res\img\portfolio.png, % A_Temp "\img\portfolio.png", 0
FileInstall, res\img\linktree.png, % A_Temp "\img\linktree.png", 0

;~ showAboutScreen("My APP", "This app does amazing things.")
showAboutScreen(title, description){
	Gui, about:destroy ; Normally this is not needed but just in case destroy previous about window
	exitButtonB64 := "iVBORw0KGgoAAAANSUhEUgAAACoAAAAoCAYAAACIC2hQAAAAAXNSR0IArs4c6QAAApNJREFUWAntWEFrE1EQntmNVfGih0Lr5uZF7UFBQS/RHit6UVAQhNJDjUm9evcHeGxq6klJDzXxoNDgwWJQPNqTh9qCErFNKEHPQk3GGc22L0tf+/J2FRZ34fHmzXwz35d5u2/Z4BBNE8TgcmKg8bfERGjUO5UKFkRwzjYxvxT0/8v1MM2cIei8VzmTrVe7EYWddDSKLqo1ko6q3YjC/n86ymferetUdnVdk5hgdHFTv3VH7xM5w1R4xAdz6R20yiNUHgiSik9ighGs5AQxpmurxFGqpWahUCKgSSHi+dp3aD1PU/mgTyw2+15IrIuZlBzJ9TH9zFZJq7B8jEnGVCIWdKkNrZcjVLgifha5wL6LKobtsW7uSsC/59Kqow3Mr7iwb5Srb6gMIuwbwKKMHURuSI7kqjmmtpVQKb6G2Q8uDFxANnvJ6BzfDDy2LwT8KljJ2fb2Z1kLFZp1vL26H9wMAH7ehfYTC88IdhfMnqFQQqV6HXN1LjKuY3LAHW/i3S+6uKk/tNCjNHucP7rmdYR8ND0VjC5u6g8l1KPCaYLNt/zgeDpCiQnGo+IpHcbEby3Uo5nzHaAad3MwQPSa1zK2LsF0oF1L03TPQ7YFMDCshA5R8WQb6BULONzLgdUDcOiyDH7AqmqMO3vkJ+Aiv6FOqH5T20poE7LLfCzN9ZJgxYPU1TpO/JAhNoutqBgHsNSA/EfVZ2pbCUVEauJUjokf/CHCxxkYvLmE2U2fWGzxMcET8QmWD/u85PqYfmarV6hP0MCpex49fLMGd6o7CajgjTYRTaSh+Gwdcwt+ns0cSqgQigCEnJa7+wNCiZTiVluvVfUXA4nQqJubdDTpaNQdiLpebO5RTP7Dj3jvY7P1sRH6C6/z2F0v5TZEAAAAAElFTkSuQmCC"

	elModo7ImgB64 := "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"
	; END OF IMAGE DATA

	; GDI+ Startup
	hGdip := DllCall("Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll") ; Load module
	VarSetCapacity(GdiplusStartupInput, (A_PtrSize = 8 ? 24 : 16), 0) ; GdiplusStartupInput structure
	NumPut(1, GdiplusStartupInput, 0, "UInt") ; GdiplusVersion
	VarSetCapacity(pToken, 0)
	DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", pToken, "Ptr", &GdiplusStartupInput, "Ptr", 0) ; Initialize GDI+

	exitButton := GdipCreateFromBase64(exitButtonB64, 2)
	elModo7Img := GdipCreateFromBase64(elModo7ImgB64, 2)

	; Free GDI+ module from memory
	DllCall("Kernel32.dll\FreeLibrary", "Ptr", hGdip)

	Gui about:+LastFound -Caption +AlwaysOnTop -Resize +ToolWindow
	Gui about:Color, 0x000015
	Gui about:Add, Picture, x16 y8 w128 h128, % "HBITMAP:*" elModo7Img
	Gui about:Font, s16 c0x8080FF, Bai Jamjuree Bold
	Gui about:Add, Text, x152 y8 w386 h23 +0x200, % title
	Gui about:Font, s12 c0x00FF80, Bai Jamjuree Bold
	Gui about:Add, Text, x16 y136 w128 h60 +Center, elModo7
	Gui about:Font, s12 c0x80FFFF, Bai Jamjuree Bold
	Gui about:Add, Text, x16 y156 w128 h60 +Center, VictorDevLog
	Gui about:Font, s12 c0x80FFFF, Bai Jamjuree
	Gui about:Add, Text, x152 y32 w412 h103 +Left, % description
	Gui about:Font, s10 c0xFFFF80, Bai Jamjuree
	Gui about:Add, Picture, x544 y8 w21 h20 gAboutGuiClose, % "HBITMAP:*" exitButton
	Gui about:Add, Picture, x248 y136 w32 h32 glinkGithub, % A_Temp "\img\github.png"
	Gui about:Add, Picture, x288 y136 w32 h32 glinkYoutube, % A_Temp "\img\youtube.png"
	Gui about:Add, Picture, x408 y136 w32 h32 glinkLinkedin, % A_Temp "\img\linkedin.png"
	Gui about:Add, Picture, x448 y136 w32 h32 glinkInstagram, % A_Temp "\img\instagram.png"
	Gui about:Add, Picture, x488 y136 w32 h32 glinkTwitter, % A_Temp "\img\twitter.png"
	Gui about:Add, Picture, x528 y136 w32 h32 glinkDiscord, % A_Temp "\img\discord.png"
	Gui about:Add, Picture, x328 y136 w32 h32 glinkPortfolio, % A_Temp "\img\portfolio.png"
	Gui about:Add, Picture, x368 y136 w32 h32 glinkLinktree, % A_Temp "\img\linktree.png"
	Gui about:Add, Text, x152 y175 w413 h35 +Right, Víctor Santiago Martínez Picardo (elModo7 / VictorDevLog) %A_YYYY%
	Gui about:Show, w573 h200, About Window
}

AboutGuiClose(){
	Gui, about:destroy
}

linkGithub(){
	Run, https://github.com/elModo7
}

linkYoutube(){
	Run, https://www.youtube.com/@VictorDevLog?sub_confirmation=1
}

linkLinkedin(){
	Run, https://www.linkedin.com/in/victor-smp
}

linkInstagram(){
	Run, https://www.instagram.com/victordevlogyt
}

linkTwitter(){
	Run, https://x.com/VictorDevLog
}

linkDiscord(){
	Run, https://discord.gg/aYFXQjGA6b
}

linkPortfolio(){
	Run, https://elmodo7.github.io/
}

linkLinktree(){
	Run, https://linktr.ee/VictorDevLog
}

GdipCreateFromBase64(B64, RetType := 0) { ; 0=pBitmap, 1=HICON, 2=HBITMAP
	VarSetCapacity(B64Len, 0)
	DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", StrLen(B64), "UInt", 0x01, "Ptr", 0, "UIntP", B64Len, "Ptr", 0, "Ptr", 0)
	VarSetCapacity(B64Dec, B64Len, 0) ; pbBinary size
	DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", StrLen(B64), "UInt", 0x01, "Ptr", &B64Dec, "UIntP", B64Len, "Ptr", 0, "Ptr", 0)
	pStream := DllCall("Shlwapi.dll\SHCreateMemStream", "Ptr", &B64Dec, "UInt", B64Len, "UPtr")
	VarSetCapacity(pBitmap, 0)
	DllCall("Gdiplus.dll\GdipCreateBitmapFromStreamICM", "Ptr", pStream, "PtrP", pBitmap)

	If (RetType = 2) {
		VarSetCapacity(hBitmap, 0)
		DllCall("Gdiplus.dll\GdipCreateHBITMAPFromBitmap", "UInt", pBitmap, "UInt*", hBitmap, "Int", 0XFFFFFFFF)
	}

	If (RetType = 1) {
		DllCall("Gdiplus.dll\GdipCreateHICONFromBitmap", "Ptr", pBitmap, "PtrP", hIcon, "UInt", 0)
	}

	ObjRelease(pStream)

	return (RetType = 1 ? hIcon : RetType = 2 ? hBitmap : pBitmap)
}


/*
	CustomFont v2.00 (2016-2-24)
	---------------------------------------------------------
	Description: Load font from file or resource, without needed install to system.
	---------------------------------------------------------
	Useage Examples:

		* Load From File
			font1 := New CustomFont("ewatch.ttf")
			Gui, Font, s100, ewatch

		* Load From Resource
			Gui, Add, Text, HWNDhCtrl w400 h200, 12345
			font2 := New CustomFont("res:ewatch.ttf", "ewatch", 80) ; <- Add a res: prefix to the resource name.
			font2.ApplyTo(hCtrl)

		* The fonts will removed automatically when script exits.
		  To remove a font manually, just clear the variable (e.g. font1 := "").
*/
Class CustomFont
{
	static FR_PRIVATE  := 0x10

	__New(FontFile, FontName="", FontSize=30) {
		if RegExMatch(FontFile, "i)res:\K.*", _FontFile) {
			this.AddFromResource(_FontFile, FontName, FontSize)
		} else {
			this.AddFromFile(FontFile)
		}
	}

	AddFromFile(FontFile) {
		DllCall( "AddFontResourceEx", "Str", FontFile, "UInt", this.FR_PRIVATE, "UInt", 0 )
		this.data := FontFile
	}

	AddFromResource(ResourceName, FontName, FontSize = 30) {
		static FW_NORMAL := 400, DEFAULT_CHARSET := 0x1

		nSize    := this.ResRead(fData, ResourceName)
		fh       := DllCall( "AddFontMemResourceEx", "Ptr", &fData, "UInt", nSize, "UInt", 0, "UIntP", nFonts )
		hFont    := DllCall( "CreateFont", Int,FontSize, Int,0, Int,0, Int,0, UInt,FW_NORMAL, UInt,0
		            , Int,0, Int,0, UInt,DEFAULT_CHARSET, Int,0, Int,0, Int,0, Int,0, Str,FontName )

		this.data := {fh: fh, hFont: hFont}
	}

	ApplyTo(hCtrl) {
		SendMessage, 0x30, this.data.hFont, 1,, ahk_id %hCtrl%
	}

	__Delete() {
		if IsObject(this.data) {
			DllCall( "RemoveFontMemResourceEx", "UInt", this.data.fh    )
			DllCall( "DeleteObject"           , "UInt", this.data.hFont )
		} else {
			DllCall( "RemoveFontResourceEx"   , "Str", this.data, "UInt", this.FR_PRIVATE, "UInt", 0 )
		}
	}

	; ResRead() By SKAN, from http://www.autohotkey.com/board/topic/57631-crazy-scripting-resource-only-dll-for-dummies-36l-v07/?p=609282
	ResRead( ByRef Var, Key ) {
		VarSetCapacity( Var, 128 ), VarSetCapacity( Var, 0 )
		If ! ( A_IsCompiled ) {
			FileGetSize, nSize, %Key%
			FileRead, Var, *c %Key%
			Return nSize
		}

		If hMod := DllCall( "GetModuleHandle", UInt,0 )
			If hRes := DllCall( "FindResource", UInt,hMod, Str,Key, UInt,10 )
				If hData := DllCall( "LoadResource", UInt,hMod, UInt,hRes )
					If pData := DllCall( "LockResource", UInt,hData )
						Return VarSetCapacity( Var, nSize := DllCall( "SizeofResource", UInt,hMod, UInt,hRes ) )
							,  DllCall( "RtlMoveMemory", Str,Var, UInt,pData, UInt,nSize )
		Return 0
	}
}