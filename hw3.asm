comment #
��3�λ����ҵ
������������ʮ���ƷǷ�����(��65535)����������֮�˻���
�ֱ���ʮ���ơ�ʮ�����ơ������������������磺
���룺
12345
65535
�����
12345*65535=
809029575
3038CFC7h
0011 0000 0011 1000 1100 1111 1100 0111B
��������һ���ַ�������ͨ������int 21h��0Ah�ӹ���ʵ�֣�����ɲο��̲�P.216��
ʮ�����Ƶ�������������8λ��ǰ����Ҫ��0�ճ�8λ��
�����Ƶ�������Ҫ�ֳ�8�飬ÿ��4λ������֮���һ��
���⣬����������ʹ��32λ�Ĵ�����
��ҵ�ϴ���ftp://10.71.45.100/��3�λ����ҵ
��¼�û����������Ϊ: bhhasm
��ҵ�ļ�������ʽ��ѧ������.asm
#

.386
data segment use16
input1 db 6;�ڴ滺������input1[1]���ʵ�������ַ�����offset input1+2 �������ַ�
       db ?
       db 6 dup(?)
input2 db 6
       db ?
       db 6 dup(?)
a      dd 0
ans    dd 0
dcm    db 10 dup(' '), 0Dh, 0Ah, '$'
hex    db 8  dup(0), 'h', 0Dh, 0Ah, '$'
bin    db "0000 0000 0000 0000 0000 0000 0000 0000B", 0Dh, 0Ah, '$' 
error  db 'Input Error', 0Dh, 0Ah, '$'
data ends

stack1 segment stack
	dw 100h dup(?)
stack1 ends

code segment use16
assume cs:code, ds:data, ss:stack1
inputerror:
   mov dx, offset error
   mov ah, 09h
   int 21h
   jmp done
main:
   mov ax, data
   mov ds, ax
   mov ah, 0Ah
   mov dx, offset input1
   int 21h
   mov ah, 2
   mov dl, 0Dh
   int 21h
   mov dl, 0Ah
   int 21h;�����һ��ʮ������
   mov ah, 0Ah
   mov dx, offset input2
   int 21h
   mov ah, 2
   mov dl, 0Dh
   int 21h
   mov ah, 2
   mov dl, 0Ah
   int 21h;����ڶ���ʮ������
pro1:
   xor cx, cx;��0
   mov cl, input1[1];�ַ�������Ϊѭ������
   cmp cl, 5
   ja  inputerror
   mov bx, offset input1+2
print1:
   mov ah, 2
   mov dl, [bx]
   cmp dl, '0'
   jb  inputerror
   cmp dl, '9'
   ja  inputerror
   int 21h;�ַ�������
   inc bx
   dec cx
   jnz print1
pro2:
   mov ah, 2
   mov dl, '*'
   int 21h
   xor cx, cx
   mov cl, input2[1]
   cmp cl, 5
   ja inputerror
   mov bx, offset input2+2
print2:
   mov ah, 2
   mov dl, [bx]
   cmp dl, '0'
   jb  inputerror
   cmp dl, '9'
   ja  inputerror
   int 21h
   inc bx
   dec cx
   jnz print2
pro3:
   mov ah, 2
   mov dl, '='
   int 21h
   mov ah, 2
   mov dl, 0Dh
   int 21h
   mov ah, 2
   mov dl, 0Ah
   int 21h;��һ�����
tran1:			;����һ���ַ�ת��Ϊʮ������
   xor eax, eax
   xor edx, edx
   mov si, offset input1+2
tran10_1:
   mov cl, [si]
   cmp cl, 0Dh;�ж��ַ��Ƿ��ȡ��
   je  tran2
   mov ebx, 10
   mul ebx;λ������eax
   xor edx, edx
   mov dl, [si]
   sub dl, '0';��λ������edx
   add eax, edx
   inc si
   jmp tran10_1
tran2:			;�ڶ����ַ�
   mov a, eax;�����һ���ַ���ʮ����ֵ
   cmp a, 65535
   ja  inputerror
   xor eax, eax
   xor edx, edx
   mov si, offset input2+2
tran10_2:
   mov cl, [si]
   cmp cl, 0Dh
   je  tran3
   mov ebx, 10
   mul ebx
   xor edx, edx
   mov dl, [si]
   sub dl, '0'
   add eax, edx
   inc si
   jmp tran10_2
tran3:
   mov ebx, a
   mov a, eax
   cmp a, 65535
   ja inputerror
   mul ebx
   mov ans, eax;���˷��������ans
   xor di, di
   xor cx, cx
decimal:
   xor edx, edx
   mov ebx, 10
   div ebx;eax=�̣� edx=����
   add dl, '0'
   push dx
   inc cx
   cmp eax, 0
   jne decimal
pop_d:
   pop dx
   mov dcm[di], dl;�����������飬���
   inc di
   dec cx
   jnz pop_d
   mov ah, 9
   mov dx, offset dcm
   int 21h
   mov eax, ans
   xor di, di
   mov cx, 8
hexadecimal:
   rol eax, 4
   push eax
   and eax, 0Fh
   cmp al, 10
   jb digit
   sub al, 10
   add al, 'A'
   jmp ctn
digit:
   add al, '0'
ctn:
   mov hex[di], al
   pop eax
   inc di
   dec cx
   jnz hexadecimal
   mov ah, 9
   mov dx, offset hex
   int 21h
   mov eax, ans
   xor di, di
binary:
   cmp bin[di], 'B'
   je bin_print
   cmp bin[di], ' '
   je next
   shl eax, 1
   jnc next
   mov bin[di], '1'
   inc di
   jmp binary
next:
   inc di
   jmp binary
bin_print:
   mov ah, 9
   mov dx, offset bin
   int 21h
done:
   mov ah, 4Ch
   int 21h
code ends
end main