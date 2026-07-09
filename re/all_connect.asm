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

; CmdSetInformation @ 0x10003c1e0
0x10003c1e0:	push	rbp
0x10003c1e1:	mov	rbp, rsp
0x10003c1e4:	sub	rsp, 0xa40
0x10003c1eb:	mov	rax, qword ptr [rip + 0x14fef6]
0x10003c1f2:	mov	rax, qword ptr [rax]
0x10003c1f5:	mov	qword ptr [rbp - 8], rax
0x10003c1f9:	mov	dword ptr [rbp - 0x9e4], edi
0x10003c1ff:	mov	qword ptr [rbp - 0x9f0], rsi
0x10003c206:	mov	qword ptr [rbp - 0xa08], 0x9d4  ; size? 0x9d4
0x10003c211:	mov	rax, qword ptr [rbp - 0xa08]
0x10003c218:	mov	qword ptr [rbp - 0xa10], rax
0x10003c21f:	mov	dword ptr [rbp - 0x9dc], 0x9c4
0x10003c229:	mov	esi, dword ptr [rbp - 0x9dc]
0x10003c22f:	lea	rdi, [rip + 0x1090fe]  ; "CmdSetInformation::setOid.InformationBufferLength= %d
"
0x10003c236:	mov	al, 0
0x10003c238:	call	0x10013c9fe
0x10003c23d:	mov	rdi, qword ptr [rbp - 0x9f0]
0x10003c244:	mov	rdi, qword ptr [rdi + 0x10]
0x10003c248:	mov	dword ptr [rbp - 0xa18], eax
0x10003c24e:	call	0x10003d500
0x10003c253:	mov	dword ptr [rbp - 0x9fc], eax
0x10003c259:	mov	eax, dword ptr [rbp - 0x9e4]
0x10003c25f:	sub	eax, 3
0x10003c262:	mov	rdi, qword ptr [rbp - 0x9f0]
0x10003c269:	add	rdi, 0x18
0x10003c26d:	lea	rcx, [rbp - 0x9e0]
0x10003c274:	mov	rdx, rcx
0x10003c277:	add	rdx, 4
0x10003c27b:	add	rcx, 0x10
0x10003c27f:	mov	qword ptr [rbp - 0xa20], rdi
0x10003c286:	mov	edi, eax
0x10003c288:	mov	rsi, qword ptr [rbp - 0xa20]
0x10003c28f:	call	0x10003d740
0x10003c294:	mov	dword ptr [rbp - 0xa14], eax
0x10003c29a:	cmp	dword ptr [rbp - 0xa14], 0
0x10003c2a1:	jne	0x10003c2c6
0x10003c2a7:	mov	esi, dword ptr [rbp - 0x9fc]
0x10003c2ad:	lea	rdi, [rip + 0x1090b7]  ; "CmdSetInformation(): OID %#X, invalid arguments
"
0x10003c2b4:	mov	al, 0
0x10003c2b6:	call	0x10013c9fe
0x10003c2bb:	mov	dword ptr [rbp - 0xa24], eax
0x10003c2c1:	jmp	0x10003c3a0
0x10003c2c6:	mov	eax, dword ptr [rbp - 0x9fc]
0x10003c2cc:	mov	dword ptr [rbp - 0x9e0], eax
0x10003c2d2:	mov	dword ptr [rbp - 0x9d8], 0
0x10003c2dc:	mov	dword ptr [rbp - 0x9d4], 0
0x10003c2e6:	lea	rdi, [rbp - 0x9f8]
0x10003c2ed:	call	0x10003d900
0x10003c2f2:	cmp	al, 0
0x10003c2f4:	jne	0x10003c2ff
0x10003c2fa:	jmp	0x10003c3a0
0x10003c2ff:	mov	eax, 0x9d4  ; size? 0x9d4
0x10003c304:	mov	ecx, eax
0x10003c306:	mov	edi, dword ptr [rbp - 0x9f8]
0x10003c30c:	lea	rdx, [rbp - 0x9e0]
0x10003c313:	mov	rsi, rdx
0x10003c316:	mov	eax, 0xa
0x10003c31b:	mov	qword ptr [rbp - 0xa30], rsi
0x10003c322:	mov	esi, eax
0x10003c324:	mov	r8, qword ptr [rbp - 0xa30]
0x10003c32b:	mov	qword ptr [rbp - 0xa38], rdx
0x10003c332:	mov	rdx, r8
0x10003c335:	mov	r8, qword ptr [rbp - 0xa38]
0x10003c33c:	lea	r9, [rbp - 0xa10]
0x10003c343:	call	0x10013c788
0x10003c348:	mov	dword ptr [rbp - 0x9f4], eax
0x10003c34e:	cmp	dword ptr [rbp - 0x9f4], 0
0x10003c355:	je	0x10003c37a
0x10003c35b:	mov	esi, dword ptr [rbp - 0x9fc]
0x10003c361:	lea	rdi, [rip + 0x109034]  ; "CmdSetInformation::Can not set the OID 0x%X!
"
0x10003c368:	mov	al, 0
0x10003c36a:	call	0x10013c9fe
0x10003c36f:	mov	dword ptr [rbp - 0xa3c], eax
0x10003c375:	jmp	0x10003c394
0x10003c37a:	mov	esi, dword ptr [rbp - 0x9fc]
0x10003c380:	lea	rdi, [rip + 0x109043]  ; "CmdSetInformation::Set OID 0x%X sucessfully
"
0x10003c387:	mov	al, 0
0x10003c389:	call	0x10013c9fe
0x10003c38e:	mov	dword ptr [rbp - 0xa40], eax
0x10003c394:	lea	rdi, [rbp - 0x9f8]
0x10003c39b:	call	0x10003dae0
0x10003c3a0:	mov	rax, qword ptr [rip + 0x14fd41]
0x10003c3a7:	mov	rax, qword ptr [rax]
0x10003c3aa:	mov	rcx, qword ptr [rbp - 8]
0x10003c3ae:	cmp	rax, rcx
0x10003c3b1:	jne	0x10003c3c0
0x10003c3b7:	add	rsp, 0xa40
0x10003c3be:	pop	rbp
0x10003c3bf:	ret	
0x10003c3c0:	call	0x10013c8c0
0x10003c3c5:	ud2	
0x10003c3c7:	nop	word ptr [rax + rax]
0x10003c3d0:	push	rbp
0x10003c3d1:	mov	rbp, rsp
0x10003c3d4:	sub	rsp, 0x40  ; size? 0x40
0x10003c3d8:	mov	dword ptr [rbp - 4], edi
0x10003c3db:	mov	qword ptr [rbp - 0x10], rsi

