#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#pragma warning (disable : 4996)

#define MAXTOKENS 100
#define MAXTOKENLEN 64

enum type_tag{IDENTIFIER, QUALIFIER, TYPE}; /*��ʶ�����޶���������*/

struct token{
	char type;
	char string[MAXTOKENLEN];
};

int top = -1;
struct token stack[MAXTOKENS];
struct token this;

#define pop stack[top--]
#define push(s) stack[++top] = s

#define STRCMP(a,R,b) (strcmp(a,b) R 0)

/*�ƶϱ�ʶ������*/
enum type_tag classify_string(void)
{
	char *s = this.string;
	if (STRCMP(s,==,"const"))
	{
		strcpy(s,"read-only");
		return QUALIFIER;
	}
	if (STRCMP(s,==,"volatile")) return QUALIFIER;
	if (STRCMP(s,==,"void")) return TYPE;
	if (STRCMP(s,==,"char")) return TYPE;
	if (STRCMP(s,==,"signed")) return TYPE;
	if (STRCMP(s,==,"unsigned")) return TYPE;
	if (STRCMP(s,==,"short")) return TYPE;
	if (STRCMP(s,==,"int")) return TYPE;
	if (STRCMP(s,==,"long")) return TYPE;
	if (STRCMP(s,==,"double")) return TYPE;
	if (STRCMP(s,==,"float")) return TYPE;
	if (STRCMP(s,==,"struct")) return TYPE;
	if (STRCMP(s,==,"union")) return TYPE;
	if (STRCMP(s,==,"enum")) return TYPE;
 	return IDENTIFIER;
}

/*��ȡ��һ����ǵ�"this"
*���ܶ�����ַ���������ĸ�����֡�*[]()
*/
void gettoken(void)
{
	char *p = this.string;
	
	/*�Թ��հ��ַ�*/
	while((*p = (char)getchar()) == ' ') ;
	
	/*����ĸ������*/
	if (isalnum(*p))
	{
		while(isalnum(*++p = (char)getchar())) ; /*������һ��������ĸ������Ϊֹ*/
		ungetc(*p,stdin);  /*��һ���ַ����˵�������*/
		*p = '\0';
		this.type = (char)classify_string();
		return;
	}
	
	if (*p == '*')
	{
		strcpy(this.string,"pointer to");
		this.type = '*';
		return;
	}
	
	this.string[1] = '\0';
	this.type = *p;
	return;
}

/*������з������̵Ĵ����*/
int read_to_first_identifier(void)
{
	gettoken(); /*ȡ��һ�����*/
	while(this.type != (char)IDENTIFIER) /* ȡ����ʶ����ֹ����ʶ��δѹ��ջ */
	{
		push(this);
		gettoken();
	}
	
	printf("%s is ",this.string);
	gettoken();/*��ȡ��ʶ���ұ�һ������*/
	return 0;
}

int deal_with_arrays(void)
{
	while(this.type == '[')
	{
		printf("array ");
		gettoken();/*�������']'*/
		if (isdigit(this.string[0]))
		{
			printf("0..%d ",atoi(this.string)-1);
			gettoken(); /*ȡ']'*/
		}
		
		gettoken(); /* ��ȡ']'�����һ����ǣ����ܻ���һ��'[' */
		printf("of ");
	}
	
	return 0;
}

int deal_with_function_args(void)
{
	while(this.type != ')') /* �Ѻ�������ȡ�������� */
	{
		gettoken();
	}
	
	gettoken(); /* ��ȡ')'�����һ����� */
	printf("function returning ");
	return 0;
}

int deal_with_pointers(void)
{
	while(stack[top].type == '*')
	{
		printf("%s ",pop.string);
	}
	return 0;
}

int deal_with_declarator(void)
{
	/*�����ʶ������ܴ��ڵ��������*/
	switch(this.type)
	{
		case '[' : deal_with_arrays();break;
		case '(' : deal_with_function_args();break;
		default : break;
	}
	
	deal_with_pointers(); /* ջ��Ԫ����'*' */
	
	/*�����ڶ�����ʶ��֮ǰѹ���ջ�ķ���*/
	while(top >= 0)
	{
		if (stack[top].type == '(')
		{
			pop;
			gettoken(); /* ��ȡ')'֮��ķ��ţ�������'('��'[' */
			deal_with_declarator();  /* �ݹ���� */
		}
		else
		{
			printf("%s ",pop.string);
		}
	}
	
	return 0;
}

int main(void)
{
	/*�����ѹ���ջ�У�ֱ��������ʶ��*/
	read_to_first_identifier();
	deal_with_declarator();
	printf("\n");
	
	return 0;
}
