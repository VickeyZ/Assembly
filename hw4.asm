data segment
filename db 98, 99 dup(0)
string db 98, 99 dup(0)
char db 0
qlength db 0
n db 4 dup(0)
handle dw 0
nfstr db "not found",'$'
fdat db "found at",'$'
pos db 8 dup(0)
pfile db 4 dup(0)
data ends
code segment
assume cs:code, ds:data
getname:;��ȡ�ļ���
	push ax
	push dx
	push di
	mov ah, 0Ah
	mov dx, offset filename
	int 21h
	mov ah, 0
	mov al, byte ptr[filename+1]
	mov di, offset(filename)+2
	add di, ax
	mov byte ptr[di], 0
	pop di
	pop dx
	pop ax
	ret
gets:;��ȡ�����ַ���
	push ax
	push dx
	mov ah, 0Ah
	mov dx, offset(string)
	int 21h
	pop dx
	pop ax
transString:;������һ�������ǰ�������ַ�ת��ascii�봮��ָ��,ͦ��ָ���
	push si
	push di
	push dx
	push bx
	push ax
	push cx
	mov dh, 0
	mov dl, byte ptr [offset(string)+1];dx�����ܹ��ж��ٸ��ַ���Ҫת��
	mov bx, 0;bx�����ܹ�ת���˶��ٸ��ַ�,Ҳ����pNewArray
	mov si, offset(string)+2;siָ��string��������,si�����������������ջ��ָ��
	mov di, offset(string)+2;diҲָ��string��������,di�����������������ջ��ָ��
	mov cx, 0;cx��ֵ����Ϊ0,cxΪȥ���ո��õĸ�������,��0,1Ϊѭ��
	jmp tsHead
tsError:
	call error
tsHead:
	push dx
	mov dh, 0
	mov dl, [string+1]
	cmp bx, dx
	ja tsEnd
	pop dx
	cmp byte ptr[di],'0'
	jb tsError
	cmp byte ptr[di],'9'
	jbe tsDigit
	cmp byte ptr[di],'A'
	jb tsError
	cmp byte ptr[di],'F'
	jbe tsUCase
	cmp byte ptr[di],'a'
	jb tsError
	cmp byte ptr[di],'f'
	jbe tsLCase
	jmp tsError
tsDigit:
	mov al, byte ptr[di];alΪ�������ascii��
	sub al, '0'
	jmp tsBottom
tsUCase:
	mov al, byte ptr[di];alΪ�������ascii��
	sub al, 'A'
	jmp tsBottom
tsLCase:
	mov al, byte ptr[di];alΪ�������ascii��
	sub al, 'a'
	jmp tsBottom
tsBottom:	
	cmp cx, 0
	je tsZero
	cmp cx, 1
	je tsOne
tsZero:
	mov byte ptr ds:[si], al
	inc cx
	inc di
	inc bx
	jmp tsHead
tsOne:
	push ax
	push bx
	mov al, ds:[si]
	mov bl, 10h
	mul bl
	mov ds:[si], al
	pop bx
	pop ax
	add byte ptr ds:[si], al
	inc si
	add di, 2
	add bx, 2
	mov cx, 0
	jmp tsHead
tsEnd:
	pop dx
	sub si, 2
	mov ax, si
	sub ax, offset(string)
	mov di, offset(string)+1
	mov [qlength], al
	pop cx
	pop ax
	pop bx
	pop dx
	pop si
	pop di
	ret
mainError:;��ת
	call error