; CmdAkm @ 0x10003c770
0x10003c770:	push	rbp
0x10003c771:	mov	rbp, rsp
0x10003c774:	sub	rsp, 0x60
0x10003c778:	mov	dword ptr [rbp - 4], edi
0x10003c77b:	mov	qword ptr [rbp - 0x10], rsi
0x10003c77f:	mov	dword ptr [rbp - 0x14], 0
0x10003c786:	mov	dword ptr [rbp - 0x18], 0
0x10003c78d:	mov	rsi, qword ptr [rbp - 0x10]
0x10003c791:	mov	rdi, qword ptr [rsi + 0x10]
0x10003c795:	lea	rsi, [rip + 0x1086bd]
0x10003c79c:	call	0x10013ca52
0x10003c7a1:	cmp	eax, 0
0x10003c7a4:	jne	0x10003c8c9
0x10003c7aa:	lea	rax, [rbp - 0x14]
0x10003c7ae:	mov	edi, 0xff010194  ; OID? 0xff010194
0x10003c7b3:	mov	rsi, rax
0x10003c7b6:	call	0x10003ebc0
0x10003c7bb:	cmp	eax, -1
0x10003c7be:	jne	0x10003c7da
0x10003c7c4:	lea	rdi, [rip + 0x108dcf]  ; "Failed to get encryption method.
"
0x10003c7cb:	mov	al, 0
0x10003c7cd:	call	0x10013c9fe
0x10003c7d2:	mov	dword ptr [rbp - 0x1c], eax
0x10003c7d5:	jmp	0x10003ca72
0x10003c7da:	mov	eax, dword ptr [rbp - 0x14]
0x10003c7dd:	mov	ecx, eax
0x10003c7df:	mov	rdx, rcx
0x10003c7e2:	sub	rdx, 6
0x10003c7e6:	mov	qword ptr [rbp - 0x28], rcx
0x10003c7ea:	mov	qword ptr [rbp - 0x30], rdx
0x10003c7ee:	ja	0x10003c8b0
0x10003c7f4:	lea	rax, [rip + 0x27d]  ; [0x10003ca78]=0xfffffd90
0x10003c7fb:	mov	rcx, qword ptr [rbp - 0x28]
0x10003c7ff:	movsxd	rdx, dword ptr [rax + rcx*4]
0x10003c803:	add	rdx, rax
0x10003c806:	jmp	rdx
0x10003c808:	lea	rdi, [rip + 0x108dad]  ; "open
"
0x10003c80f:	mov	al, 0
0x10003c811:	call	0x10013c9fe
0x10003c816:	mov	dword ptr [rbp - 0x34], eax
0x10003c819:	jmp	0x10003c8c4
0x10003c81e:	lea	rax, [rbp - 0x18]
0x10003c822:	mov	edi, 0xff01041a  ; OID? 0xff01041a
0x10003c827:	mov	rsi, rax
0x10003c82a:	call	0x10003ebc0
0x10003c82f:	cmp	eax, -1
0x10003c832:	jne	0x10003c84e
0x10003c838:	lea	rdi, [rip + 0x108d83]  ; "Failed to get shared key authentication mode.
"
0x10003c83f:	mov	al, 0
0x10003c841:	call	0x10013c9fe
0x10003c846:	mov	dword ptr [rbp - 0x38], eax
0x10003c849:	jmp	0x10003ca72
0x10003c84e:	cmp	dword ptr [rbp - 0x18], 0
0x10003c852:	je	0x10003c86e
0x10003c858:	lea	rdi, [rip + 0x108d92]  ; "sharedkey
"
0x10003c85f:	mov	al, 0
0x10003c861:	call	0x10013c9fe
0x10003c866:	mov	dword ptr [rbp - 0x3c], eax
0x10003c869:	jmp	0x10003c87f
0x10003c86e:	lea	rdi, [rip + 0x108d47]  ; "open
"
0x10003c875:	mov	al, 0
0x10003c877:	call	0x10013c9fe
0x10003c87c:	mov	dword ptr [rbp - 0x40], eax
0x10003c87f:	jmp	0x10003c8c4
0x10003c884:	lea	rdi, [rip + 0x108d71]  ; "wpa-psk
"
0x10003c88b:	mov	al, 0
0x10003c88d:	call	0x10013c9fe
0x10003c892:	mov	dword ptr [rbp - 0x44], eax
0x10003c895:	jmp	0x10003c8c4
0x10003c89a:	lea	rdi, [rip + 0x108d64]  ; "wpa2-psk
"
0x10003c8a1:	mov	al, 0
0x10003c8a3:	call	0x10013c9fe
0x10003c8a8:	mov	dword ptr [rbp - 0x48], eax
0x10003c8ab:	jmp	0x10003c8c4
0x10003c8b0:	mov	esi, dword ptr [rbp - 0x14]
0x10003c8b3:	lea	rdi, [rip + 0x108d55]  ; "unknown encryption method(%d)!
"
0x10003c8ba:	mov	al, 0
0x10003c8bc:	call	0x10013c9fe
0x10003c8c1:	mov	dword ptr [rbp - 0x4c], eax
0x10003c8c4:	jmp	0x10003ca72
0x10003c8c9:	mov	rax, qword ptr [rbp - 0x10]
0x10003c8cd:	mov	rdi, qword ptr [rax + 0x10]
0x10003c8d1:	lea	rsi, [rip + 0x1085c2]
0x10003c8d8:	call	0x10013ca52
0x10003c8dd:	cmp	eax, 0
0x10003c8e0:	jne	0x10003ca50
0x10003c8e6:	cmp	dword ptr [rbp - 4], 4
0x10003c8ea:	jl	0x10003ca2e
0x10003c8f0:	mov	rax, qword ptr [rbp - 0x10]
0x10003c8f4:	mov	rdi, qword ptr [rax + 0x18]
0x10003c8f8:	lea	rsi, [rip + 0x108d30]  ; "sharedkey"
0x10003c8ff:	call	0x10013ca52
0x10003c904:	cmp	eax, 0
0x10003c907:	jne	0x10003c919
0x10003c90d:	mov	dword ptr [rbp - 0x18], 1
0x10003c914:	jmp	0x10003c9c0
0x10003c919:	mov	dword ptr [rbp - 0x18], 0
0x10003c920:	mov	rax, qword ptr [rbp - 0x10]
0x10003c924:	mov	rdi, qword ptr [rax + 0x18]
0x10003c928:	lea	rsi, [rip + 0x108d0a]  ; "open"
0x10003c92f:	call	0x10013ca52
0x10003c934:	cmp	eax, 0
0x10003c937:	jne	0x10003c949
0x10003c93d:	mov	dword ptr [rbp - 0x14], 0
0x10003c944:	jmp	0x10003c9bb
0x10003c949:	mov	rax, qword ptr [rbp - 0x10]
0x10003c94d:	mov	rdi, qword ptr [rax + 0x18]
0x10003c951:	lea	rsi, [rip + 0x108ce6]  ; "wpa-psk"
0x10003c958:	call	0x10013ca52
0x10003c95d:	cmp	eax, 0
0x10003c960:	jne	0x10003c972
0x10003c966:	mov	dword ptr [rbp - 0x14], 3
0x10003c96d:	jmp	0x10003c9b6
0x10003c972:	mov	rax, qword ptr [rbp - 0x10]
0x10003c976:	mov	rdi, qword ptr [rax + 0x18]
0x10003c97a:	lea	rsi, [rip + 0x108cc5]  ; "wpa2-psk"
0x10003c981:	call	0x10013ca52
0x10003c986:	cmp	eax, 0
0x10003c989:	jne	0x10003c99b
0x10003c98f:	mov	dword ptr [rbp - 0x14], 6
0x10003c996:	jmp	0x10003c9b1
0x10003c99b:	lea	rdi, [rip + 0x108cad]  ; "unknown AKM!"
0x10003c9a2:	mov	al, 0
0x10003c9a4:	call	0x10013c9fe
0x10003c9a9:	mov	dword ptr [rbp - 0x50], eax
0x10003c9ac:	jmp	0x10003ca72
0x10003c9b1:	jmp	0x10003c9b6
0x10003c9b6:	jmp	0x10003c9bb
0x10003c9bb:	jmp	0x10003c9c0
0x10003c9c0:	mov	esi, dword ptr [rbp - 0x18]
0x10003c9c3:	mov	edi, 0xff01041a  ; OID? 0xff01041a
0x10003c9c8:	call	0x10003ef70
0x10003c9cd:	cmp	eax, -1
0x10003c9d0:	jne	0x10003c9ec
0x10003c9d6:	lea	rdi, [rip + 0x108c7f]  ; "Failed to set shared key auth.
"
0x10003c9dd:	mov	al, 0
0x10003c9df:	call	0x10013c9fe
0x10003c9e4:	mov	dword ptr [rbp - 0x54], eax
0x10003c9e7:	jmp	0x10003ca72
0x10003c9ec:	mov	esi, dword ptr [rbp - 0x14]
0x10003c9ef:	mov	edi, 0xff010194  ; OID? 0xff010194
0x10003c9f4:	call	0x10003ef70
0x10003c9f9:	cmp	eax, -1
0x10003c9fc:	jne	0x10003ca18
0x10003ca02:	lea	rdi, [rip + 0x108c73]  ; "Failed to set AKM.
"
0x10003ca09:	mov	al, 0
0x10003ca0b:	call	0x10013c9fe
0x10003ca10:	mov	dword ptr [rbp - 0x58], eax
0x10003ca13:	jmp	0x10003ca29
0x10003ca18:	lea	rdi, [rip + 0x108c71]  ; "Set AKM success.
"
0x10003ca1f:	mov	al, 0
0x10003ca21:	call	0x10013c9fe
0x10003ca26:	mov	dword ptr [rbp - 0x5c], eax
0x10003ca29:	jmp	0x10003ca4b
0x10003ca2e:	movsxd	rax, dword ptr [rip + 0x1764eb]  ; [0x1001b2f20]=0xffffffff
0x10003ca35:	shl	rax, 5
0x10003ca39:	lea	rcx, [rip + 0x1764f0]
0x10003ca40:	add	rcx, rax
0x10003ca43:	mov	rdi, rcx
0x10003ca46:	call	0x10003f120
0x10003ca4b:	jmp	0x10003ca6d
0x10003ca50:	movsxd	rax, dword ptr [rip + 0x1764c9]  ; [0x1001b2f20]=0xffffffff
0x10003ca57:	shl	rax, 5
0x10003ca5b:	lea	rcx, [rip + 0x1764ce]
0x10003ca62:	add	rcx, rax
0x10003ca65:	mov	rdi, rcx
0x10003ca68:	call	0x10003f120
0x10003ca6d:	jmp	0x10003ca72
0x10003ca72:	add	rsp, 0x60
0x10003ca76:	pop	rbp
0x10003ca77:	ret	
0x10003ca78:	nop	
0x10003ca79:	std	

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

