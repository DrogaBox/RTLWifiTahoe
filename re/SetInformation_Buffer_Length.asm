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