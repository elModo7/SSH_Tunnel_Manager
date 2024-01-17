class Socket
{
  static __eventMsg := 0x9987
  
  __New(s=-1)
  {
    static init
    if (!init)
    {
      DllCall("LoadLibrary", "str", "ws2_32", "ptr")
      VarSetCapacity(wsadata, 394+A_PtrSize)
      DllCall("ws2_32\WSAStartup", "ushort", 0x0000, "ptr", &wsadata)
      DllCall("ws2_32\WSAStartup", "ushort", NumGet(wsadata, 2, "ushort"), "ptr", &wsadata)
      OnMessage(Socket.__eventMsg, "SocketEventProc")
      init := 1
    }
    this.socket := s
  }
  __Delete()
  {
    this.disconnect()
  }
  __Get(k, v)
  {
    if (k="size")
      return this.msgSize()
  }
  connect(host, port)
  {
    if ((this.socket!=-1) || (!(faddr := next := this.__getAddrInfo(host, port))))
      return 0
    while (next)
    {
      sockaddrlen := NumGet(next+0, 16, "uint")
      sockaddr := NumGet(next+0, 16+(2*A_PtrSize), "ptr")
      if ((this.socket := DllCall("ws2_32\socket", "int", NumGet(next+0, 4, "int"), "int", this.__socketType, "int", this.__protocolId, "ptr"))!=-1)
      {
        if ((r := DllCall("ws2_32\WSAConnect", "ptr", this.socket, "ptr", sockaddr, "uint", sockaddrlen, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0, "int"))=0)
        {
          DllCall("ws2_32\freeaddrinfo", "ptr", faddr)
          return Socket.__eventProcRegister(this, 0x21)
        }
        this.disconnect()
      }
      next := NumGet(next+0, 16+(3*A_PtrSize), "ptr")
    }
    this.lastError := DllCall("ws2_32\WSAGetLastError")
    return 0
  }
  bind(host, port)
  {
    if ((this.socket!=-1) || (!(faddr := next := this.__getAddrInfo(host, port))))
      return 0
    while (next)
    {
      sockaddrlen := NumGet(next+0, 16, "uint")
      sockaddr := NumGet(next+0, 16+(2*A_PtrSize), "ptr")
      if ((this.socket := DllCall("ws2_32\socket", "int", NumGet(next+0, 4, "int"), "int", this.__socketType, "int", this.__protocolId, "ptr"))!=-1)
      {
        if (DllCall("ws2_32\bind", "ptr", this.socket, "ptr", sockaddr, "uint", sockaddrlen, "int")=0)
        {
          DllCall("ws2_32\freeaddrinfo", "ptr", faddr)
          return Socket.__eventProcRegister(this, 0x29)
        }
        this.disconnect()
      }
      next := NumGet(next+0, 16+(3*A_PtrSize), "ptr")
    }
    this.lastError := DllCall("ws2_32\WSAGetLastError")
    return 0
  }
  listen(backlog=32)
  {
    return (DllCall("ws2_32\listen", "ptr", this.socket, "int", backlog)=0) ? 1 : 0
  }
  accept()
  {
    if ((s := DllCall("ws2_32\accept", "ptr", this.socket, "ptr", 0, "int", 0, "ptr"))!=-1)
    {
      newsock := new Socket(s)
      newsock.__protocolId := this.__protocolId
      newsock.__socketType := this.__socketType
      Socket.__eventProcRegister(newsock, 0x21)
      return newsock
    }
    return 0
  }
  disconnect()
  {
    Socket.__eventProcUnregister(this)
    DllCall("ws2_32\closesocket", "ptr", this.socket, "int")
    this.socket := -1
    return 1
  }
  msgSize()
  {
    VarSetCapacity(argp, 4, 0)
    if (DllCall("ws2_32\ioctlsocket", "ptr", this.socket, "uint", 0x4004667F, "ptr", &argp)!=0)
      return 0
    return NumGet(argp, 0, "int")
  }
  send(addr, length)
  {
    if ((r := DllCall("ws2_32\send", "ptr", this.socket, "ptr", addr, "int", length, "int", 0, "int"))<=0)
      return 0
    return r
  }
  sendText(msg, encoding="UTF-8")
  {
    VarSetCapacity(buffer, length := (StrPut(msg, encoding)*(((encoding="utf-16")||(encoding="cp1200")) ? 2 : 1)))
    StrPut(msg, &buffer, encoding)
    return this.send(&buffer, length)
  }
  recv(byref buffer, wait=1)
  {
    while ((wait) && ((length := this.msgSize())=0))
      sleep, 100
    if (length)
    {
      VarSetCapacity(buffer, length)
      if ((r := DllCall("ws2_32\recv", "ptr", this.socket, "ptr", &buffer, "int", length, "int", 0))<=0)
        return 0
      return r
    }
    return 0
  }
  recvText(wait=1, encoding="UTF-8")
  {
    if (length := this.recv(buffer, wait))
      return StrGet(&buffer, length, encoding)
    return
  }
  __getAddrInfo(host, port)
  {
    a := ["127.0.0.1", "0.0.0.0", "255.255.255.255", "::1", "::", "FF00::"]
    conv := {localhost:a[1], addr_loopback:a[1], inaddr_loopback:a[1], addr_any:a[2], inaddr_any:a[2], addr_broadcast:a[3]
    , inaddr_broadcast:a[3], addr_none:a[3], inaddr_none:a[3], localhost6:a[4], addr_loopback6:a[4], inaddr_loopback6:a[4]
    , addr_any6:a[5], inaddr_any:a[5], addr_broadcast6:a[6], inaddr_broadcast6:a[6], addr_none6:a[6], inaddr_none6:a[6]}
    if (conv[host])
      host := conv[host]
    VarSetCapacity(hints, 16+(4*A_PtrSize), 0)
    NumPut(this.__socketType, hints, 8, "int")
    NumPut(this.__protocolId, hints, 12, "int")
    if ((r := DllCall("ws2_32\getaddrinfo", "astr", host, "astr", port, "ptr", &hints, "ptr*", next))!=0)
    {
      this.lastError := DllCall("ws2_32\WSAGetLastError")
      return 0
    }
    return next
  }
  __eventProcRegister(obj, msg)
  {
    a := SocketEventProc(0, 0, "register", 0)
    a[obj.socket] := obj
    return (DllCall("ws2_32\WSAAsyncSelect", "ptr", obj.socket, "ptr", A_ScriptHwnd, "uint", Socket.__eventMsg, "uint", msg)=0) ? 1 : 0
  }
  __eventProcUnregister(obj)
  {
    a := SocketEventProc(0, 0, "register", 0)
    a.remove(obj.socket)
    return (DllCall("ws2_32\WSAAsyncSelect", "ptr", obj.socket, "ptr", A_ScriptHwnd, "uint", 0, "uint", 0)=0) ? 1 : 0
  }
}
SocketEventProc(wParam, lParam, msg, hwnd)
{
  global Socket
  static a := []
  Critical
  if (msg="register")
    return a
  if (msg=Socket.__eventMsg)
  {
    if (!isobject(a[wParam]))
      return 0
    if ((lParam & 0xFFFF) = 1)
      return a[wParam].onRecv(a[wParam])
    else if ((lParam & 0xFFFF) = 8)
      return a[wParam].onAccept(a[wParam])
    else if ((lParam & 0xFFFF) = 32)
    {
      a[wParam].socket := -1
      return a[wParam].onDisconnect(a[wParam])
    }
    return 0
  }
  return 0
}