; CmdScan @ 0x10003d190
0x10003d190:	push	rbp
0x10003d191:	mov	rbp, rsp
0x10003d194:	sub	rsp, 0xc80a0
0x10003d19b:	xor	eax, eax
0x10003d19d:	mov	dword ptr [rbp - 4], edi
0x10003d1a0:	mov	qword ptr [rbp - 0x10], rsi
0x10003d1a4:	mov	dword ptr [rbp - 0x18], 0
0x10003d1ab:	mov	dword ptr [rbp - 0x1c], 0
0x10003d1b2:	lea	rsi, [rbp - 0xc8030]
0x10003d1b9:	mov	qword ptr [rbp - 0xc8038], rsi
0x10003d1c0:	mov	rsi, qword ptr [rbp - 0xc8038]
0x10003d1c7:	mov	dword ptr [rsi + 0xc8000], 0
0x10003d1d1:	mov	edi, 0xff07011a  ; OID? 0xff07011a
0x10003d1d6:	mov	esi, eax
0x10003d1d8:	call	0x10003ef70
0x10003d1dd:	lea	rcx, [rbp - 0x18]
0x10003d1e1:	mov	edi, 0xff0101bd  ; OID? 0xff0101bd
0x10003d1e6:	mov	rsi, rcx
0x10003d1e9:	mov	dword ptr [rbp - 0xc8044], eax
0x10003d1ef:	call	0x10003ebc0
0x10003d1f4:	mov	dword ptr [rbp - 0xc8048], eax
0x10003d1fa:	cmp	dword ptr [rbp - 0x18], 0
0x10003d1fe:	je	0x10003d230
0x10003d204:	mov	edi, 1
0x10003d209:	call	0x10013ca34
0x10003d20e:	lea	rcx, [rbp - 0x18]
0x10003d212:	mov	edi, 0xff0101bd  ; OID? 0xff0101bd
0x10003d217:	mov	rsi, rcx
0x10003d21a:	mov	dword ptr [rbp - 0xc804c], eax
0x10003d220:	call	0x10003ebc0
0x10003d225:	mov	dword ptr [rbp - 0xc8050], eax
0x10003d22b:	jmp	0x10003d1fa
0x10003d230:	lea	rax, [rbp - 0x1c]
0x10003d234:	mov	edi, 0xff010419  ; OID? 0xff010419
0x10003d239:	mov	rsi, rax
0x10003d23c:	call	0x10003ebc0
0x10003d241:	cmp	eax, 0
0x10003d244:	je	0x10003d40e
0x10003d24a:	lea	rdi, [rbp - 0x20]
0x10003d24e:	call	0x10003d900
0x10003d253:	cmp	al, 0
0x10003d255:	jne	0x10003d260
0x10003d25b:	jmp	0x10003d422
0x10003d260:	cmp	dword ptr [rbp - 0x1c], 0x200
0x10003d267:	jle	0x10003d27d
0x10003d26d:	mov	eax, 0x200
0x10003d272:	mov	dword ptr [rbp - 0xc8054], eax
0x10003d278:	jmp	0x10003d286
0x10003d27d:	mov	eax, dword ptr [rbp - 0x1c]
0x10003d280:	mov	dword ptr [rbp - 0xc8054], eax
0x10003d286:	mov	eax, dword ptr [rbp - 0xc8054]
0x10003d28c:	mov	dword ptr [rbp - 0x30], eax
0x10003d28f:	mov	qword ptr [rbp - 0xc8040], 0x640  ; size? 0x640
0x10003d29a:	mov	qword ptr [rbp - 0x28], 0
0x10003d2a2:	mov	rax, qword ptr [rbp - 0x28]
0x10003d2a6:	mov	rcx, qword ptr [rbp - 0xc8038]
0x10003d2ad:	movsxd	rcx, dword ptr [rcx + 0xc8000]
0x10003d2b4:	cmp	rax, rcx
0x10003d2b7:	jae	0x10003d400
0x10003d2bd:	xor	esi, esi
0x10003d2bf:	mov	rcx, 0xffffffffffffffff
0x10003d2c6:	lea	rax, [rbp - 0xc8030]
0x10003d2cd:	imul	rdx, qword ptr [rbp - 0x28], 0x640  ; size? 0x640
0x10003d2d5:	add	rax, rdx
0x10003d2d8:	mov	rdx, qword ptr [rbp - 0xc8040]
0x10003d2df:	mov	rdi, rax
0x10003d2e2:	call	0x10013c8b4
0x10003d2e7:	xor	esi, esi
0x10003d2e9:	xor	r8d, r8d
0x10003d2ec:	mov	ecx, r8d
0x10003d2ef:	mov	edi, dword ptr [rbp - 0x20]
0x10003d2f2:	mov	rdx, qword ptr [rbp - 0xc8038]
0x10003d2f9:	imul	r9, qword ptr [rbp - 0x28], 0x640  ; size? 0x640
0x10003d301:	add	rdx, r9
0x10003d304:	lea	r9, [rbp - 0x28]
0x10003d308:	mov	qword ptr [rbp - 0xc8060], rdx
0x10003d30f:	mov	rdx, r9
0x10003d312:	mov	r8d, 1
0x10003d318:	mov	qword ptr [rbp - 0xc8068], rcx
0x10003d31f:	mov	ecx, r8d
0x10003d322:	mov	r8, qword ptr [rbp - 0xc8068]
0x10003d329:	mov	r9, qword ptr [rbp - 0xc8068]
0x10003d330:	mov	qword ptr [rsp], 0
0x10003d338:	mov	qword ptr [rsp + 8], 0
0x10003d341:	mov	r10, qword ptr [rbp - 0xc8060]
0x10003d348:	mov	qword ptr [rsp + 0x10], r10
0x10003d34d:	lea	r11, [rbp - 0xc8040]
0x10003d354:	mov	qword ptr [rsp + 0x18], r11
0x10003d359:	mov	qword ptr [rbp - 0xc8070], rax
0x10003d360:	call	0x10013c77c
0x10003d365:	mov	dword ptr [rbp - 0x14], eax
0x10003d368:	cmp	dword ptr [rbp - 0x14], 0
0x10003d36c:	jne	0x10003d3d2
0x10003d372:	mov	rax, qword ptr [rbp - 0x28]
0x10003d376:	mov	ecx, eax
0x10003d378:	mov	rax, qword ptr [rbp - 0xc8038]
0x10003d37f:	imul	rdx, qword ptr [rbp - 0x28], 0x640  ; size? 0x640
0x10003d387:	add	rax, rdx
0x10003d38a:	mov	rdx, qword ptr [rbp - 0xc8038]
0x10003d391:	imul	rsi, qword ptr [rbp - 0x28], 0x640  ; size? 0x640
0x10003d399:	add	rdx, rsi
0x10003d39c:	movzx	edi, byte ptr [rdx + 0x21]
0x10003d3a0:	mov	esi, edi
0x10003d3a2:	mov	rdi, rax
0x10003d3a5:	mov	dword ptr [rbp - 0xc8074], ecx
0x10003d3ab:	call	0x10003f160
0x10003d3b0:	lea	rdi, [rip + 0x108518]  ; "[%d] %s 
"
0x10003d3b7:	mov	esi, dword ptr [rbp - 0xc8074]
0x10003d3bd:	mov	rdx, rax
0x10003d3c0:	mov	al, 0
0x10003d3c2:	call	0x10013c9fe
0x10003d3c7:	mov	dword ptr [rbp - 0xc8078], eax
0x10003d3cd:	jmp	0x10003d3ea
0x10003d3d2:	mov	rsi, qword ptr [rbp - 0x28]
0x10003d3d6:	lea	rdi, [rip + 0x1084fc]  ; "GetNetworkNameAtIndex() failed[%llu]
"
0x10003d3dd:	mov	al, 0
0x10003d3df:	call	0x10013c9fe
0x10003d3e4:	mov	dword ptr [rbp - 0xc807c], eax
0x10003d3ea:	jmp	0x10003d3ef
0x10003d3ef:	mov	rax, qword ptr [rbp - 0x28]
0x10003d3f3:	add	rax, 1
0x10003d3f7:	mov	qword ptr [rbp - 0x28], rax
0x10003d3fb:	jmp	0x10003d2a2
0x10003d400:	lea	rdi, [rbp - 0x20]
0x10003d404:	call	0x10003dae0
0x10003d409:	jmp	0x10003d422
0x10003d40e:	lea	rdi, [rip + 0x1084ea]  ; "GetAvailableNetworksFromDriver failed"
0x10003d415:	mov	al, 0
0x10003d417:	call	0x10013c9fe
0x10003d41c:	mov	dword ptr [rbp - 0xc8080], eax
0x10003d422:	add	rsp, 0xc80a0
0x10003d429:	pop	rbp
0x10003d42a:	ret	
0x10003d42b:	nop	dword ptr [rax + rax]
0x10003d430:	push	rbp
0x10003d431:	mov	rbp, rsp
0x10003d434:	sub	rsp, 0x20
0x10003d438:	mov	dword ptr [rbp - 4], edi
0x10003d43b:	mov	qword ptr [rbp - 0x10], rsi
0x10003d43f:	mov	dword ptr [rbp - 0x14], 0
0x10003d446:	lea	rsi, [rbp - 0x14]
0x10003d44a:	mov	edi, 0xff010418  ; OID? 0xff010418
0x10003d44f:	call	0x10003ebc0
0x10003d454:	cmp	eax, -1
0x10003d457:	jne	0x10003d473
0x10003d45d:	lea	rdi, [rip + 0x1084c1]  ; "Failed to query NIC interface status.
"
0x10003d464:	mov	al, 0
0x10003d466:	call	0x10013c9fe
0x10003d46b:	mov	dword ptr [rbp - 0x18], eax
0x10003d46e:	jmp	0x10003d49f
0x10003d473:	mov	eax, dword ptr [rbp - 0x14]
0x10003d476:	cmp	eax, 0
0x10003d479:	lea	rcx, [rip + 0xffd95]
0x10003d480:	lea	rdx, [rip + 0xffd91]  ; "down"
0x10003d487:	cmovne	rdx, rcx
0x10003d48b:	lea	rdi, [rip + 0x1084ba]  ; "Interface Status: %s
"
0x10003d492:	mov	rsi, rdx
0x10003d495:	mov	al, 0
0x10003d497:	call	0x10013c9fe
0x10003d49c:	mov	dword ptr [rbp - 0x1c], eax
0x10003d49f:	add	rsp, 0x20
0x10003d4a3:	pop	rbp
0x10003d4a4:	ret	
0x10003d4a5:	nop	word ptr cs:[rax + rax]
0x10003d4af:	nop	
0x10003d4b0:	push	rbp
0x10003d4b1:	mov	rbp, rsp
0x10003d4b4:	sub	rsp, 0x20
0x10003d4b8:	mov	dword ptr [rbp - 4], edi
0x10003d4bb:	mov	qword ptr [rbp - 0x10], rsi
0x10003d4bf:	mov	rsi, qword ptr [rbp - 0x10]
0x10003d4c3:	mov	rdi, qword ptr [rsi + 0x10]
0x10003d4c7:	call	0x10003d500
0x10003d4cc:	xor	edx, edx
0x10003d4ce:	mov	dword ptr [rbp - 0x14], eax
0x10003d4d1:	mov	r9d, dword ptr [rbp - 0x14]
0x10003d4d5:	mov	edi, 8
0x10003d4da:	mov	esi, 1
0x10003d4df:	mov	ecx, 0xff
0x10003d4e4:	mov	r8d, 4
0x10003d4ea:	call	0x10003db10
0x10003d4ef:	add	rsp, 0x20
0x10003d4f3:	pop	rbp
0x10003d4f4:	ret	
0x10003d4f5:	nop	word ptr cs:[rax + rax]
0x10003d4ff:	nop	
0x10003d500:	push	rbp
0x10003d501:	mov	rbp, rsp
0x10003d504:	sub	rsp, 0x40  ; size? 0x40
0x10003d508:	mov	eax, 2
0x10003d50d:	mov	edx, eax
0x10003d50f:	mov	rcx, qword ptr [rip + 0x14ebd2]
0x10003d516:	mov	rcx, qword ptr [rcx]
0x10003d519:	mov	qword ptr [rbp - 8], rcx
0x10003d51d:	mov	qword ptr [rbp - 0x28], rdi
0x10003d521:	mov	dword ptr [rbp - 0x34], 0
0x10003d528:	mov	rcx, qword ptr [rip + 0x113cb1]  ; "0123456789ABCDEFPacket.txt"
0x10003d52f:	mov	qword ptr [rbp - 0x20], rcx
0x10003d533:	mov	rcx, qword ptr [rip + 0x113cae]  ; "89ABCDEFPacket.txt"
0x10003d53a:	mov	qword ptr [rbp - 0x18], rcx
0x10003d53e:	mov	rdi, qword ptr [rbp - 0x28]
0x10003d542:	lea	rsi, [rip + 0x1076f0]
0x10003d549:	call	0x10013ca70
0x10003d54e:	cmp	eax, 0
0x10003d551:	jne	0x10003d568
0x10003d557:	mov	rax, qword ptr [rbp - 0x28]
0x10003d55b:	add	rax, 2
0x10003d55f:	mov	qword ptr [rbp - 0x30], rax
0x10003d563:	jmp	0x10003d570
0x10003d568:	mov	rax, qword ptr [rbp - 0x28]
0x10003d56c:	mov	qword ptr [rbp - 0x30], rax
0x10003d570:	jmp	0x10003d575
0x10003d575:	mov	dword ptr [rbp - 0x38], 0
0x10003d57c:	movsxd	rax, dword ptr [rbp - 0x38]
0x10003d580:	cmp	rax, 0x10
0x10003d584:	jae	0x10003d5d7
0x10003d58a:	mov	rax, qword ptr [rbp - 0x30]

