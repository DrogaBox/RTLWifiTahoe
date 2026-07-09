; CmdSsid @ 0x10003ae40
0x10003ae40:	push	rbp
0x10003ae41:	mov	rbp, rsp
0x10003ae44:	sub	rsp, 0xe0
0x10003ae4b:	xor	eax, eax
0x10003ae4d:	mov	ecx, 0x84
0x10003ae52:	mov	edx, ecx
0x10003ae54:	mov	r8, qword ptr [rip + 0x15128d]
0x10003ae5b:	mov	r8, qword ptr [r8]
0x10003ae5e:	mov	qword ptr [rbp - 8], r8
0x10003ae62:	mov	dword ptr [rbp - 0x94], edi
0x10003ae68:	mov	qword ptr [rbp - 0xa0], rsi
0x10003ae6f:	lea	rsi, [rbp - 0x90]
0x10003ae76:	mov	rdi, rsi
0x10003ae79:	mov	esi, eax
0x10003ae7b:	call	0x10013c9d4
0x10003ae80:	mov	rdx, qword ptr [rbp - 0xa0]
0x10003ae87:	mov	rdi, qword ptr [rdx + 0x10]
0x10003ae8b:	lea	rsi, [rip + 0x109fc7]
0x10003ae92:	call	0x10013ca52
0x10003ae97:	cmp	eax, 0
0x10003ae9a:	jne	0x10003af3e
0x10003aea0:	lea	rax, [rbp - 0x90]
0x10003aea7:	mov	edi, 0xff070102  ; OID? 0xff070102
0x10003aeac:	mov	rsi, rax
0x10003aeaf:	call	0x10003ebc0
0x10003aeb4:	mov	dword ptr [rbp - 0x10], eax
0x10003aeb7:	cmp	dword ptr [rbp - 0x10], 0
0x10003aebb:	jle	0x10003af39
0x10003aec1:	lea	rdi, [rip + 0x10a113]  ; "Query SSID : "
0x10003aec8:	mov	al, 0
0x10003aeca:	call	0x10013c9fe
0x10003aecf:	mov	dword ptr [rbp - 0xa4], 0
0x10003aed9:	mov	dword ptr [rbp - 0xac], eax
0x10003aedf:	mov	eax, dword ptr [rbp - 0xa4]
0x10003aee5:	cmp	eax, dword ptr [rbp - 0x10]
0x10003aee8:	jge	0x10003af25
0x10003aeee:	movsxd	rax, dword ptr [rbp - 0xa4]
0x10003aef5:	movsx	esi, byte ptr [rbp + rax - 0x90]
0x10003aefd:	lea	rdi, [rip + 0x109f17]
0x10003af04:	mov	al, 0
0x10003af06:	call	0x10013c9fe
0x10003af0b:	mov	dword ptr [rbp - 0xb0], eax
0x10003af11:	mov	eax, dword ptr [rbp - 0xa4]
0x10003af17:	add	eax, 1
0x10003af1a:	mov	dword ptr [rbp - 0xa4], eax
0x10003af20:	jmp	0x10003aedf
0x10003af25:	lea	rdi, [rip + 0x112f44]
0x10003af2c:	mov	al, 0
0x10003af2e:	call	0x10013c9fe
0x10003af33:	mov	dword ptr [rbp - 0xb4], eax
0x10003af39:	jmp	0x10003b116
0x10003af3e:	mov	rax, qword ptr [rbp - 0xa0]
0x10003af45:	mov	rdi, qword ptr [rax + 0x10]
0x10003af49:	lea	rsi, [rip + 0x109f4a]
0x10003af50:	call	0x10013ca52
0x10003af55:	cmp	eax, 0
0x10003af58:	jne	0x10003b0fd
0x10003af5e:	cmp	dword ptr [rbp - 0x94], 4
0x10003af65:	jl	0x10003b0e4
0x10003af6b:	mov	rax, qword ptr [rbp - 0xa0]
0x10003af72:	mov	rdi, qword ptr [rax + 0x18]
0x10003af76:	call	0x10013ca64
0x10003af7b:	cmp	rax, 0x80  ; size? 0x80
0x10003af81:	ja	0x10003b0cb
0x10003af87:	mov	dword ptr [rbp - 0xa8], 0
0x10003af91:	movsxd	rax, dword ptr [rbp - 0xa8]
0x10003af98:	mov	rcx, qword ptr [rbp - 0xa0]
0x10003af9f:	mov	rdi, qword ptr [rcx + 0x18]
0x10003afa3:	mov	qword ptr [rbp - 0xc0], rax
0x10003afaa:	call	0x10013ca64
0x10003afaf:	mov	rcx, qword ptr [rbp - 0xc0]
0x10003afb6:	cmp	rcx, rax
0x10003afb9:	jae	0x10003aff6
0x10003afbf:	mov	rax, qword ptr [rbp - 0xa0]
0x10003afc6:	mov	rax, qword ptr [rax + 0x18]
0x10003afca:	movsxd	rcx, dword ptr [rbp - 0xa8]
0x10003afd1:	mov	dl, byte ptr [rax + rcx]
0x10003afd4:	movsxd	rax, dword ptr [rbp - 0xa8]
0x10003afdb:	mov	byte ptr [rbp + rax - 0x90], dl
0x10003afe2:	mov	eax, dword ptr [rbp - 0xa8]
0x10003afe8:	add	eax, 1
0x10003afeb:	mov	dword ptr [rbp - 0xa8], eax
0x10003aff1:	jmp	0x10003af91
0x10003aff6:	mov	rax, qword ptr [rbp - 0xa0]
0x10003affd:	mov	rdi, qword ptr [rax + 0x18]
0x10003b001:	call	0x10013ca64
0x10003b006:	mov	ecx, eax
0x10003b008:	mov	dword ptr [rbp - 0x10], ecx
0x10003b00b:	mov	rax, qword ptr [rbp - 0xa0]
0x10003b012:	mov	rdi, qword ptr [rax + 0x18]
0x10003b016:	call	0x10013ca64
0x10003b01b:	lea	rdi, [rip + 0x109fc7]  ; "strlen(argv[3]: %ld
 "