class SocketTCP extends Socket
{
  static __protocolId := 6 ;IPPROTO_TCP
  static __socketType := 1 ;SOCK_STREAM
}

class SocketUDP extends Socket
{
  static __protocolId := 17 ;IPPROTO_UDP
  static __socketType := 2 ;SOCK_DGRAM

  enableBroadcast()
  {
    VarSetCapacity(optval, 4, 0)
    NumPut(1, optval, 0, "uint")
    if (DllCall("ws2_32\setsockopt", "ptr", this.socket, "int", 0xFFFF, "int", 0x0020, "ptr", &optval, "int", 4)=0)
      return 1
    return 0
  }
  disableBroadcast()
  {
    VarSetCapacity(optval, 4, 0)
    if (DllCall("ws2_32\setsockopt", "ptr", this.socket, "int", 0xFFFF, "int", 0x0020, "ptr", &optval, "int", 4)=0)
      return 1
    return 0
  }
}

RunCMD(CmdLine, WorkingDir:="", Codepage:="CP0", Fn:="RunCMD_Output") {  ;         RunCMD v0.94        
Local
Global A_Args

  Fn := IsFunc(Fn) ? Func(Fn) : 0
, DllCall("CreatePipe", "PtrP",hPipeR:=0, "PtrP",hPipeW:=0, "Ptr",0, "Int",0)
, DllCall("SetHandleInformation", "Ptr",hPipeW, "Int",1, "Int",1)
, DllCall("SetNamedPipeHandleState","Ptr",hPipeR, "UIntP",PIPE_NOWAIT:=1, "Ptr",0, "Ptr",0)

, P8 := (A_PtrSize=8)
, VarSetCapacity(SI, P8 ? 104 : 68, 0)                          ; STARTUPINFO structure      
, NumPut(P8 ? 104 : 68, SI)                                     ; size of STARTUPINFO
, NumPut(STARTF_USESTDHANDLES:=0x100, SI, P8 ? 60 : 44,"UInt")  ; dwFlags
, NumPut(hPipeW, SI, P8 ? 88 : 60)                              ; hStdOutput
, NumPut(hPipeW, SI, P8 ? 96 : 64)                              ; hStdError
, VarSetCapacity(PI, P8 ? 24 : 16)                              ; PROCESS_INFORMATION structure

  If not DllCall("CreateProcess", "Ptr",0, "Str",CmdLine, "Ptr",0, "Int",0, "Int",True
                ,"Int",0x08000000 | DllCall("GetPriorityClass", "Ptr",-1, "UInt"), "Int",0
                ,"Ptr",WorkingDir ? &WorkingDir : 0, "Ptr",&SI, "Ptr",&PI)  
     Return Format("{1:}", "", ErrorLevel := -1
                   ,DllCall("CloseHandle", "Ptr",hPipeW), DllCall("CloseHandle", "Ptr",hPipeR))

  DllCall("CloseHandle", "Ptr",hPipeW)
, A_Args.RunCMD := { "PID": NumGet(PI, P8? 16 : 8, "UInt") }      
, File := FileOpen(hPipeR, "h", Codepage)

, LineNum := 1,  sOutput := ""
  While (A_Args.RunCMD.PID + DllCall("Sleep", "Int",0))
    and DllCall("PeekNamedPipe", "Ptr",hPipeR, "Ptr",0, "Int",0, "Ptr",0, "Ptr",0, "Ptr",0)
        While A_Args.RunCMD.PID and (Line := File.ReadLine())
          sOutput .= Fn ? Fn.Call(Line, LineNum++) : Line

  A_Args.RunCMD.PID := 0
, hProcess := NumGet(PI, 0)
, hThread  := NumGet(PI, A_PtrSize)

, DllCall("GetExitCodeProcess", "Ptr",hProcess, "PtrP",ExitCode:=0)
, DllCall("CloseHandle", "Ptr",hProcess)
, DllCall("CloseHandle", "Ptr",hThread)
, DllCall("CloseHandle", "Ptr",hPipeR)

, ErrorLevel := ExitCode

Return sOutput  
}

