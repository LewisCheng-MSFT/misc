#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define OK 0
#define SHIT 1

#define YES 1
#define NO 0

#define MAX_COMMAND_SIZE 100
#define EDIT_BUFFER_SIZE 256
#define BYTES_EACH_LINE 16

#define QUIT_EDITOR 12345

typedef unsigned char uchar;

int interaction(const char *);
int parse_and_execute();

void show_help();
int parse_number();
int get_hex(uchar);
int parse_xnumber();
int check_file_size();
int brute_force_find_string(int);

void write_back_edit_buffer(int);
void switch_edit_buffer(int);
void show_edit_buffer();
void fill_edit_buffer();

FILE * strm;
int file_size;

uchar command_buffer[MAX_COMMAND_SIZE];
uchar * cbptr;	// Pointer to command buffer.

uchar edit_buffer[EDIT_BUFFER_SIZE];
uchar * ebptr; // Pointer to edit buffer.
int ebmodified; // If the content in the buffer has been modified.
int ebsize; // Actual bytes in the buffer.
int ebo;	// Offset of edit buffer in the file.

int main(int argc, char * argv[])
{
	printf("����ʮ�����Ʊ༭��\n���ߣ�����  ���ڣ�2011/2/2\n\n");
	switch (argc)
	{
	case 1:
		printf("�÷���zghex <filename>\n");
		return OK;

	case 2:
		printf("�ļ�����\"%s\"\n", argv[1]);
		strm = fopen(argv[1], "r+b");
		if (!strm)
		{
			printf("�����ļ��򲻿���SHIT��������֪��ˣ����ĺ��~\n");
			return SHIT;
		}
		if (check_file_size() == SHIT) return SHIT;
		fill_edit_buffer();
		printf("��ʼ��������ɣ�����\'?\'��ʾ������\n");
		return interaction(argv[1]);

	default:
		printf("�粻����%d������������\n", argc - 1);
		return SHIT;
	}

	return OK;
}

int interaction(const char * filename)
{
	for (;;)
	{
		printf("\n>");
		scanf("%s", command_buffer);
		if (command_buffer[MAX_COMMAND_SIZE - 1] != 0)
		{
			printf("�������������̫����\n");
			continue;
		}
		cbptr = command_buffer;
		int ret = parse_and_execute();
		if (ret == QUIT_EDITOR) break;
		if (ret == OK) printf("�㶨��\n");
	}
	printf("���ðף�Ը��������ͬ�У�\n");
	return OK;
}

