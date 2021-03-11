.386
data segment use16
   inputfile   db 'Input file name: $'
   inputstring db 'Input a hex string, e.g. 41 42 43 0D 0A', 0Dh, 0Ah, '$'
   outputfound db 'Found at ', 8 dup('0'), 0Dh, 0Ah, '$'
   notfound    db 'Not found!', 0Dh, 0Ah, '$'
   inputerror  db 'Fatal input!', 0Dh, 0Ah, '$'
   filename    db 17
               db ?
	       db 17 dup(?)
   string      db 101
               db ?
	       db 101 dup(?)
   fp          dw 0
   len         dd 0;文件长度
   strlen      db 0;输入字符长度
   hex	       db 100 dup(0);存入输入字节
   newoffset   dd 0;buf[0]中的字节距离文件开端的偏移量
   readlen     dw 0;本次要读的字节数
   prolen      dw 0;上次已搜索过的字节数
   remainlen   dw 0;上次搜索是余下未搜索的字节数
   buf         db 100 dup(0)
   buflen      db 0
   p           dw 0
   q           dw 0
   distance    dw 0
data ends

code segment use16
assume ds:data, cs:code
find:
   xor ax, ax
   mov al, string[1]
   mov strlen, al
   ;把输入十六进制字符转化为字节值
   xor di, di
   xor si, si
pro1:
   xor cx, cx
   mov cl, string[2+di]
   cmp cl, '9'
   ja ischar1
   sub cl, '0'
   jmp pro2
ischar1:
   sub cl, 'A'
   add cl, 10
pro2:
   inc di
   rol cx, 4
   mov hex[si], cl
   mov cl, string[2+di]
   cmp cl, '9'
   ja ischar2
   sub cl, '0'
   jmp pro3
ischar2:
   sub cl, 'A'
   add cl, 10
pro3:
   add hex[si], cl
   add di, 2
   inc si
   cmp di, ax
   ja pro1
   ;al=(strlen+1)/3
   inc al
   mov cl, 3
   div cl
   mov strlen, al
   mov di, 100
   mov readlen, di
do1:
   ;newoffset += prolen
   xor ebx, ebx
   mov bx, prolen
   add newoffset, ebx
   ;readlen = min(n,readlen)
   mov bx, readlen
   cmp ebx, len
   jb do2
   mov ebx, len
   mov readlen, bx
do2:
   ;fread(buf+remained_len, 1, read_len, fp)
   ;读取read_len字节到buf+remained_len中
   mov ah, 3Fh
   mov bx, [fp]
   mov cx, readlen
   lea dx, buf
   add dx, remainlen
   int 21h
   ;n -= readlen,n为文件中剩余未读的字节数
   xor ebx, ebx
   mov bx, readlen
   mov eax, len
   sub eax, ebx
   mov len, eax
   ;buflen = remainlen + readlen
   mov ax, remainlen
   add ax, readlen
   mov buflen, al
   xor bx, bx
   mov bl, strlen
   cmp ax, bx;buflen < strlen,若buf中的字节数不足, 则n一定为0, 于是回上去结束循环
   jb do1

   ;q = buf,q为本次搜索起点
   lea bx, buf
   mov q, bx
do3:
   ;distance = buf + buflen -hexlen - q + 1
   xor cx, cx
   mov cl, buflen
   sub cl, strlen
   lea bx, buf
   add cx, bx
   sub cx, q
   inc cx
   mov distance, cx
   ;p = memchr(q, hex[0], distance),在[q, q+distance-1]范围内寻找hex[0]
   xor ax, ax
   mov al, hex[0]
   mov di, q
   repne scasb
   jne do4;没有找到则退出循环
   dec di
   mov p, di
   ;memcmp(p, hex, hex_len) != 0,比较p和hex指向的hex_len字节是否相同
   mov di, p
   lea si, hex
   xor cx, cx
   mov cl, strlen
   repe cmpsb
   jz return;相同则返回偏移量
   ;q = p+1
   mov di, p
   inc di
   mov q, di
   ;q <= buf+buf_len-hex_len,判断循环
   lea dx, buf
   xor ax, ax
   mov al, buflen
   sub al, strlen
   add dx, ax
   cmp dx, q
   jb do4
   jmp do3
