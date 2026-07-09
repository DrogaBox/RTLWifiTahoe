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