int parse_and_execute()
{
	int arg1;
	int new_ebo;

	if (strcmp(cbptr, "w") == 0)
	{
		write_back_edit_buffer(NO);
		return OK;
	}

	if (strcmp(cbptr, "p") == 0)
	{
		new_ebo = ebo - EDIT_BUFFER_SIZE;
		if (new_ebo < 0)
		{
			printf("���󣺵����ļ��ײ���\n");
			return SHIT;
		}
		switch_edit_buffer(new_ebo);
		return OK;
	}

	if (strcmp(cbptr, "q") == 0)
	{
		write_back_edit_buffer(YES);
		fclose(strm);
		return QUIT_EDITOR;
	}

	if (strcmp(cbptr, "s") == 0)
	{
		show_edit_buffer();
		return OK;
	}

	if (strcmp(cbptr, "?") == 0)
	{
		show_help();
		return OK;
	}

	if (*cbptr == 'n')
	{
		if (strcmp(cbptr, "n") == 0)
		{
			new_ebo = ebo + EDIT_BUFFER_SIZE;
			if (new_ebo >= file_size)
			{
				printf("���󣺵����ļ�β��\n");
				return SHIT;
			}
		}
		else if (strcmp(cbptr, "nn") == 0)
		{
			new_ebo = file_size & 0xFFFFFF00;
		}
		else
		{
			printf("���󣺸粻���������\n");
			return SHIT;
		}

		switch_edit_buffer(new_ebo);
		return OK;
	}

	if (*cbptr == 'm')
	{
		++cbptr; // Match 'm'.

		if (!isxdigit(*cbptr))
		{
			printf("����\'m\'�����ֻ�ܸ�ʮ����������\n");
			return SHIT;
		}
		arg1 = parse_xnumber();
		if (arg1 > 0xFFFF)
		{
			printf("����\'m\'����ֻ����4��ʮ������λ��\n");
			return SHIT;
		}

		int hi = arg1 >> 8;
		int lo = arg1 & 0xFF;
		edit_buffer[hi] = lo;
		if (hi >= ebsize)
		{
			file_size += hi + 1 - ebsize;
			ebsize = hi + 1;
		}
		ebmodified = YES;

		show_edit_buffer();
		return OK;
	}

	if (*cbptr == 'o')
	{
		++cbptr;	// Match 'o'.

		write_back_edit_buffer(YES);
		printf("�ļ�����\"%s\"\n", cbptr);
		FILE * new_strm = fopen(cbptr, "r+b");
		if (!new_strm)
		{
			printf("�����ļ��򲻿���SHIT��������֪��ˣ����ĺ��~\n");
			return SHIT;
		}
		fclose(strm);
		strm = new_strm;
		if (check_file_size() == SHIT) return SHIT;

		ebo = 0;
		fill_edit_buffer();
		return OK;
	}

	if (*cbptr == 'd')
	{
		++cbptr; // Match 'd'.

		if (!isxdigit(*cbptr))
		{
			printf("����\'d\'��ֻ�ܸ�һ��ʮ����������\n");
			return SHIT;
		}
		arg1 = parse_xnumber();
		printf("ʮ��������Ϊ��%d��\n", arg1);
		return OK;
	}

	if (*cbptr == 'h')
	{
		++cbptr; // Match 'h'.

		if (*cbptr == '\'')
		{
			++cbptr;
			arg1 = *cbptr++;
			if (*cbptr++ != '\'')
			{
				printf("�����ַ������Ե����Ž�β��\n");
				return SHIT;
			}
		}
		else if (isdigit(*cbptr))
		{
			arg1 = parse_number();
		}
		else
		{
			printf("����\'h\'��ֻ�ܸ�һ��ʮ���������������������ַ���\n");
			return SHIT;
		}

		printf("ʮ��������Ϊ��0x%x��\n", arg1);
		return OK;
	}

	if (*cbptr == 'l')
	{
		if (strcmp(cbptr, "l") == 0)
		{
			++cbptr;	// Match 'l'.
			switch_edit_buffer(0);
		}
		else
		{
			++cbptr;	// Match 'l'.

			if (!isxdigit(*cbptr))
			{
				printf("����\'l\'��ֻ�ܸ�ʮ��������.\n");
				return SHIT;
			}
			arg1 = parse_xnumber();
			if (file_size > 0 && arg1 >= file_size ||
					file_size == 0 && arg1 > 0)
			{
				printf("����ƫ��0x%x�����ļ���С��0x%x �ֽڡ�\n", arg1, file_size);
				return SHIT;
			}
			switch_edit_buffer(arg1 & 0xFFFFFF00);
		}
		return OK;
	}

	if (*cbptr == 'f')
	{
		++cbptr;	// Match 'f'.

		if (*cbptr != '+')
		{
			fseek(strm, ebo, SEEK_SET);
		}
		else
		{
			++cbptr; // Match '+'.
		}

		uchar * p;
		if (*cbptr == '\"')
		{
			++cbptr; // Match '"'.

			// Make the other '"' zero so that string-functions can be used.
			p = cbptr;
			while (*p && *p != '\"')
				++p;
			if (*p == 0)
			{
				printf("�����ַ���������\"��β��\n");
				return SHIT;
			}
			*p = 0;
		}
		else if (isxdigit(*cbptr))
		{
			p = cbptr;
			char * q = cbptr;
			for (;;)
			{
				int d = get_hex(*q);
				if (d == -1) break;
				arg1 = d << 4;
				d = get_hex(*(q + 1));
				if (d == -1)
				{
					*p++ = arg1;
					break;
				}
				arg1 += d;
				*p++ = arg1;
				q += 2;
			}
			*p = 0;
		}
		else
		{
			printf("����\'f\'��ֻ�ܸ�ʮ����������˫�������������ַ�����\n");
			return SHIT;
		}

		printf("���ҵ���ʼƫ�ƣ�0x%08x��\n", ftell(strm));
		int offset = brute_force_find_string(p - cbptr);
		if (offset == -1)
		{
			printf("����ָ��������û���ҵ���\n");
			return SHIT;
		}
		printf("���ҵ���ƫ�ƣ�0x%08x��\n", offset);
		*cbptr = 0;
		switch_edit_buffer(offset & 0xFFFFFF00);
		return OK;
	}

	printf("���󣺸粻��ʶ�����\n");
	return SHIT;
}

