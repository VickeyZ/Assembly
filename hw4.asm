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
getname:;读取文件名
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
gets:;读取待测字符串
	push ax
	push dx
	mov ah, 0Ah
	mov dx, offset(string)
	int 21h
	pop dx
	pop ax
transString:;下面这一长串都是把输入的字符转成ascii码串的指令,挺多指令的
	push si
	push di
	push dx
	push bx
	push ax
	push cx
	mov dh, 0
	mov dl, byte ptr [offset(string)+1];dx代表总共有多少个字符需要转换
	mov bx, 0;bx代表总共转换了多少个字符,也就是pNewArray
	mov si, offset(string)+2;si指向string数组的起点,si被用来当作新数组的栈顶指针
	mov di, offset(string)+2;di也指向string数组的起点,di被用来当作旧数组的栈顶指针
	mov cx, 0;cx初值被设为0,cx为去除空格用的辅助变量,以0,1为循环
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
	mov al, byte ptr[di];al为待处理的ascii码
	sub al, '0'
	jmp tsBottom
tsUCase:
	mov al, byte ptr[di];al为待处理的ascii码
	sub al, 'A'
	jmp tsBottom
tsLCase:
	mov al, byte ptr[di];al为待处理的ascii码
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
mainError:;中转
	call error
main:;主函数
   mov ax, data
   mov ds, ax
	call getname
   mov ah, 3Dh; open
   mov al, 0; ReadOnly
   mov dx, offset filename
	add dx, 2
   int 21h
   jc mainError
   mov handle, ax; 保存文件句柄
	call gets
	mov ah, 42h
	mov al, 2
	mov bx, handle
	xor cx, cx
	xor dx, dx
	int 21h; 返回DX:AX为文件长度
	mov word ptr n[0], ax
	mov word ptr n[2], dx
	mov ah, 42h
	mov al, 0
	mov bx, handle
	xor cx, cx
	xor dx, dx
	int 21h;将指针移回文件头
	mov di, offset string
	add di, 2
	mov bx, 0;用si来代表当前已匹配多少个字符
	mov word ptr[pfile], 0
	mov word ptr[pfile+2], 0
	jmp rotatetoread
notfoundcall:
	call notfound
rotatetoread:;这部分是寻找第一个匹配到的字符,并且随时保存文件指针位置
	push ax
	push bx
	push cx
	push dx
	mov ah, 42h
	mov al, 0
	mov bx, handle
	mov cx, word ptr[pfile+2]
	mov dx, word ptr[pfile]
	int 21h;将指针移到之前的地方
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
rotatetoreadplus:;和前面是一起的,名字随便起的
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
sucrotread:;这部分是匹配到第一个字符后循环匹配之后的字符
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
success:;这是成功匹配了一个字符
	inc di
	inc bx
	cmp bl, [qlength]
	jne sucrotread
founded:;找到了字符串
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
printpostion:;接下来的一长串都是把地址打印出来的指令
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
notfound:;这是没有找到字符串
   mov ah, 3Eh; close file
   mov bx, handle
   int 21h
	mov ah, 09h
	mov dx, offset nfstr
	int 21h
error:;结束并跳出
   mov ah, 4Ch
   int 21h
code ends
end main