0x10003b022:	mov	rsi, rax
0x10003b025:	mov	al, 0
0x10003b027:	call	0x10013c9fe
0x10003b02c:	lea	rsi, [rbp - 0x90]
0x10003b033:	mov	edi, 0xff070102  ; OID? 0xff070102
0x10003b038:	mov	edx, 0x84
0x10003b03d:	mov	dword ptr [rbp - 0xc4], eax
0x10003b043:	call	0x10003eda0
0x10003b048:	cmp	eax, -1
0x10003b04b:	jne	0x10003b071
0x10003b051:	lea	rsi, [rbp - 0x90]
0x10003b058:	lea	rdi, [rip + 0x109fa0]  ; "Failed to set SSID: %s
"
0x10003b05f:	mov	al, 0
0x10003b061:	call	0x10013c9fe
0x10003b066:	mov	dword ptr [rbp - 0xc8], eax
0x10003b06c:	jmp	0x10003b0c6
0x10003b071:	xor	esi, esi
0x10003b073:	mov	edi, 0xff01041b  ; OID? 0xff01041b
0x10003b078:	call	0x10003ef70
0x10003b07d:	cmp	eax, -1
0x10003b080:	jne	0x10003b0a6
0x10003b086:	lea	rsi, [rbp - 0x90]
0x10003b08d:	lea	rdi, [rip + 0x109f6b]  ; "Failed to set SSID: %s
"
0x10003b094:	mov	al, 0
0x10003b096:	call	0x10013c9fe
0x10003b09b:	mov	dword ptr [rbp - 0xcc], eax
0x10003b0a1:	jmp	0x10003b0c1
0x10003b0a6:	lea	rsi, [rbp - 0x90]
0x10003b0ad:	lea	rdi, [rip + 0x109f63]  ; "Set SSID (%s) success.
"
0x10003b0b4:	mov	al, 0
0x10003b0b6:	call	0x10013c9fe
0x10003b0bb:	mov	dword ptr [rbp - 0xd0], eax
0x10003b0c1:	jmp	0x10003b0c6
0x10003b0c6:	jmp	0x10003b0df
0x10003b0cb:	lea	rdi, [rip + 0x109f5d]  ; "Error input SSID.
"
0x10003b0d2:	mov	al, 0
0x10003b0d4:	call	0x10013c9fe
0x10003b0d9:	mov	dword ptr [rbp - 0xd4], eax
0x10003b0df:	jmp	0x10003b0f8
0x10003b0e4:	lea	rdi, [rip + 0x109f57]  ; "Usage: MacAccess -ssid s [ssid].
"
0x10003b0eb:	mov	al, 0
0x10003b0ed:	call	0x10013c9fe
0x10003b0f2:	mov	dword ptr [rbp - 0xd8], eax
0x10003b0f8:	jmp	0x10003b111
0x10003b0fd:	lea	rdi, [rip + 0x109f60]  ; "Usage: MacAccess -ssid [g|s] [ssid].
"
0x10003b104:	mov	al, 0
0x10003b106:	call	0x10013c9fe
0x10003b10b:	mov	dword ptr [rbp - 0xdc], eax
0x10003b111:	jmp	0x10003b116
0x10003b116:	mov	rax, qword ptr [rip + 0x150fcb]
0x10003b11d:	mov	rax, qword ptr [rax]
0x10003b120:	mov	rcx, qword ptr [rbp - 8]
0x10003b124:	cmp	rax, rcx
0x10003b127:	jne	0x10003b136
0x10003b12d:	add	rsp, 0xe0
0x10003b134:	pop	rbp
0x10003b135:	ret	
0x10003b136:	call	0x10013c8c0
0x10003b13b:	ud2	
0x10003b13d:	nop	dword ptr [rax]
0x10003b140:	push	rbp
0x10003b141:	mov	rbp, rsp
0x10003b144:	sub	rsp, 0x90
0x10003b14b:	mov	dword ptr [rbp - 4], edi
0x10003b14e:	mov	qword ptr [rbp - 0x10], rsi
0x10003b152:	mov	dword ptr [rbp - 0x14], 0
0x10003b159:	mov	rsi, qword ptr [rbp - 0x10]
0x10003b15d:	mov	rdi, qword ptr [rsi + 0x10]
0x10003b161:	lea	rsi, [rip + 0x109cf1]
0x10003b168:	call	0x10013ca52
0x10003b16d:	cmp	eax, 0
0x10003b170:	jne	0x10003b3a9
0x10003b176:	lea	rax, [rbp - 0x14]
0x10003b17a:	mov	edi, 0xff818500  ; OID? 0xff818500
0x10003b17f:	mov	rsi, rax
0x10003b182:	call	0x10003ebc0
0x10003b187:	cmp	eax, -1
0x10003b18a:	jne	0x10003b1a6
0x10003b190:	lea	rdi, [rip + 0x105c81]  ; "Failed to get wireless mode.
"
0x10003b197:	mov	al, 0
0x10003b199:	call	0x10013c9fe
0x10003b19e:	mov	dword ptr [rbp - 0x18], eax
0x10003b1a1:	jmp	0x10003b3a4
0x10003b1a6:	lea	rdi, [rip + 0x109edd]  ; "Get wireless mode : "
0x10003b1ad:	xor	eax, eax
0x10003b1af:	mov	cl, al
0x10003b1b1:	mov	al, cl
0x10003b1b3:	call	0x10013c9fe
0x10003b1b8:	mov	edx, dword ptr [rbp - 0x14]
0x10003b1bb:	test	edx, edx
0x10003b1bd:	mov	dword ptr [rbp - 0x1c], eax
0x10003b1c0:	mov	dword ptr [rbp - 0x20], edx
0x10003b1c3:	je	0x10003b29c
0x10003b1c9:	jmp	0x10003b1ce
0x10003b1ce:	mov	eax, dword ptr [rbp - 0x20]
0x10003b1d1:	sub	eax, 1
0x10003b1d4:	mov	dword ptr [rbp - 0x24], eax
0x10003b1d7:	je	0x10003b2b2
0x10003b1dd:	jmp	0x10003b1e2
0x10003b1e2:	mov	eax, dword ptr [rbp - 0x20]
0x10003b1e5:	sub	eax, 2
0x10003b1e8:	mov	dword ptr [rbp - 0x28], eax
0x10003b1eb:	je	0x10003b2c8
0x10003b1f1:	jmp	0x10003b1f6
0x10003b1f6:	mov	eax, dword ptr [rbp - 0x20]
0x10003b1f9:	sub	eax, 4
0x10003b1fc:	mov	dword ptr [rbp - 0x2c], eax
0x10003b1ff:	je	0x10003b2de
0x10003b205:	jmp	0x10003b20a
0x10003b20a:	mov	eax, dword ptr [rbp - 0x20]
0x10003b20d:	sub	eax, 8
0x10003b210:	mov	dword ptr [rbp - 0x30], eax
0x10003b213:	je	0x10003b2f4
0x10003b219:	jmp	0x10003b21e
0x10003b21e:	mov	eax, dword ptr [rbp - 0x20]
0x10003b221:	sub	eax, 0x10
0x10003b224:	mov	dword ptr [rbp - 0x34], eax
0x10003b227:	je	0x10003b30a
0x10003b22d:	jmp	0x10003b232
0x10003b232:	mov	eax, dword ptr [rbp - 0x20]
0x10003b235:	sub	eax, 0x20
0x10003b238:	mov	dword ptr [rbp - 0x38], eax