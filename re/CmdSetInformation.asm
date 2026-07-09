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