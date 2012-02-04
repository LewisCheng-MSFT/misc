#include <stdio.h>
#include <time.h>

#define N 16 // �ʺ������

int scnt = 0; // ������
int pos[N]; // ÿ�лʺ��λ�á�
int col[N]; // ��ռ�����顣
int pdiag[2 * N]; // ���Խ���ռ�����顣
int cdiag[2 * N]; // ���Խ���ռ�����顣

void print_solution()
{
	int i, j;
	for (i = 0; i < N; ++i)
	{
		for (j = 0; j < N; ++j)
		{
			if (j == pos[i])
			{
				putchar('*');
			}
			else
			{
				putchar('_');
			}
			putchar(' ');
		}
		putchar('\n');
	}
	puts("\n");
}

void queen(int i)
{
	if (i == N)
	{ // �ҵ�һ���⡣
		// print_solution();
		++scnt;
	}
	else
	{ // �����ڵ�i�зŻʺ�
		int j;
		for (j = 0; j < N; ++j)
		{ // ��ÿһ�г��Է��ûʺ����ҵ����н⡣
			if (!col[j] && !pdiag[i + j] && !cdiag[i - j + N - 1])
			{ // ��(i, j)���ûʺ�û�г�ͻ��
				// ��(i, j)���ûʺ�
				pos[i] = j;

				// ����ռ���j�к͸ûʺ����ڵ������Խ��ߡ�
				col[j] = pdiag[i + j] = cdiag[i - j + N - 1] = 1;

				// �����ڵ�i + 1�зŻʺ�
				queen(i + 1);

				// �ͷŶԵ�j�к͸ûʺ����ڵ������Խ��ߵ�ռ�졣
				col[j] = pdiag[i + j] = cdiag[i - j + N - 1] = 0;
			}
		}
	}
}

int main()
{
	clock_t st = clock();
	queen(0);
	clock_t en = clock();
	printf("һ��%d���⣬����ʱ�䣺%.3lf�롣\n", scnt, (en - st) / 1000.0);
	return 0;
}