void show_help()
{
	printf(">>>>>>>>>>>>>>>>>>>>>>>>>>> ���� <<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
	printf("��һ��֧��12�����\n");
	printf("1. �򿪺ͱ���:\n"
				 "(1). o<filename>���ڱ༭���д�<filename>�ļ���\n"
				 "(2). w���ѵ�ǰҳ���޸�д���ļ���\n");
	printf("2. ����ļ�:\n"
				 "(1). l[<hex>]������ƫ��<hex>���ڵ��Ǹ�ҳ��\n"
				 "     ���<hex>ʡ�ԣ�Ĭ��Ϊ0��\n"
				 "(2). n����ʾ��һҳ��\n"
				 "(3). nn����ʾ���һҳ��\n"
				 "(4). p����ʾǰһҳ��\n"
				 "(5). s����ʾ��ǰҳ��\n");
	printf("3. �޸�:\n"
				 "(1). m<��λhex><��λhex>����һ��<hex>ָ�����ڵ�ǰҳ�е�λ�ã�\n"
				 "     �ڶ���<hex>ָ�����µ����ݡ�\n");
	printf("4. ����:\n"
				 "(1). f[+]{<hex> | \"<str>\"}���ӵ�ǰҳ��ʼ��<hex>��\n"
				 "     �����\'+\'���ʹ��ϴ�λ�ÿ�ʼ������\n");
	printf("5. ʵ�ù���:\n"
				 "(1). d<hex>����<hex>ת����ʮ���ơ�\n"
				 "(2). h<dec>����<dec>ת����ʮ�����ơ�\n"
				 "     h\'<char>\'����<char>ת����ʮ�����ơ�\n");
	printf("6. �༭��:\n"
				 "(1). q���˳��༭����\n");
	printf("ע��������������Զ�����һ�������������ķϻ���\n");
}

int parse_number()
{
	int ret = 0;
	while (isdigit(*cbptr))
	{
		ret *= 10;
		ret += (*cbptr++) - '0';
	}

	return ret;
}

int get_hex(uchar ch)
{
	if (ch >= '0' && ch <= '9')
		return ch - '0';
	else if (ch >= 'A' && ch <= 'F')
		return ch - 'A' + 10;
	else if (ch >= 'a' && ch <= 'f')
		return ch - 'a' + 10;
	else
		return -1;
}

int parse_xnumber()
{
	int ret = 0;
	for (;; ++cbptr)
	{
		int d = get_hex(*cbptr);
		if (d == -1) break;
		ret *= 16;
		ret += d;
	}

	return ret;
}

int check_file_size()
{
	fseek(strm, 0, SEEK_END);
	file_size = ftell(strm);
	fseek(strm, 0, SEEK_SET);
	if (file_size < 0)
	{
		printf("�����ļ�̫�󣬸紦���ˡ�\n");
		return SHIT;
	}
	printf("�ļ���С��0x%x �ֽڡ�\n", file_size);
	return OK;
}

int brute_force_find_string(int size)
{
	if (size < 1) return -1;

	for (;;)
	{
		int offset = ftell(strm);
		int i;
		for (i = 0; i < size; ++i)
		{
			uchar ch = fgetc(strm);
			if (ch != cbptr[i]) break;
		}
		// Found.
		if (i == size)
			return offset;
		if (feof(strm))
			return -1;
		fseek(strm, offset + 1, SEEK_SET);
	}
}

//////////////////////////////////////////////////////////////////////////

void write_back_edit_buffer(int need_ask)
{
	if (ebmodified == YES)
	{
		if (need_ask == YES)
		{
			char ans[2];
			printf("��ǰҳ�ѱ��޸ģ��Ƿ���д�أ�[y/N]");
			scanf("%s", ans);
			if (ans[0] != 'y')
				return;
		}
		int old_offset = ftell(strm);
		fseek(strm, 0, ebo);
		fwrite(edit_buffer, 1, ebsize, strm);
		fflush(strm);
		fseek(strm, old_offset, SEEK_SET);
		ebmodified = NO;
	}
}

void switch_edit_buffer(int new_ebo)
{
	if (ebo != new_ebo)
	{
		write_back_edit_buffer(YES);
		ebo = new_ebo;
	}
	fill_edit_buffer();
	show_edit_buffer();
}

void show_edit_buffer()
{
	printf("��ǰҳƫ�ƣ�0x%x, �ļ���С��0x%x �ֽڡ�\n", ebo, file_size);
	int i, j;
	printf("B7-B1\\B0| ");
	for (j = 0; j < BYTES_EACH_LINE; ++j)
		printf("%2X ", j);
	printf("\n--------+------------------------------------------------\n");

	for (i = 0; i < EDIT_BUFFER_SIZE / BYTES_EACH_LINE; ++i)
	{
		int line_index = i * BYTES_EACH_LINE;
		int line_offset = ebo + line_index;
		printf("%06X %X| ", line_offset >> 8, (line_offset & 0xF0) >> 4);
		for (j = 0; j < BYTES_EACH_LINE; ++j)
			printf("%02X ", edit_buffer[line_index + j]);
		for (j = 0; j < BYTES_EACH_LINE; ++j)
		{
			uchar ch = edit_buffer[line_index + j];
			if (!isgraph(ch))
				printf(".");
			else
				printf("%c", ch);
		}
		printf("\n");
	}
}

void fill_edit_buffer()
{
	int old_offset = ftell(strm);
	fseek(strm, ebo, SEEK_SET);
	ebsize = fread(edit_buffer, 1, EDIT_BUFFER_SIZE, strm);
	fseek(strm, old_offset, SEEK_SET);
	int cnt = ebsize;
	while (cnt < EDIT_BUFFER_SIZE)
		edit_buffer[cnt++] = 0;
	ebmodified = NO;
}
