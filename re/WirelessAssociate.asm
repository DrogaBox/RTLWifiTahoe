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