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