Class AES
{
    Encrypt(string, password, alg)
    {
        len := this.StrPutVar(string, str_buf, 0, "UTF-8")
        this.Crypt(str_buf, len, password, alg, 1)
        return this.b64Encode(str_buf, len)
    }
    Decrypt(string, password, alg)
    {
        len := this.b64Decode(string, encr_Buf)
        sLen := this.Crypt(encr_Buf, len, password, alg, 0)
        sLen /= 2
        return StrGet(&encr_Buf, sLen, "UTF-8")
    }

    Crypt(ByRef encr_Buf, ByRef Buf_Len, password, ALG_ID, CryptMode := 1)
    {
        ; WinCrypt.h
        static MS_ENH_RSA_AES_PROV := "Microsoft Enhanced RSA and AES Cryptographic Provider"
        static PROV_RSA_AES        := 24
        static CRYPT_VERIFYCONTEXT := 0xF0000000
        static CALG_SHA1           := 0x00008004
        static CALG_SHA_256        := 0x0000800c
        static CALG_SHA_384        := 0x0000800d
        static CALG_SHA_512        := 0x0000800e
        static CALG_AES_128        := 0x0000660e ; KEY_LENGHT := 0x80  ; (128)
        static CALG_AES_192        := 0x0000660f ; KEY_LENGHT := 0xC0  ; (192)
        static CALG_AES_256        := 0x00006610 ; KEY_LENGHT := 0x100 ; (256)
        static KP_BLOCKLEN         := 8

        if !(DllCall("advapi32.dll\CryptAcquireContext", "Ptr*", hProv, "Ptr", 0, "Ptr", 0, "Uint", PROV_RSA_AES, "UInt", CRYPT_VERIFYCONTEXT))
            MsgBox % "*CryptAcquireContext (" DllCall("kernel32.dll\GetLastError") ")"

        if !(DllCall("advapi32.dll\CryptCreateHash", "Ptr", hProv, "Uint", CALG_SHA1, "Ptr", 0, "Uint", 0, "Ptr*", hHash))
            MsgBox % "*CryptCreateHash (" DllCall("kernel32.dll\GetLastError") ")"

        passLen := this.StrPutVar(password, passBuf, 0, "UTF-16")
        if !(DllCall("advapi32.dll\CryptHashData", "Ptr", hHash, "Ptr", &passBuf, "Uint", passLen, "Uint", 0))
            MsgBox % "*CryptHashData (" DllCall("kernel32.dll\GetLastError") ")"
        
        if !(DllCall("advapi32.dll\CryptDeriveKey", "Ptr", hProv, "Uint", CALG_AES_%ALG_ID%, "Ptr", hHash, "Uint", (ALG_ID << 0x10), "Ptr*", hKey)) ; KEY_LENGHT << 0x10
            MsgBox % "*CryptDeriveKey (" DllCall("kernel32.dll\GetLastError") ")"

        if !(DllCall("advapi32.dll\CryptGetKeyParam", "Ptr", hKey, "Uint", KP_BLOCKLEN, "Uint*", BlockLen, "Uint*", 4, "Uint", 0))
            MsgBox % "*CryptGetKeyParam (" DllCall("kernel32.dll\GetLastError") ")"
        BlockLen /= 8

        if (CryptMode)
            DllCall("advapi32.dll\CryptEncrypt", "Ptr", hKey, "Ptr", 0, "Uint", 1, "Uint", 0, "Ptr", &encr_Buf, "Uint*", Buf_Len, "Uint", Buf_Len + BlockLen)
        else
            DllCall("advapi32.dll\CryptDecrypt", "Ptr", hKey, "Ptr", 0, "Uint", 1, "Uint", 0, "Ptr", &encr_Buf, "Uint*", Buf_Len)

        DllCall("advapi32.dll\CryptDestroyKey", "Ptr", hKey)
        DllCall("advapi32.dll\CryptDestroyHash", "Ptr", hHash)
        DllCall("advapi32.dll\CryptReleaseContext", "Ptr", hProv, "UInt", 0)
        return Buf_Len
    }

    StrPutVar(string, ByRef var, addBufLen := 0, encoding := "UTF-8")
    {
        tlen := ((encoding = "UTF-8" || encoding = "CP1200") ? 2 : 1)
        str_len := StrPut(string, encoding) * tlen
        VarSetCapacity(var, str_len + addBufLen, 0)
        StrPut(string, &var, encoding)
        return str_len - tlen
    }

    b64Encode(ByRef VarIn, SizeIn)
    {
        static CRYPT_STRING_BASE64 := 0x00000001
        static CRYPT_STRING_NOCRLF := 0x40000000
        DllCall("crypt32.dll\CryptBinaryToStringA", "Ptr", &VarIn, "UInt", SizeIn, "Uint", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", 0, "UInt*", SizeOut)
        VarSetCapacity(VarOut, SizeOut, 0)
        DllCall("crypt32.dll\CryptBinaryToStringA", "Ptr", &VarIn, "UInt", SizeIn, "Uint", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", &VarOut, "UInt*", SizeOut)
        return StrGet(&VarOut, SizeOut, "CP0")
    }
    b64Decode(ByRef VarIn, ByRef VarOut)
    {
        static CRYPT_STRING_BASE64 := 0x00000001
        static CryptStringToBinary := "CryptStringToBinary" (A_IsUnicode ? "W" : "A")
        DllCall("crypt32.dll\" CryptStringToBinary, "Ptr", &VarIn, "UInt", 0, "Uint", CRYPT_STRING_BASE64, "Ptr", 0, "UInt*", SizeOut, "Ptr", 0, "Ptr", 0)
        VarSetCapacity(VarOut, SizeOut, 0)
        DllCall("crypt32.dll\" CryptStringToBinary, "Ptr", &VarIn, "UInt", 0, "Uint", CRYPT_STRING_BASE64, "Ptr", &VarOut, "UInt*", SizeOut, "Ptr", 0, "Ptr", 0)
        return SizeOut
    }
}