; SetInformationBuffer @ 0x10003eda0
0x10003eda0:	push	rbp
0x10003eda1:	mov	rbp, rsp
0x10003eda4:	sub	rsp, 0xa40
0x10003edab:	mov	rcx, 0xffffffffffffffff
0x10003edb2:	mov	rax, qword ptr [rip + 0x14d32f]
0x10003edb9:	mov	rax, qword ptr [rax]
0x10003edbc:	mov	qword ptr [rbp - 8], rax
0x10003edc0:	mov	dword ptr [rbp - 0x9e8], edi
0x10003edc6:	mov	qword ptr [rbp - 0x9f0], rsi
0x10003edcd:	mov	dword ptr [rbp - 0x9f4], edx
0x10003edd3:	mov	qword ptr [rbp - 0xa08], 0x9d4  ; size? 0x9d4
0x10003edde:	mov	rax, qword ptr [rbp - 0xa08]
0x10003ede5:	mov	qword ptr [rbp - 0xa10], rax
0x10003edec:	lea	rax, [rbp - 0x9e0]
0x10003edf3:	add	rax, 0x10
0x10003edf7:	mov	qword ptr [rbp - 0xa18], rax
0x10003edfe:	mov	edx, dword ptr [rbp - 0x9f4]
0x10003ee04:	mov	dword ptr [rbp - 0x9dc], edx
0x10003ee0a:	mov	edx, dword ptr [rbp - 0x9e8]
0x10003ee10:	mov	dword ptr [rbp - 0xa00], edx
0x10003ee16:	mov	rdi, qword ptr [rbp - 0xa18]
0x10003ee1d:	mov	rsi, qword ptr [rbp - 0x9f0]
0x10003ee24:	movsxd	rdx, dword ptr [rbp - 0x9f4]
0x10003ee2b:	call	0x10013c8a8
0x10003ee30:	mov	r8d, dword ptr [rbp - 0xa00]
0x10003ee37:	mov	dword ptr [rbp - 0x9e0], r8d
0x10003ee3e:	mov	dword ptr [rbp - 0x9d8], 0
0x10003ee48:	mov	dword ptr [rbp - 0x9d4], 0
0x10003ee52:	lea	rdi, [rbp - 0x9fc]
0x10003ee59:	mov	qword ptr [rbp - 0xa20], rax
0x10003ee60:	call	0x10003d900
0x10003ee65:	cmp	al, 0
0x10003ee67:	jne	0x10003ee7c
0x10003ee6d:	mov	dword ptr [rbp - 0x9e4], 0xffffffff  ; OID? 0xffffffff
0x10003ee77:	jmp	0x10003ef31
0x10003ee7c:	mov	eax, 0x9d4  ; size? 0x9d4
0x10003ee81:	mov	ecx, eax
0x10003ee83:	mov	edi, dword ptr [rbp - 0x9fc]
0x10003ee89:	lea	rdx, [rbp - 0x9e0]
0x10003ee90:	mov	rsi, rdx
0x10003ee93:	mov	eax, 0xa
0x10003ee98:	mov	qword ptr [rbp - 0xa28], rsi
0x10003ee9f:	mov	esi, eax
0x10003eea1:	mov	r8, qword ptr [rbp - 0xa28]
0x10003eea8:	mov	qword ptr [rbp - 0xa30], rdx
0x10003eeaf:	mov	rdx, r8
0x10003eeb2:	mov	r8, qword ptr [rbp - 0xa30]
0x10003eeb9:	lea	r9, [rbp - 0xa10]
0x10003eec0:	call	0x10013c788
0x10003eec5:	mov	dword ptr [rbp - 0x9f8], eax
0x10003eecb:	cmp	dword ptr [rbp - 0x9f8], 0
0x10003eed2:	je	0x10003ef01
0x10003eed8:	mov	esi, dword ptr [rbp - 0xa00]
0x10003eede:	lea	rdi, [rip + 0x106571]  ; "SetInformationBuffer:: Can not set the OID 0x%X!
"
0x10003eee5:	mov	al, 0
0x10003eee7:	call	0x10013c9fe
0x10003eeec:	mov	dword ptr [rbp - 0x9e4], 0xffffffff  ; OID? 0xffffffff
0x10003eef6:	mov	dword ptr [rbp - 0xa34], eax
0x10003eefc:	jmp	0x10003ef31
0x10003ef01:	mov	esi, dword ptr [rbp - 0xa00]
0x10003ef07:	lea	rdi, [rip + 0x10657a]  ; "SetInformationBuffer:: Set OID 0x%X sucessfully
"
0x10003ef0e:	mov	al, 0
0x10003ef10:	call	0x10013c9fe
0x10003ef15:	mov	dword ptr [rbp - 0xa38], eax
0x10003ef1b:	lea	rdi, [rbp - 0x9fc]
0x10003ef22:	call	0x10003dae0
0x10003ef27:	mov	dword ptr [rbp - 0x9e4], 1
0x10003ef31:	mov	eax, dword ptr [rbp - 0x9e4]
0x10003ef37:	mov	rcx, qword ptr [rip + 0x14d1aa]
0x10003ef3e:	mov	rcx, qword ptr [rcx]
0x10003ef41:	mov	rdx, qword ptr [rbp - 8]
0x10003ef45:	cmp	rcx, rdx
0x10003ef48:	mov	dword ptr [rbp - 0xa3c], eax
0x10003ef4e:	jne	0x10003ef63
0x10003ef54:	mov	eax, dword ptr [rbp - 0xa3c]
0x10003ef5a:	add	rsp, 0xa40
0x10003ef61:	pop	rbp
0x10003ef62:	ret	
0x10003ef63:	call	0x10013c8c0
0x10003ef68:	ud2	
0x10003ef6a:	nop	word ptr [rax + rax]

; SetInformationValue @ 0x10003ef70
0x10003ef70:	push	rbp
0x10003ef71:	mov	rbp, rsp
0x10003ef74:	sub	rsp, 0xa30
0x10003ef7b:	mov	rax, qword ptr [rip + 0x14d166]
0x10003ef82:	mov	rax, qword ptr [rax]
0x10003ef85:	mov	qword ptr [rbp - 8], rax
0x10003ef89:	mov	dword ptr [rbp - 0x9e8], edi
0x10003ef8f:	mov	dword ptr [rbp - 0x9ec], esi
0x10003ef95:	mov	qword ptr [rbp - 0xa00], 0x9d4  ; size? 0x9d4
0x10003efa0:	mov	rax, qword ptr [rbp - 0xa00]
0x10003efa7:	mov	qword ptr [rbp - 0xa08], rax
0x10003efae:	lea	rax, [rbp - 0x9e0]
0x10003efb5:	add	rax, 0x10
0x10003efb9:	mov	qword ptr [rbp - 0xa10], rax
0x10003efc0:	mov	dword ptr [rbp - 0x9dc], 0x9c4
0x10003efca:	mov	esi, dword ptr [rbp - 0x9e8]
0x10003efd0:	mov	dword ptr [rbp - 0x9f8], esi
0x10003efd6:	mov	esi, dword ptr [rbp - 0x9ec]
0x10003efdc:	mov	rax, qword ptr [rbp - 0xa10]
0x10003efe3:	mov	dword ptr [rax], esi
0x10003efe5:	mov	esi, dword ptr [rbp - 0x9f8]
0x10003efeb:	mov	dword ptr [rbp - 0x9e0], esi
0x10003eff1:	mov	dword ptr [rbp - 0x9d8], 0
0x10003effb:	mov	dword ptr [rbp - 0x9d4], 0
0x10003f005:	lea	rdi, [rbp - 0x9f4]
0x10003f00c:	call	0x10003d900
0x10003f011:	cmp	al, 0
0x10003f013:	jne	0x10003f028
0x10003f019:	mov	dword ptr [rbp - 0x9e4], 0xffffffff  ; OID? 0xffffffff
0x10003f023:	jmp	0x10003f0dd
0x10003f028:	mov	eax, 0x9d4  ; size? 0x9d4
0x10003f02d:	mov	ecx, eax
0x10003f02f:	mov	edi, dword ptr [rbp - 0x9f4]
0x10003f035:	lea	rdx, [rbp - 0x9e0]
0x10003f03c:	mov	rsi, rdx
0x10003f03f:	mov	eax, 0xa
0x10003f044:	mov	qword ptr [rbp - 0xa18], rsi
0x10003f04b:	mov	esi, eax
0x10003f04d:	mov	r8, qword ptr [rbp - 0xa18]
0x10003f054:	mov	qword ptr [rbp - 0xa20], rdx
0x10003f05b:	mov	rdx, r8
0x10003f05e:	mov	r8, qword ptr [rbp - 0xa20]
0x10003f065:	lea	r9, [rbp - 0xa08]
0x10003f06c:	call	0x10013c788
0x10003f071:	mov	dword ptr [rbp - 0x9f0], eax
0x10003f077:	cmp	dword ptr [rbp - 0x9f0], 0
0x10003f07e:	je	0x10003f0ad
0x10003f084:	mov	esi, dword ptr [rbp - 0x9f8]
0x10003f08a:	lea	rdi, [rip + 0x106366]  ; "SetInformationValue: Can not set the OID 0x%X!
"
0x10003f091:	mov	al, 0
0x10003f093:	call	0x10013c9fe
0x10003f098:	mov	dword ptr [rbp - 0x9e4], 0xffffffff  ; OID? 0xffffffff
0x10003f0a2:	mov	dword ptr [rbp - 0xa24], eax
0x10003f0a8:	jmp	0x10003f0dd
0x10003f0ad:	mov	esi, dword ptr [rbp - 0x9f8]
0x10003f0b3:	lea	rdi, [rip + 0x10636d]  ; "SetInformationValue: Set OID 0x%X sucessfully
"
0x10003f0ba:	mov	al, 0
0x10003f0bc:	call	0x10013c9fe
0x10003f0c1:	mov	dword ptr [rbp - 0xa28], eax
0x10003f0c7:	lea	rdi, [rbp - 0x9f4]
0x10003f0ce:	call	0x10003dae0
0x10003f0d3:	mov	dword ptr [rbp - 0x9e4], 1
0x10003f0dd:	mov	eax, dword ptr [rbp - 0x9e4]
0x10003f0e3:	mov	rcx, qword ptr [rip + 0x14cffe]
0x10003f0ea:	mov	rcx, qword ptr [rcx]
0x10003f0ed:	mov	rdx, qword ptr [rbp - 8]
0x10003f0f1:	cmp	rcx, rdx
0x10003f0f4:	mov	dword ptr [rbp - 0xa2c], eax
0x10003f0fa:	jne	0x10003f10f
0x10003f100:	mov	eax, dword ptr [rbp - 0xa2c]
0x10003f106:	add	rsp, 0xa30
0x10003f10d:	pop	rbp
0x10003f10e:	ret	
0x10003f10f:	call	0x10013c8c0
0x10003f114:	ud2	
0x10003f116:	nop	word ptr cs:[rax + rax]
0x10003f120:	push	rbp
0x10003f121:	mov	rbp, rsp
0x10003f124:	sub	rsp, 0x10
0x10003f128:	mov	qword ptr [rbp - 8], rdi
0x10003f12c:	lea	rdi, [rip + 0x10682f]  ; "Usage:
"
0x10003f133:	mov	al, 0
0x10003f135:	call	0x10013c9fe
0x10003f13a:	mov	rdi, qword ptr [rbp - 8]
0x10003f13e:	mov	rsi, qword ptr [rdi + 0x18]
0x10003f142:	lea	rdi, [rip + 0x106821]  ; "	%s
"
0x10003f149:	mov	dword ptr [rbp - 0xc], eax
0x10003f14c:	mov	al, 0
0x10003f14e:	call	0x10013c9fe
0x10003f153:	mov	dword ptr [rbp - 0x10], eax
0x10003f156:	add	rsp, 0x10
0x10003f15a:	pop	rbp
0x10003f15b:	ret	
0x10003f15c:	nop	dword ptr [rax]
0x10003f160:	push	rbp
0x10003f161:	mov	rbp, rsp
0x10003f164:	sub	rsp, 0x20
0x10003f168:	mov	qword ptr [rbp - 8], rdi
0x10003f16c:	mov	qword ptr [rbp - 0x10], rsi

