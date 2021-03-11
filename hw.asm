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
   len         dd 0;�ļ�����
   strlen      db 0;�����ַ�����
   hex	       db 100 dup(0);���������ֽ�
   newoffset   dd 0;buf[0]�е��ֽھ����ļ����˵�ƫ����
   readlen     dw 0;����Ҫ�����ֽ���
   prolen      dw 0;�ϴ������������ֽ���
   remainlen   dw 0;�ϴ�����������δ�������ֽ���
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
   ;������ʮ�������ַ�ת��Ϊ�ֽ�ֵ
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
   ;��ȡread_len�ֽڵ�buf+remained_len��
   mov ah, 3Fh
   mov bx, [fp]
   mov cx, readlen
   lea dx, buf
   add dx, remainlen
   int 21h
   ;n -= readlen,nΪ�ļ���ʣ��δ�����ֽ���
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
   cmp ax, bx;buflen < strlen,��buf�е��ֽ�������, ��nһ��Ϊ0, ���ǻ���ȥ����ѭ��
   jb do1

   ;q = buf,qΪ�����������
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
   ;p = memchr(q, hex[0], distance),��[q, q+distance-1]��Χ��Ѱ��hex[0]
   xor ax, ax
   mov al, hex[0]
   mov di, q
   repne scasb
   jne do4;û���ҵ����˳�ѭ��
   dec di
   mov p, di
   ;memcmp(p, hex, hex_len) != 0,�Ƚ�p��hexָ���hex_len�ֽ��Ƿ���ͬ
   mov di, p
   lea si, hex
   xor cx, cx
   mov cl, strlen
   repe cmpsb
   jz return;��ͬ�򷵻�ƫ����
   ;q = p+1
   mov di, p
   inc di
   mov q, di
   ;q <= buf+buf_len-hex_len,�ж�ѭ��
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
   ;��ʾ��1
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
   int 21h;������ļ�������filename
   lea bx, filename+2
   xor cx, cx
   mov cl, filename[1]
   add bl, cl
   mov byte ptr ds:[bx], 0;�ļ������һλ�ĳ�0
   ;���ļ�
   mov ah, 3Dh;���ļ����ܺ�
   mov al, 0;ֻ��
   mov dx, offset filename+2;ds:dx
   int 21h
   jc errorexit
   mov [fp], ax;����Ŀ���ļ����
   ;��ʾ��2
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
   int 21;�����ʮ�����ƴ�����string
   lea bx, string+2
   xor cx, cx
   mov cl, string[1]
   add bl, cl
   mov byte ptr ds:[bx], 0
   
   ;�ƶ��ļ�ָ�뵽EOF
   mov ah, 42h
   mov al, 2
   mov bx, [fp]
   xor cx, cx
   xor dx, dx
   int 21h;����dx:axΪ�ļ�����
   ;���ļ����ȱ��浽����n��
   mov word ptr len[0], ax
   mov word ptr len[2], dx
   ;�ƶ��ļ�ָ�뵽�ļ�����
   mov ah, 42h
   mov al, 0
   mov bx, [fp]
   xor cx, cx
   xor dx, dx
   int 21h
   call find;���ú���

   push eax
   mov ah, 3Eh
   mov bx, [fp]
   int 21h;�ر��ļ�
   cmp cl, 0
   jz notfoundexit
   pop eax;��������ֵ      
   mov di, 9;���ֵ��outputfound��9λ��ʼ
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