do4:
   ;processed_len = buf_len - hex_len + 1
   xor ax, ax
   mov al, buflen
   sub al, strlen
   inc ax
   mov prolen, ax
   ;q = buf + processed_len
   lea bx, buf
   add ax, bx
   mov q, ax
   ;remained_len = hex_len - 1;
   xor ax, ax
   mov al, strlen
   dec ax
   mov remainlen, ax
   ;memcpy(buf, q, remained_len);
   mov cx, remainlen
   mov si, q
   lea di, buf
   rep movsb
   ;read_len = sizeof(buf) - remained_len
   mov ax, 100
   sub ax, remainlen
   mov readlen, ax

   cmp len, 0
   jnz do1
   mov cl, 0
   jmp endret
return:
   ;return offset + (p-buf)
   mov eax, newoffset
   xor ebx, ebx
   mov bx, p
   sub bx, offset buf
   add eax, ebx
   mov cl, 1
endret:
   ret
   
main:
   mov ax, data
   mov ds, ax
   mov es, ax
   ;提示词1
   mov dx, offset inputfile
   mov ah, 09h
   int 21h;
   mov ah, 0Ah
   mov dx, offset filename
   int 21h
   mov ah, 2
   mov dl, 0Dh
   int 21h
   mov ah, 2
   mov dl, 0Ah
   int 21h;输入的文件名存入filename
   lea bx, filename+2
   xor cx, cx
   mov cl, filename[1]
   add bl, cl
   mov byte ptr ds:[bx], 0;文件名最后一位改成0
   ;打开文件
   mov ah, 3Dh;打开文件功能号
   mov al, 0;只读
   mov dx, offset filename+2;ds:dx
   int 21h
   jc errorexit
   mov [fp], ax;保存目标文件句柄
   ;提示词2
   mov dx, offset inputstring
   mov ah, 09h
   int 21h
   mov ah, 0Ah
   mov dx, offset string
   int 21h
   mov ah, 2
   mov dl, 0Dh
   int 21h
   mov ah, 2
   mov dl, 0Ah
   int 21;输入的十六进制串存入string
   lea bx, string+2
   xor cx, cx
   mov cl, string[1]
   add bl, cl
   mov byte ptr ds:[bx], 0
   
   ;移动文件指针到EOF
   mov ah, 42h
   mov al, 2
   mov bx, [fp]
   xor cx, cx
   xor dx, dx
   int 21h;返回dx:ax为文件长度
   ;把文件长度保存到变量n中
   mov word ptr len[0], ax
   mov word ptr len[2], dx
   ;移动文件指针到文件开端
   mov ah, 42h
   mov al, 0
   mov bx, [fp]
   xor cx, cx
   xor dx, dx
   int 21h
   call find;调用函数

   push eax
   mov ah, 3Eh
   mov bx, [fp]
   int 21h;关闭文件
   cmp cl, 0
   jz notfoundexit
   pop eax;弹出返回值      
   mov di, 9;输出值从outputfound第9位开始
output:
   mov cl,4
   rol eax, cl
   mov bl, al
   and bl, 0Fh
   cmp bl, 9
   jbe isdigit
   sub bl, 10
   add bl, 'A'
   jmp next
isdigit:
   add bl, '0'
next:
   mov outputfound[di], bl
   inc di
   cmp di, 17
   je foundexit
   jmp output
errorexit:
   mov dx, offset inputerror
   mov ah, 09h
   int 21h
   jmp exit
foundexit:
   mov ah, 9
   lea dx, outputfound
   int 21h
   jmp exit
notfoundexit:
   mov dx, offset notfound
   mov ah, 09h
   int 21h
exit:
   mov ah, 4Ch
   int 21h
code ends
   end main