; WirelessAssociate @ 0x10001c7f0
0x10001c7f0:	push	rbp
0x10001c7f1:	mov	rbp, rsp
0x10001c7f4:	sub	rsp, 0x60
0x10001c7f8:	xor	ecx, ecx
0x10001c7fa:	mov	qword ptr [rbp - 8], rdi
0x10001c7fe:	mov	qword ptr [rbp - 0x10], rsi
0x10001c802:	mov	qword ptr [rbp - 0x18], rdx
0x10001c806:	mov	byte ptr [rbp - 0x19], 0
0x10001c80a:	mov	rdx, qword ptr [rbp - 8]
0x10001c80e:	mov	rsi, qword ptr [rip + 0x194183]
0x10001c815:	mov	rdi, rdx
0x10001c818:	mov	edx, 0xd010115
0x10001c81d:	call	qword ptr [rip + 0x16f9ad]
0x10001c823:	mov	rsi, qword ptr [rbp - 8]
0x10001c827:	mov	rdi, qword ptr [rbp - 0x18]
0x10001c82b:	movzx	ecx, byte ptr [rdi + 0x18]
0x10001c82f:	mov	rdi, qword ptr [rip + 0x194162]
0x10001c836:	mov	qword ptr [rbp - 0x28], rdi
0x10001c83a:	mov	rdi, rsi
0x10001c83d:	mov	rsi, qword ptr [rbp - 0x28]
0x10001c841:	mov	edx, 0xd010108
0x10001c846:	mov	byte ptr [rbp - 0x29], al
0x10001c849:	call	qword ptr [rip + 0x16f981]
0x10001c84f:	mov	rsi, qword ptr [rbp - 8]
0x10001c853:	mov	rdi, qword ptr [rbp - 0x18]
0x10001c857:	mov	rdx, qword ptr [rdi + 8]
0x10001c85b:	mov	rdi, qword ptr [rip + 0x194b76]
0x10001c862:	mov	qword ptr [rbp - 0x38], rdi
0x10001c866:	mov	rdi, rsi
0x10001c869:	mov	rsi, qword ptr [rbp - 0x38]
0x10001c86d:	mov	byte ptr [rbp - 0x39], al
0x10001c870:	call	qword ptr [rip + 0x16f95a]
0x10001c876:	mov	rdx, qword ptr [rbp - 8]
0x10001c87a:	mov	rsi, qword ptr [rbp - 0x18]
0x10001c87e:	movzx	ecx, byte ptr [rsi + 0x1a]
0x10001c882:	mov	rsi, qword ptr [rip + 0x194b57]
0x10001c889:	mov	rdi, rdx
0x10001c88c:	mov	edx, ecx
0x10001c88e:	mov	byte ptr [rbp - 0x3a], al
0x10001c891:	call	qword ptr [rip + 0x16f939]
0x10001c897:	xor	ecx, ecx
0x10001c899:	mov	rsi, qword ptr [rbp - 8]
0x10001c89d:	mov	rdi, qword ptr [rbp - 0x18]
0x10001c8a1:	mov	edx, dword ptr [rdi + 0x30]
0x10001c8a4:	cmp	edx, 2
0x10001c8a7:	mov	edx, 1
0x10001c8ac:	cmove	ecx, edx
0x10001c8af:	mov	rdi, qword ptr [rip + 0x1940e2]
0x10001c8b6:	mov	qword ptr [rbp - 0x48], rdi
0x10001c8ba:	mov	rdi, rsi
0x10001c8bd:	mov	rsi, qword ptr [rbp - 0x48]
0x10001c8c1:	mov	edx, 0xff01041a  ; OID? 0xff01041a
0x10001c8c6:	mov	byte ptr [rbp - 0x49], al
0x10001c8c9:	call	qword ptr [rip + 0x16f901]
0x10001c8cf:	mov	rsi, qword ptr [rbp - 0x18]
0x10001c8d3:	movzx	ecx, byte ptr [rsi + 0x18]
0x10001c8d7:	cmp	ecx, 1
0x10001c8da:	mov	byte ptr [rbp - 0x4a], al
0x10001c8dd:	jne	0x10001c921
0x10001c8e3:	mov	rax, qword ptr [rbp - 0x18]
0x10001c8e7:	cmp	dword ptr [rax + 0x30], 3
0x10001c8eb:	je	0x10001c8ff
0x10001c8f1:	mov	rax, qword ptr [rbp - 0x18]
0x10001c8f5:	cmp	dword ptr [rax + 0x30], 4
0x10001c8f9:	jne	0x10001c921
0x10001c8ff:	xor	ecx, ecx
0x10001c901:	mov	rax, qword ptr [rbp - 8]
0x10001c905:	mov	rsi, qword ptr [rip + 0x19408c]
0x10001c90c:	mov	rdi, rax
0x10001c90f:	mov	edx, 0xff030004  ; OID? 0xff030004
0x10001c914:	call	qword ptr [rip + 0x16f8b6]
0x10001c91a:	mov	byte ptr [rbp - 0x19], 1
0x10001c91e:	mov	byte ptr [rbp - 0x4b], al
0x10001c921:	mov	rax, qword ptr [rbp - 0x18]
0x10001c925:	cmp	dword ptr [rax + 0x30], 1
0x10001c929:	je	0x10001c93d
0x10001c92f:	mov	rax, qword ptr [rbp - 0x18]
0x10001c933:	cmp	dword ptr [rax + 0x30], 2
0x10001c937:	jne	0x10001c9ed
0x10001c93d:	mov	dword ptr [rbp - 0x20], 0
0x10001c944:	mov	rax, qword ptr [rbp - 8]
0x10001c948:	mov	rcx, qword ptr [rbp - 0x18]
0x10001c94c:	movzx	ecx, byte ptr [rcx + 0x19]
0x10001c950:	mov	rsi, qword ptr [rip + 0x194041]
0x10001c957:	mov	rdi, rax
0x10001c95a:	mov	edx, 0xff030004  ; OID? 0xff030004
0x10001c95f:	call	qword ptr [rip + 0x16f86b]
0x10001c965:	mov	rsi, qword ptr [rbp - 8]
0x10001c969:	mov	rdi, qword ptr [rbp - 0x18]
0x10001c96d:	mov	rdx, qword ptr [rdi + 0x20]
0x10001c971:	mov	rdi, qword ptr [rbp - 0x18]
0x10001c975:	movzx	ecx, byte ptr [rdi + 0x19]
0x10001c979:	mov	rdi, qword ptr [rip + 0x194a68]
0x10001c980:	mov	qword ptr [rbp - 0x58], rdi
0x10001c984:	mov	rdi, rsi
0x10001c987:	mov	rsi, qword ptr [rbp - 0x58]
0x10001c98b:	mov	byte ptr [rbp - 0x59], al
0x10001c98e:	call	qword ptr [rip + 0x16f83c]
0x10001c994:	mov	dword ptr [rbp - 0x20], eax
0x10001c997:	cmp	dword ptr [rbp - 0x20], 0x1a
0x10001c99b:	jne	0x10001c9c7
0x10001c9a1:	mov	rax, qword ptr [rbp - 8]
0x10001c9a5:	mov	rsi, qword ptr [rip + 0x193fec]
0x10001c9ac:	mov	rdi, rax
0x10001c9af:	mov	edx, 0xff010194  ; OID? 0xff010194
0x10001c9b4:	mov	ecx, 2
0x10001c9b9:	call	qword ptr [rip + 0x16f811]
0x10001c9bf:	mov	byte ptr [rbp - 0x5a], al
0x10001c9c2:	jmp	0x10001c9e8
0x10001c9c7:	mov	rax, qword ptr [rbp - 8]
0x10001c9cb:	mov	rsi, qword ptr [rip + 0x193fc6]
0x10001c9d2:	mov	rdi, rax
0x10001c9d5:	mov	edx, 0xff010194  ; OID? 0xff010194
0x10001c9da:	mov	ecx, 1
0x10001c9df:	call	qword ptr [rip + 0x16f7eb]
0x10001c9e5:	mov	byte ptr [rbp - 0x5b], al
0x10001c9e8:	jmp	0x10001cab4
0x10001c9ed:	mov	rax, qword ptr [rbp - 0x18]
0x10001c9f1:	cmp	dword ptr [rax + 0x30], 3
0x10001c9f5:	je	0x10001ca25
0x10001c9fb:	mov	rax, qword ptr [rbp - 0x18]
0x10001c9ff:	cmp	dword ptr [rax + 0x30], 4
0x10001ca03:	je	0x10001ca25
0x10001ca09:	mov	rax, qword ptr [rbp - 0x18]
0x10001ca0d:	cmp	dword ptr [rax + 0x30], 5
0x10001ca11:	je	0x10001ca25
0x10001ca17:	mov	rax, qword ptr [rbp - 0x18]
0x10001ca1b:	cmp	dword ptr [rax + 0x30], 6
0x10001ca1f:	jne	0x10001ca7e
0x10001ca25:	lea	rax, [rip + 0x18a09c]
0x10001ca2c:	mov	rdi, rax
0x10001ca2f:	mov	al, 0
0x10001ca31:	call	0x10013c7d6
0x10001ca36:	mov	rdi, qword ptr [rbp - 8]
0x10001ca3a:	mov	rcx, qword ptr [rbp - 0x18]
0x10001ca3e:	mov	rdx, qword ptr [rcx + 0x28]
0x10001ca42:	mov	rsi, qword ptr [rip + 0x1949a7]
0x10001ca49:	call	qword ptr [rip + 0x16f781]
0x10001ca4f:	mov	rcx, qword ptr [rbp - 8]
0x10001ca53:	mov	rdx, qword ptr [rbp - 0x18]
0x10001ca57:	mov	r8d, dword ptr [rdx + 0x30]
0x10001ca5b:	mov	rsi, qword ptr [rip + 0x193f36]
0x10001ca62:	mov	rdi, rcx
0x10001ca65:	mov	edx, 0xff010194  ; OID? 0xff010194
0x10001ca6a:	mov	ecx, r8d
0x10001ca6d:	mov	byte ptr [rbp - 0x5c], al
0x10001ca70:	call	qword ptr [rip + 0x16f75a]
0x10001ca76:	mov	byte ptr [rbp - 0x5d], al
0x10001ca79:	jmp	0x10001caaf
0x10001ca7e:	lea	rax, [rip + 0x18a063]
0x10001ca85:	mov	rdi, rax
0x10001ca88:	mov	al, 0
0x10001ca8a:	call	0x10013c7d6
0x10001ca8f:	mov	rdi, qword ptr [rbp - 8]
0x10001ca93:	mov	rcx, qword ptr [rbp - 0x18]
0x10001ca97:	mov	ecx, dword ptr [rcx + 0x30]
0x10001ca9a:	mov	rsi, qword ptr [rip + 0x193ef7]
0x10001caa1:	mov	edx, 0xff010194  ; OID? 0xff010194
0x10001caa6:	call	qword ptr [rip + 0x16f724]
0x10001caac:	mov	byte ptr [rbp - 0x5e], al
0x10001caaf:	jmp	0x10001cab4
0x10001cab4:	xor	ecx, ecx
0x10001cab6:	mov	rax, qword ptr [rbp - 8]
0x10001caba:	mov	rsi, qword ptr [rip + 0x193ed7]
0x10001cac1:	mov	rdi, rax
0x10001cac4:	mov	edx, 0xff01041b  ; OID? 0xff01041b
0x10001cac9:	call	qword ptr [rip + 0x16f701]
0x10001cacf:	cmp	byte ptr [rbp - 0x19], 0
0x10001cad3:	mov	byte ptr [rbp - 0x5f], al
0x10001cad6:	je	0x10001cafb
0x10001cadc:	mov	rax, qword ptr [rbp - 8]
0x10001cae0:	mov	rcx, qword ptr [rbp - 0x18]
0x10001cae4:	mov	rdx, qword ptr [rcx + 0x28]
0x10001cae8:	mov	rsi, qword ptr [rip + 0x194901]
0x10001caef:	mov	rdi, rax
0x10001caf2:	call	qword ptr [rip + 0x16f6d8]
0x10001caf8:	mov	byte ptr [rbp - 0x60], al
0x10001cafb:	add	rsp, 0x60
0x10001caff:	pop	rbp
0x10001cb00:	ret	
0x10001cb01:	nop	word ptr cs:[rax + rax]
0x10001cb0b:	nop	dword ptr [rax + rax]
0x10001cb10:	push	rbp
0x10001cb11:	mov	rbp, rsp
0x10001cb14:	sub	rsp, 0x30
0x10001cb18:	mov	qword ptr [rbp - 8], rdi
0x10001cb1c:	mov	qword ptr [rbp - 0x10], rsi
0x10001cb20:	mov	dword ptr [rbp - 0x14], 0
0x10001cb27:	mov	rsi, qword ptr [rbp - 8]
0x10001cb2b:	lea	rdi, [rbp - 0x14]
0x10001cb2f:	mov	rax, qword ptr [rip + 0x19414a]
0x10001cb36:	mov	qword ptr [rbp - 0x20], rdi
0x10001cb3a:	mov	rdi, rsi
0x10001cb3d:	mov	rsi, rax
0x10001cb40:	mov	edx, 0x10114
0x10001cb45:	mov	rcx, qword ptr [rbp - 0x20]
0x10001cb49:	call	qword ptr [rip + 0x16f681]
0x10001cb4f:	mov	edx, dword ptr [rbp - 0x14]
0x10001cb52:	mov	dword ptr [rbp - 0x24], eax
0x10001cb55:	mov	eax, edx
0x10001cb57:	add	rsp, 0x30
0x10001cb5b:	pop	rbp
0x10001cb5c:	ret	
0x10001cb5d:	nop	dword ptr [rax]
0x10001cb60:	push	rbp
0x10001cb61:	mov	rbp, rsp
0x10001cb64:	sub	rsp, 0x30
0x10001cb68:	mov	qword ptr [rbp - 0x10], rdi
0x10001cb6c:	mov	qword ptr [rbp - 0x18], rsi
0x10001cb70:	mov	dword ptr [rbp - 0x1c], 0
0x10001cb77:	mov	rsi, qword ptr [rbp - 0x10]
0x10001cb7b:	lea	rdi, [rbp - 0x1c]
0x10001cb7f:	mov	rax, qword ptr [rip + 0x1940fa]
0x10001cb86:	mov	qword ptr [rbp - 0x28], rdi
0x10001cb8a:	mov	rdi, rsi
0x10001cb8d:	mov	rsi, rax
0x10001cb90:	mov	edx, 0xff0101bd  ; OID? 0xff0101bd
0x10001cb95:	mov	rcx, qword ptr [rbp - 0x28]
0x10001cb99:	call	qword ptr [rip + 0x16f631]
0x10001cb9f:	cmp	dword ptr [rbp - 0x1c], 0
0x10001cba3:	mov	dword ptr [rbp - 0x2c], eax
0x10001cba6:	je	0x10001cbb8
0x10001cbac:	mov	dword ptr [rbp - 4], 0
0x10001cbb3:	jmp	0x10001cbbf
0x10001cbb8:	mov	dword ptr [rbp - 4], 1
0x10001cbbf:	mov	eax, dword ptr [rbp - 4]
0x10001cbc2:	add	rsp, 0x30
0x10001cbc6:	pop	rbp
0x10001cbc7:	ret	
0x10001cbc8:	nop	dword ptr [rax + rax]
0x10001cbd0:	push	rbp
0x10001cbd1:	mov	rbp, rsp
0x10001cbd4:	sub	rsp, 0xd0
0x10001cbdb:	lea	rax, [rbp - 0x90]
0x10001cbe2:	mov	rcx, qword ptr [rip + 0x16f4ff]
0x10001cbe9:	mov	rcx, qword ptr [rcx]
0x10001cbec:	mov	qword ptr [rbp - 8], rcx
0x10001cbf0:	mov	qword ptr [rbp - 0x98], rdi
0x10001cbf7:	mov	qword ptr [rbp - 0xa0], rsi
0x10001cbfe:	mov	qword ptr [rbp - 0xa8], rdx
0x10001cc05:	mov	byte ptr [rbp - 0xa9], 1
0x10001cc0c:	mov	dword ptr [rbp - 0xb0], 0
0x10001cc16:	mov	rcx, qword ptr [rbp - 0xa8]
0x10001cc1d:	mov	rsi, qword ptr [rip + 0x1947d4]
0x10001cc24:	mov	rdi, rcx
0x10001cc27:	mov	qword ptr [rbp - 0xb8], rax
0x10001cc2e:	call	qword ptr [rip + 0x16f59c]
0x10001cc34:	mov	rcx, qword ptr [rbp - 0xa8]
0x10001cc3b:	mov	rsi, qword ptr [rip + 0x193c16]
0x10001cc42:	mov	rdi, rcx
0x10001cc45:	mov	qword ptr [rbp - 0xc0], rax
0x10001cc4c:	call	qword ptr [rip + 0x16f57e]
0x10001cc52:	mov	r8d, 0x84
0x10001cc58:	mov	ecx, r8d
0x10001cc5b:	mov	rdi, qword ptr [rbp - 0xb8]
0x10001cc62:	mov	rsi, qword ptr [rbp - 0xc0]
0x10001cc69:	mov	rdx, rax
0x10001cc6c:	call	0x10013c8a8
0x10001cc71:	mov	rcx, qword ptr [rbp - 0xa8]
0x10001cc78:	mov	rsi, qword ptr [rip + 0x193bd9]
0x10001cc7f:	mov	rdi, rcx
0x10001cc82:	mov	qword ptr [rbp - 0xc8], rax
0x10001cc89:	call	qword ptr [rip + 0x16f541]
0x10001cc8f:	mov	r8d, eax
0x10001cc92:	mov	dword ptr [rbp - 0x10], r8d
0x10001cc96:	mov	rax, qword ptr [rbp - 0x98]
0x10001cc9d:	lea	rcx, [rbp - 0x90]
0x10001cca4:	mov	rsi, qword ptr [rip + 0x193d05]
0x10001ccab:	mov	rdi, rax
0x10001ccae:	mov	edx, 0xff070102  ; OID? 0xff070102
0x10001ccb3:	mov	r8d, 0x84
0x10001ccb9:	call	qword ptr [rip + 0x16f511]
0x10001ccbf:	cmp	dword ptr [rbp - 0xb0], 0
0x10001ccc6:	mov	byte ptr [rbp - 0xc9], al
0x10001cccc:	jne	0x10001ccde
0x10001ccd2:	mov	byte ptr [rbp - 0xa9], 1
0x10001ccd9:	jmp	0x10001cce3
0x10001ccde:	jmp	0x10001cce3
0x10001cce3:	mov	al, byte ptr [rbp - 0xa9]
0x10001cce9:	mov	rcx, qword ptr [rip + 0x16f3f8]

