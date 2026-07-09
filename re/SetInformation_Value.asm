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