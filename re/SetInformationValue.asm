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