; SetInformation_Buffer_Length @ 0x10001e770
0x10001e770:	push	rbp
0x10001e771:	mov	rbp, rsp
0x10001e774:	sub	rsp, 0xa50
0x10001e77b:	mov	rax, 0xffffffffffffffff
0x10001e782:	mov	r9, qword ptr [rip + 0x16d95f]
0x10001e789:	mov	r9, qword ptr [r9]
0x10001e78c:	mov	qword ptr [rbp - 8], r9
0x10001e790:	mov	qword ptr [rbp - 0x9f0], rdi
0x10001e797:	mov	qword ptr [rbp - 0x9f8], rsi
0x10001e79e:	mov	dword ptr [rbp - 0x9fc], edx
0x10001e7a4:	mov	qword ptr [rbp - 0xa08], rcx
0x10001e7ab:	mov	dword ptr [rbp - 0xa0c], r8d
0x10001e7b2:	mov	qword ptr [rbp - 0xa18], 0x9d4  ; size? 0x9d4
0x10001e7bd:	mov	rcx, qword ptr [rbp - 0xa18]
0x10001e7c4:	mov	qword ptr [rbp - 0xa20], rcx
0x10001e7cb:	lea	rcx, [rbp - 0x9e0]
0x10001e7d2:	add	rcx, 0x10
0x10001e7d6:	mov	qword ptr [rbp - 0xa28], rcx
0x10001e7dd:	mov	edx, dword ptr [rbp - 0xa0c]
0x10001e7e3:	mov	dword ptr [rbp - 0x9dc], edx
0x10001e7e9:	mov	rdi, qword ptr [rbp - 0xa28]
0x10001e7f0:	mov	rsi, qword ptr [rbp - 0xa08]
0x10001e7f7:	movsxd	rdx, dword ptr [rbp - 0xa0c]
0x10001e7fe:	mov	rcx, rax
0x10001e801:	call	0x10013c8a8
0x10001e806:	mov	r8d, 0x9d4  ; size? 0x9d4
0x10001e80c:	mov	ecx, r8d
0x10001e80f:	mov	r8d, dword ptr [rbp - 0x9fc]
0x10001e816:	mov	dword ptr [rbp - 0x9e0], r8d
0x10001e81d:	mov	dword ptr [rbp - 0x9d8], 0
0x10001e827:	mov	dword ptr [rbp - 0x9d4], 0
0x10001e831:	mov	rdx, qword ptr [rbp - 0x9f0]
0x10001e838:	mov	rsi, qword ptr [rip + 0x193b31]
0x10001e83f:	mov	edi, dword ptr [rdx + rsi]
0x10001e842:	lea	rdx, [rbp - 0x9e0]
0x10001e849:	mov	rsi, rdx
0x10001e84c:	mov	r8d, 0xa
0x10001e852:	mov	qword ptr [rbp - 0xa30], rsi
0x10001e859:	mov	esi, r8d
0x10001e85c:	mov	r9, qword ptr [rbp - 0xa30]
0x10001e863:	mov	qword ptr [rbp - 0xa38], rdx
0x10001e86a:	mov	rdx, r9
0x10001e86d:	mov	r8, qword ptr [rbp - 0xa38]
0x10001e874:	lea	r9, [rbp - 0xa20]
0x10001e87b:	mov	qword ptr [rbp - 0xa40], rax
0x10001e882:	call	0x10013c788
0x10001e887:	mov	dword ptr [rbp - 0xa10], eax
0x10001e88d:	cmp	dword ptr [rbp - 0xa10], 0
0x10001e894:	je	0x10001e8a6
0x10001e89a:	mov	byte ptr [rbp - 0x9e1], 0
0x10001e8a1:	jmp	0x10001e8ad
0x10001e8a6:	mov	byte ptr [rbp - 0x9e1], 1
0x10001e8ad:	mov	al, byte ptr [rbp - 0x9e1]
0x10001e8b3:	mov	rcx, qword ptr [rip + 0x16d82e]
0x10001e8ba:	mov	rcx, qword ptr [rcx]
0x10001e8bd:	mov	rdx, qword ptr [rbp - 8]
0x10001e8c1:	cmp	rcx, rdx
0x10001e8c4:	mov	byte ptr [rbp - 0xa41], al
0x10001e8ca:	jne	0x10001e8e2
0x10001e8d0:	mov	al, byte ptr [rbp - 0xa41]
0x10001e8d6:	movsx	eax, al
0x10001e8d9:	add	rsp, 0xa50
0x10001e8e0:	pop	rbp
0x10001e8e1:	ret	
0x10001e8e2:	call	0x10013c8c0
0x10001e8e7:	ud2	
0x10001e8e9:	nop	dword ptr [rax]
0x10001e8f0:	push	rbp
0x10001e8f1:	mov	rbp, rsp
0x10001e8f4:	sub	rsp, 0xa50
0x10001e8fb:	mov	eax, 0x9d4  ; size? 0x9d4
0x10001e900:	mov	r8d, eax
0x10001e903:	xor	eax, eax
0x10001e905:	mov	r9, qword ptr [rip + 0x16d7dc]
0x10001e90c:	mov	r9, qword ptr [r9]
0x10001e90f:	mov	qword ptr [rbp - 8], r9
0x10001e913:	mov	qword ptr [rbp - 0x9f0], rdi
0x10001e91a:	mov	qword ptr [rbp - 0x9f8], rsi
0x10001e921:	mov	dword ptr [rbp - 0x9fc], edx
0x10001e927:	mov	qword ptr [rbp - 0xa08], rcx
0x10001e92e:	mov	qword ptr [rbp - 0xa18], 0x9d4  ; size? 0x9d4
0x10001e939:	mov	rcx, qword ptr [rbp - 0xa18]
0x10001e940:	mov	qword ptr [rbp - 0xa20], rcx
0x10001e947:	lea	rcx, [rbp - 0x9e0]
0x10001e94e:	mov	rsi, rcx
0x10001e951:	mov	rdi, rsi
0x10001e954:	mov	esi, eax
0x10001e956:	mov	rdx, r8
0x10001e959:	mov	qword ptr [rbp - 0xa28], rcx
0x10001e960:	mov	qword ptr [rbp - 0xa30], r8
0x10001e967:	call	0x10013c9d4
0x10001e96c:	mov	eax, dword ptr [rbp - 0x9fc]
0x10001e972:	mov	dword ptr [rbp - 0xa10], eax
0x10001e978:	mov	eax, dword ptr [rbp - 0xa10]
0x10001e97e:	mov	dword ptr [rbp - 0x9e0], eax
0x10001e984:	mov	dword ptr [rbp - 0x9dc], 0x9c4
0x10001e98e:	mov	dword ptr [rbp - 0x9d8], 0
0x10001e998:	mov	dword ptr [rbp - 0x9d4], 0
0x10001e9a2:	mov	rcx, qword ptr [rbp - 0x9f0]
0x10001e9a9:	mov	rdx, qword ptr [rip + 0x1939c0]
0x10001e9b0:	mov	edi, dword ptr [rcx + rdx]
0x10001e9b3:	mov	rcx, qword ptr [rbp - 0xa28]
0x10001e9ba:	mov	rdx, qword ptr [rbp - 0xa28]
0x10001e9c1:	mov	esi, 9
0x10001e9c6:	mov	qword ptr [rbp - 0xa38], rdx
0x10001e9cd:	mov	rdx, rcx
0x10001e9d0:	mov	rcx, qword ptr [rbp - 0xa30]
0x10001e9d7:	mov	r8, qword ptr [rbp - 0xa38]
0x10001e9de:	lea	r9, [rbp - 0xa20]
0x10001e9e5:	call	0x10013c788
0x10001e9ea:	mov	dword ptr [rbp - 0xa0c], eax
0x10001e9f0:	cmp	dword ptr [rbp - 0x9d8], 0
0x10001e9f7:	ja	0x10001ea0c
0x10001e9fd:	mov	dword ptr [rbp - 0x9e4], 0xffffffff  ; OID? 0xffffffff
0x10001ea07:	jmp	0x10001ea62
0x10001ea0c:	cmp	dword ptr [rbp - 0xa0c], 0
0x10001ea13:	je	0x10001ea28
0x10001ea19:	mov	dword ptr [rbp - 0x9e4], 0xffffffff  ; OID? 0xffffffff
0x10001ea23:	jmp	0x10001ea62
0x10001ea28:	mov	rcx, 0xffffffffffffffff
0x10001ea2f:	mov	rdi, qword ptr [rbp - 0xa08]
0x10001ea36:	lea	rax, [rbp - 0x9e0]
0x10001ea3d:	add	rax, 0x10
0x10001ea41:	mov	edx, dword ptr [rbp - 0x9d8]
0x10001ea47:	mov	rsi, rax
0x10001ea4a:	call	0x10013c8a8
0x10001ea4f:	mov	qword ptr [rbp - 0xa40], rax
0x10001ea56:	mov	eax, dword ptr [rbp - 0x9d8]
0x10001ea5c:	mov	dword ptr [rbp - 0x9e4], eax
0x10001ea62:	mov	eax, dword ptr [rbp - 0x9e4]
0x10001ea68:	mov	rcx, qword ptr [rip + 0x16d679]

