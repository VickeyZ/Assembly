data segment
buf db 8, 0, 8 dup(0)
s db 100 dup(0) 
t db 100 dup(0)
data ends

code segment
assume cs:code, ds:data
input proc; procedure
   push bx
   push cx
   push dx
   push si
   push di
   mov ah, 0Ah
   mov dx, si
   int 21h
   mov cx, 0
   mov cl, [si+1]; CX=count of char
comment # ===================================
   jcxz input_done
   lea bx, [si+2]; bx->���������
copy_next_char:
   mov al, [bx]
   mov [di], al
   inc bx
   inc di
   dec cx
   jnz copy_next_char
============================================== #
   lea si, [si+2]
   cld
   rep movsb

input_done:
   mov byte ptr [di], 0
   pop di
   pop si
   pop dx
   pop cx
   pop bx
   ret
input endp; end of procedure

main:
   mov ax, data
   mov ds, ax
   mov es, ax
   mov si, offset buf
   mov di, offset s
   call input; ����ds:siָ�������ģ�����������
             ; ���Ƶ�es:diָ����ڴ���
   mov si, offset buf
   mov di, offset t
   call input
   mov ah, 4Ch
   int 21h
code ends
end main
