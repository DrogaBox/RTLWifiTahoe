; CmdPassphrase @ 0x10003ce10
0x10003ce10:	push	rbp
0x10003ce11:	mov	rbp, rsp
0x10003ce14:	sub	rsp, 0xe0
0x10003ce1b:	mov	rax, qword ptr [rip + 0x14f2c6]
0x10003ce22:	mov	rax, qword ptr [rax]
0x10003ce25:	mov	qword ptr [rbp - 8], rax
0x10003ce29:	mov	dword ptr [rbp - 0xa4], edi
0x10003ce2f:	mov	qword ptr [rbp - 0xb0], rsi
0x10003ce36:	mov	rax, qword ptr [rbp - 0xb0]
0x10003ce3d:	mov	rax, qword ptr [rax + 0x10]
0x10003ce41:	mov	qword ptr [rbp - 0xc0], rax
0x10003ce48:	mov	rdi, qword ptr [rbp - 0xc0]
0x10003ce4f:	call	0x10013ca64
0x10003ce54:	mov	ecx, eax
0x10003ce56:	mov	dword ptr [rbp - 0xb4], ecx
0x10003ce5c:	cmp	dword ptr [rbp - 0xb4], 8
0x10003ce63:	jl	0x10003ce76
0x10003ce69:	cmp	dword ptr [rbp - 0xb4], 0x3f
0x10003ce70:	jle	0x10003ce95
0x10003ce76:	mov	esi, dword ptr [rbp - 0xb4]
0x10003ce7c:	lea	rdi, [rip + 0x1088ff]  ; "Invalid passphrase length, %d, valid range is 8-63
"
0x10003ce83:	mov	al, 0
0x10003ce85:	call	0x10013c9fe
0x10003ce8a:	mov	dword ptr [rbp - 0xc4], eax
0x10003ce90:	jmp	0x10003cf19
0x10003ce95:	mov	eax, 0x98
0x10003ce9a:	mov	ecx, eax
0x10003ce9c:	lea	rdi, [rbp - 0xa0]
0x10003cea3:	mov	dword ptr [rbp - 0x1c], 0
0x10003ceaa:	mov	eax, dword ptr [rbp - 0xb4]
0x10003ceb0:	mov	dword ptr [rbp - 0x20], eax
0x10003ceb3:	mov	rsi, qword ptr [rbp - 0xc0]
0x10003ceba:	movsxd	rdx, dword ptr [rbp - 0x20]
0x10003cebe:	call	0x10013c8a8
0x10003cec3:	lea	rcx, [rbp - 0xa0]
0x10003ceca:	mov	edi, 0xff010305  ; OID? 0xff010305
0x10003cecf:	mov	rsi, rcx
0x10003ced2:	mov	edx, 0x98
0x10003ced7:	mov	qword ptr [rbp - 0xd0], rax
0x10003cede:	call	0x10003eda0
0x10003cee3:	cmp	eax, -1
0x10003cee6:	jne	0x10003cf05
0x10003ceec:	lea	rdi, [rip + 0x1088c3]  ; "Failed to set passphrase.
"
0x10003cef3:	mov	al, 0
0x10003cef5:	call	0x10013c9fe
0x10003cefa:	mov	dword ptr [rbp - 0xd4], eax
0x10003cf00:	jmp	0x10003cf19
0x10003cf05:	lea	rdi, [rip + 0x1088c5]  ; "Set passphrase success.
"
0x10003cf0c:	mov	al, 0
0x10003cf0e:	call	0x10013c9fe
0x10003cf13:	mov	dword ptr [rbp - 0xd8], eax
0x10003cf19:	mov	rax, qword ptr [rip + 0x14f1c8]
0x10003cf20:	mov	rax, qword ptr [rax]
0x10003cf23:	mov	rcx, qword ptr [rbp - 8]
0x10003cf27:	cmp	rax, rcx
0x10003cf2a:	jne	0x10003cf39
0x10003cf30:	add	rsp, 0xe0
0x10003cf37:	pop	rbp
0x10003cf38:	ret	
0x10003cf39:	call	0x10013c8c0
0x10003cf3e:	ud2	
0x10003cf40:	push	rbp
0x10003cf41:	mov	rbp, rsp
0x10003cf44:	sub	rsp, 0xe0
0x10003cf4b:	mov	rax, qword ptr [rip + 0x14f196]
0x10003cf52:	mov	rax, qword ptr [rax]
0x10003cf55:	mov	qword ptr [rbp - 8], rax
0x10003cf59:	mov	dword ptr [rbp - 0xa4], edi
0x10003cf5f:	mov	qword ptr [rbp - 0xb0], rsi
0x10003cf66:	mov	rax, qword ptr [rbp - 0xb0]
0x10003cf6d:	mov	rdi, qword ptr [rax + 0x10]
0x10003cf71:	call	0x10013c8e4
0x10003cf76:	mov	dword ptr [rbp - 0xb4], eax
0x10003cf7c:	cmp	dword ptr [rbp - 0xb4], 0
0x10003cf83:	jl	0x10003cf96
0x10003cf89:	cmp	dword ptr [rbp - 0xb4], 4
0x10003cf90:	jle	0x10003cfb5
0x10003cf96:	mov	esi, dword ptr [rbp - 0xb4]
0x10003cf9c:	lea	rdi, [rip + 0x108847]  ; "Invalid key index, %d, valid range is 0-3!
"
0x10003cfa3:	mov	al, 0
0x10003cfa5:	call	0x10013c9fe
0x10003cfaa:	mov	dword ptr [rbp - 0xc4], eax
0x10003cfb0:	jmp	0x10003d09a
0x10003cfb5:	mov	rax, qword ptr [rbp - 0xb0]
0x10003cfbc:	mov	rax, qword ptr [rax + 0x18]
0x10003cfc0:	mov	qword ptr [rbp - 0xc0], rax
0x10003cfc7:	mov	rdi, qword ptr [rbp - 0xc0]
0x10003cfce:	call	0x10013ca64
0x10003cfd3:	mov	ecx, eax
0x10003cfd5:	mov	dword ptr [rbp - 0xb8], ecx
0x10003cfdb:	cmp	dword ptr [rbp - 0xb8], 0xa
0x10003cfe2:	je	0x10003d014
0x10003cfe8:	cmp	dword ptr [rbp - 0xb8], 0x1a
0x10003cfef:	je	0x10003d014
0x10003cff5:	mov	esi, dword ptr [rbp - 0xb8]
0x10003cffb:	lea	rdi, [rip + 0x108814]  ; "Invalid key length, %d, valid range is 10 or 26 characters!
"
0x10003d002:	mov	al, 0
0x10003d004:	call	0x10013c9fe
0x10003d009:	mov	dword ptr [rbp - 0xc8], eax
0x10003d00f:	jmp	0x10003d09a
0x10003d014:	mov	eax, 0x98
0x10003d019:	mov	ecx, eax
0x10003d01b:	lea	rdi, [rbp - 0xa0]
0x10003d022:	mov	eax, dword ptr [rbp - 0xb4]
0x10003d028:	mov	dword ptr [rbp - 0x1c], eax
0x10003d02b:	mov	eax, dword ptr [rbp - 0xb8]
0x10003d031:	mov	dword ptr [rbp - 0x20], eax
0x10003d034:	mov	rsi, qword ptr [rbp - 0xc0]
0x10003d03b:	movsxd	rdx, dword ptr [rbp - 0x20]
0x10003d03f:	call	0x10013c8a8
0x10003d044:	lea	rcx, [rbp - 0xa0]
0x10003d04b:	mov	edi, 0xff070113  ; OID? 0xff070113
0x10003d050:	mov	rsi, rcx
0x10003d053:	mov	edx, 0x98
0x10003d058:	mov	qword ptr [rbp - 0xd0], rax
0x10003d05f:	call	0x10003eda0
0x10003d064:	cmp	eax, -1
0x10003d067:	jne	0x10003d086
0x10003d06d:	lea	rdi, [rip + 0x1087df]  ; "Failed to set wep key.
"
0x10003d074:	mov	al, 0
0x10003d076:	call	0x10013c9fe
0x10003d07b:	mov	dword ptr [rbp - 0xd4], eax
0x10003d081:	jmp	0x10003d09a
0x10003d086:	lea	rdi, [rip + 0x1087de]  ; "Set wep key success.
"
0x10003d08d:	mov	al, 0
0x10003d08f:	call	0x10013c9fe
0x10003d094:	mov	dword ptr [rbp - 0xd8], eax
0x10003d09a:	mov	rax, qword ptr [rip + 0x14f047]
0x10003d0a1:	mov	rax, qword ptr [rax]
0x10003d0a4:	mov	rcx, qword ptr [rbp - 8]
0x10003d0a8:	cmp	rax, rcx
0x10003d0ab:	jne	0x10003d0ba
0x10003d0b1:	add	rsp, 0xe0
0x10003d0b8:	pop	rbp
0x10003d0b9:	ret	
0x10003d0ba:	call	0x10013c8c0
0x10003d0bf:	ud2	
0x10003d0c1:	nop	word ptr cs:[rax + rax]
0x10003d0cb:	nop	dword ptr [rax + rax]
0x10003d0d0:	push	rbp
0x10003d0d1:	mov	rbp, rsp
0x10003d0d4:	sub	rsp, 0x20
0x10003d0d8:	xor	eax, eax
0x10003d0da:	mov	dword ptr [rbp - 4], edi
0x10003d0dd:	mov	qword ptr [rbp - 0x10], rsi
0x10003d0e1:	mov	edi, 0xd010115
0x10003d0e6:	mov	esi, eax
0x10003d0e8:	call	0x10003ef70
0x10003d0ed:	cmp	eax, -1
0x10003d0f0:	jne	0x10003d10c
0x10003d0f6:	lea	rdi, [rip + 0x108784]  ; "Failed to set disassociate.
"
0x10003d0fd:	mov	al, 0
0x10003d0ff:	call	0x10013c9fe
0x10003d104:	mov	dword ptr [rbp - 0x14], eax
0x10003d107:	jmp	0x10003d11d
0x10003d10c:	lea	rdi, [rip + 0x10878b]  ; "Disassociate 
"
0x10003d113:	mov	al, 0
0x10003d115:	call	0x10013c9fe
0x10003d11a:	mov	dword ptr [rbp - 0x18], eax
0x10003d11d:	add	rsp, 0x20
0x10003d121:	pop	rbp
0x10003d122:	ret	
0x10003d123:	nop	word ptr cs:[rax + rax]
0x10003d12d:	nop	dword ptr [rax]
0x10003d130:	push	rbp
0x10003d131:	mov	rbp, rsp
0x10003d134:	sub	rsp, 0x20
0x10003d138:	mov	dword ptr [rbp - 4], edi
0x10003d13b:	mov	qword ptr [rbp - 0x10], rsi
0x10003d13f:	lea	rsi, [rbp - 0x14]
0x10003d143:	mov	edi, 0xd010206
0x10003d148:	call	0x10003ebc0
0x10003d14d:	cmp	eax, -1
0x10003d150:	jne	0x10003d16c
0x10003d156:	lea	rdi, [rip + 0x108750]  ; "Failed to Query Rssi.
"
0x10003d15d:	mov	al, 0
0x10003d15f:	call	0x10013c9fe
0x10003d164:	mov	dword ptr [rbp - 0x18], eax
0x10003d167:	jmp	0x10003d180
0x10003d16c:	mov	esi, dword ptr [rbp - 0x14]
0x10003d16f:	lea	rdi, [rip + 0x10874e]  ; "RSSI: %d 
"
0x10003d176:	mov	al, 0
0x10003d178:	call	0x10013c9fe
0x10003d17d:	mov	dword ptr [rbp - 0x1c], eax
0x10003d180:	add	rsp, 0x20
0x10003d184:	pop	rbp
0x10003d185:	ret	
0x10003d186:	nop	word ptr cs:[rax + rax]