; SetInformation_Value @ 0x10001e420
0x10001e420:	push	rbp
0x10001e421:	mov	rbp, rsp
0x10001e424:	sub	rsp, 0xa30
0x10001e42b:	mov	eax, 0x9d4  ; size? 0x9d4
0x10001e430:	mov	r8d, eax
0x10001e433:	mov	r9, qword ptr [rip + 0x16dcae]
0x10001e43a:	mov	r9, qword ptr [r9]
0x10001e43d:	mov	qword ptr [rbp - 8], r9
0x10001e441:	mov	qword ptr [rbp - 0x9f0], rdi
0x10001e448:	mov	qword ptr [rbp - 0x9f8], rsi
0x10001e44f:	mov	dword ptr [rbp - 0x9fc], edx
0x10001e455:	mov	dword ptr [rbp - 0xa00], ecx
0x10001e45b:	mov	qword ptr [rbp - 0xa10], 0x9d4  ; size? 0x9d4
0x10001e466:	mov	rsi, qword ptr [rbp - 0xa10]
0x10001e46d:	mov	qword ptr [rbp - 0xa18], rsi
0x10001e474:	lea	rsi, [rbp - 0x9e0]
0x10001e47b:	mov	rdi, rsi
0x10001e47e:	add	rdi, 0x10
0x10001e482:	mov	qword ptr [rbp - 0xa20], rdi
0x10001e489:	mov	dword ptr [rbp - 0x9dc], 0x9c4
0x10001e493:	mov	eax, dword ptr [rbp - 0x9fc]
0x10001e499:	mov	dword ptr [rbp - 0xa08], eax
0x10001e49f:	mov	eax, dword ptr [rbp - 0xa00]
0x10001e4a5:	mov	rdi, qword ptr [rbp - 0xa20]
0x10001e4ac:	mov	dword ptr [rdi], eax
0x10001e4ae:	mov	eax, dword ptr [rbp - 0xa08]
0x10001e4b4:	mov	dword ptr [rbp - 0x9e0], eax
0x10001e4ba:	mov	dword ptr [rbp - 0x9d8], 0
0x10001e4c4:	mov	dword ptr [rbp - 0x9d4], 0
0x10001e4ce:	mov	rdi, qword ptr [rbp - 0x9f0]
0x10001e4d5:	mov	r9, qword ptr [rip + 0x193e94]
0x10001e4dc:	mov	edi, dword ptr [rdi + r9]
0x10001e4e0:	mov	r9, rsi
0x10001e4e3:	mov	eax, 0xa
0x10001e4e8:	mov	qword ptr [rbp - 0xa28], rsi
0x10001e4ef:	mov	esi, eax
0x10001e4f1:	mov	rdx, r9
0x10001e4f4:	mov	rcx, r8
0x10001e4f7:	mov	r8, qword ptr [rbp - 0xa28]
0x10001e4fe:	lea	r9, [rbp - 0xa18]
0x10001e505:	call	0x10013c788
0x10001e50a:	mov	dword ptr [rbp - 0xa04], eax
0x10001e510:	cmp	dword ptr [rbp - 0xa04], 0
0x10001e517:	je	0x10001e529
0x10001e51d:	mov	byte ptr [rbp - 0x9e1], 0
0x10001e524:	jmp	0x10001e530
0x10001e529:	mov	byte ptr [rbp - 0x9e1], 1
0x10001e530:	mov	al, byte ptr [rbp - 0x9e1]
0x10001e536:	mov	rcx, qword ptr [rip + 0x16dbab]
0x10001e53d:	mov	rcx, qword ptr [rcx]
0x10001e540:	mov	rdx, qword ptr [rbp - 8]
0x10001e544:	cmp	rcx, rdx
0x10001e547:	mov	byte ptr [rbp - 0xa29], al
0x10001e54d:	jne	0x10001e565
0x10001e553:	mov	al, byte ptr [rbp - 0xa29]
0x10001e559:	movsx	eax, al
0x10001e55c:	add	rsp, 0xa30
0x10001e563:	pop	rbp
0x10001e564:	ret	
0x10001e565:	call	0x10013c8c0
0x10001e56a:	ud2	
0x10001e56c:	nop	dword ptr [rax]
0x10001e570:	push	rbp
0x10001e571:	mov	rbp, rsp
0x10001e574:	sub	rsp, 0x30
0x10001e578:	lea	rax, [rbp + 0x10]
0x10001e57c:	mov	r8d, 0xf14
0x10001e582:	mov	r9d, r8d
0x10001e585:	mov	qword ptr [rbp - 8], rdi
0x10001e589:	mov	qword ptr [rbp - 0x10], rsi
0x10001e58d:	mov	dword ptr [rbp - 0x14], edx
0x10001e590:	mov	dword ptr [rbp - 0x18], ecx
0x10001e593:	mov	qword ptr [rbp - 0x28], 0xf14
0x10001e59b:	mov	rsi, qword ptr [rbp - 8]
0x10001e59f:	mov	rdi, qword ptr [rip + 0x193dca]
0x10001e5a6:	mov	edi, dword ptr [rsi + rdi]
0x10001e5a9:	mov	rsi, rax
0x10001e5ac:	mov	ecx, 0xb
0x10001e5b1:	mov	qword ptr [rbp - 0x30], rsi
0x10001e5b5:	mov	esi, ecx
0x10001e5b7:	mov	rdx, qword ptr [rbp - 0x30]
0x10001e5bb:	mov	rcx, r9
0x10001e5be:	mov	r8, rax
0x10001e5c1:	lea	r9, [rbp - 0x28]
0x10001e5c5:	call	0x10013c788
0x10001e5ca:	mov	dword ptr [rbp - 0x1c], eax
0x10001e5cd:	mov	eax, dword ptr [rbp - 0x1c]
0x10001e5d0:	mov	r10b, al
0x10001e5d3:	movsx	eax, r10b
0x10001e5d7:	add	rsp, 0x30
0x10001e5db:	pop	rbp
0x10001e5dc:	ret	
0x10001e5dd:	nop	dword ptr [rax]
0x10001e5e0:	push	rbp
0x10001e5e1:	mov	rbp, rsp
0x10001e5e4:	sub	rsp, 0x180
0x10001e5eb:	mov	eax, 0x128
0x10001e5f0:	mov	ecx, eax
0x10001e5f2:	lea	r8, [rbp - 0x130]
0x10001e5f9:	mov	r9, qword ptr [rip + 0x16dae8]
0x10001e600:	mov	r9, qword ptr [r9]
0x10001e603:	mov	qword ptr [rbp - 8], r9
0x10001e607:	mov	qword ptr [rbp - 0x138], rdi
0x10001e60e:	mov	qword ptr [rbp - 0x140], rsi
0x10001e615:	mov	qword ptr [rbp - 0x148], rdx
0x10001e61c:	mov	qword ptr [rbp - 0x158], 0x128
0x10001e627:	mov	rdx, qword ptr [rbp - 0x148]
0x10001e62e:	mov	eax, dword ptr [rdx + 0x20]
0x10001e631:	mov	dword ptr [rbp - 0x110], eax
0x10001e637:	mov	rdx, qword ptr [rbp - 0x148]
0x10001e63e:	mov	eax, dword ptr [rdx + 0x124]
0x10001e644:	mov	dword ptr [rbp - 0xc], eax
0x10001e647:	mov	rsi, qword ptr [rbp - 0x148]
0x10001e64e:	mov	rdx, qword ptr [rbp - 0x148]
0x10001e655:	mov	eax, dword ptr [rdx + 0x20]
0x10001e658:	mov	edx, eax
0x10001e65a:	mov	rdi, r8
0x10001e65d:	call	0x10013c8a8
0x10001e662:	mov	r10d, 0x104
0x10001e668:	mov	ecx, r10d
0x10001e66b:	mov	rdx, qword ptr [rbp - 0x148]
0x10001e672:	mov	r10d, dword ptr [rdx + 0x20]
0x10001e676:	mov	edx, r10d
0x10001e679:	mov	byte ptr [rbp + rdx - 0x130], 0
0x10001e681:	lea	rdx, [rbp - 0x130]
0x10001e688:	add	rdx, 0x24
0x10001e68c:	mov	rsi, qword ptr [rbp - 0x148]
0x10001e693:	add	rsi, 0x24
0x10001e697:	mov	rdi, qword ptr [rbp - 0x148]
0x10001e69e:	mov	r10d, dword ptr [rdi + 0x124]
0x10001e6a5:	mov	edi, r10d
0x10001e6a8:	mov	qword ptr [rbp - 0x160], rdi
0x10001e6af:	mov	rdi, rdx
0x10001e6b2:	mov	rdx, qword ptr [rbp - 0x160]
0x10001e6b9:	mov	qword ptr [rbp - 0x168], rax
0x10001e6c0:	call	0x10013c8a8
0x10001e6c5:	mov	r10d, 0x128
0x10001e6cb:	mov	ecx, r10d
0x10001e6ce:	mov	rdx, qword ptr [rbp - 0x148]
0x10001e6d5:	mov	r10d, dword ptr [rdx + 0x124]
0x10001e6dc:	mov	edx, r10d
0x10001e6df:	mov	byte ptr [rbp + rdx - 0x10c], 0
0x10001e6e7:	mov	rdx, qword ptr [rbp - 0x138]
0x10001e6ee:	mov	rsi, qword ptr [rip + 0x193c7b]
0x10001e6f5:	mov	edi, dword ptr [rdx + rsi]
0x10001e6f8:	lea	rdx, [rbp - 0x130]
0x10001e6ff:	mov	rsi, rdx
0x10001e702:	mov	r10d, 0xc
0x10001e708:	mov	qword ptr [rbp - 0x170], rsi
0x10001e70f:	mov	esi, r10d
0x10001e712:	mov	r8, qword ptr [rbp - 0x170]
0x10001e719:	mov	qword ptr [rbp - 0x178], rdx
0x10001e720:	mov	rdx, r8
0x10001e723:	mov	r8, qword ptr [rbp - 0x178]
0x10001e72a:	lea	r9, [rbp - 0x158]
0x10001e731:	mov	qword ptr [rbp - 0x180], rax
0x10001e738:	call	0x10013c788
0x10001e73d:	mov	dword ptr [rbp - 0x14c], eax
0x10001e743:	mov	rcx, qword ptr [rip + 0x16d99e]
0x10001e74a:	mov	rcx, qword ptr [rcx]
0x10001e74d:	mov	rdx, qword ptr [rbp - 8]
0x10001e751:	cmp	rcx, rdx
0x10001e754:	jne	0x10001e768
0x10001e75a:	mov	al, 1
0x10001e75c:	movsx	eax, al
0x10001e75f:	add	rsp, 0x180
0x10001e766:	pop	rbp
0x10001e767:	ret	
0x10001e768:	call	0x10013c8c0
0x10001e76d:	ud2	
0x10001e76f:	nop	