main:;������
   mov ax, data
   mov ds, ax
	call getname
   mov ah, 3Dh; open
   mov al, 0; ReadOnly
   mov dx, offset filename
	add dx, 2
   int 21h
   jc mainError
   mov handle, ax; �����ļ����
	call gets
	mov ah, 42h
	mov al, 2
	mov bx, handle
	xor cx, cx
	xor dx, dx
	int 21h; ����DX:AXΪ�ļ�����
	mov word ptr n[0], ax
	mov word ptr n[2], dx
	mov ah, 42h
	mov al, 0
	mov bx, handle
	xor cx, cx
	xor dx, dx
	int 21h;��ָ���ƻ��ļ�ͷ
	mov di, offset string
	add di, 2
	mov bx, 0;��si������ǰ��ƥ����ٸ��ַ�
	mov word ptr[pfile], 0
	mov word ptr[pfile+2], 0
	jmp rotatetoread
notfoundcall:
	call notfound
rotatetoread:;�ⲿ����Ѱ�ҵ�һ��ƥ�䵽���ַ�,������ʱ�����ļ�ָ��λ��
	push ax
	push bx
	push cx
	push dx
	mov ah, 42h
	mov al, 0
	mov bx, handle
	mov cx, word ptr[pfile+2]
	mov dx, word ptr[pfile]
	int 21h;��ָ���Ƶ�֮ǰ�ĵط�
   mov ah, 3Fh; read
   mov bx, handle
   mov cx, 1
   mov dx, offset(char)
   int 21h
	cmp ax, 0
	je notfoundcall
	mov ax, word ptr[pfile]
	mov dx, word ptr[pfile+2]
	inc ax
	jnc rotatetoreadplus
addx:
	inc dx
rotatetoreadplus:;��ǰ����һ���,����������
	mov word ptr[pfile], ax
	mov word ptr[pfile+2], dx
	pop dx
	pop cx
	pop bx
	pop ax
	mov di, offset string
	add di, 2
	mov bx, 0
	mov ah, byte ptr[char]
	mov al, byte ptr[di]
	cmp ah, al
	je success
	jmp rotatetoread
sucrotread:;�ⲿ����ƥ�䵽��һ���ַ���ѭ��ƥ��֮����ַ�
	push ax
	push bx
	push cx
	push dx
	mov ah, 3Fh
	mov bx, handle
	mov cx, 1
	mov dx, offset char
	int 21h
	pop dx
	pop cx
	pop bx
	mov ah, byte ptr[char]
	mov al, byte ptr[di]
	cmp ah, al
	je success
	jmp rotatetoread
	pop ax
success:;���ǳɹ�ƥ����һ���ַ�
	inc di
	inc bx
	cmp bl, [qlength]
	jne sucrotread
founded:;�ҵ����ַ���
	mov ah, 02h
	mov dl, 0Dh
	int 21h
	mov ah, 02h
	mov dl, 0Ah
	int 21h
   mov ah, 3Eh; close file
   mov bx, handle
   int 21h
	mov ax, word ptr [pfile]
	mov dx, word ptr [pfile+2]
	dec ax
	jnc foundedafter
decdx:
	dec dx
foundedafter:
	mov byte ptr [pos+4], dh
	mov byte ptr [pos+5], dl
	mov byte ptr [pos+6], ah
	mov byte ptr [pos+7], al
	mov ah, 09h
	mov dx, offset fdat
	int 21h
	mov bx, 8
	mov di, offset pos
	mov ah, 02h
	mov dl, ' '
	int 21h
printpostion:;��������һ�������ǰѵ�ַ��ӡ������ָ��
	cmp byte ptr[di], 0Ah
	jb ppdigit
	jmp ppletter
ppdigit:
	mov dl, byte ptr [di]
	add dl, '0'
	mov ah, 02h
	int 21h
	jmp ppbottom
ppletter:
	mov dl, byte ptr [di]
	sub dl, 0Ah
	add dl, 'A'
	mov ah, 02h
	int 21h
ppbottom:
	inc di
	dec bx
	jz error
	jmp printpostion
notfound:;����û���ҵ��ַ���
   mov ah, 3Eh; close file
   mov bx, handle
   int 21h
	mov ah, 09h
	mov dx, offset nfstr
	int 21h
error:;����������
   mov ah, 4Ch
   int 21h
code ends
end main