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