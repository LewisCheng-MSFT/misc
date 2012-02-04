// Console.cpp : �������̨Ӧ�ó������ڵ㡣
//

#include "stdafx.h"
#include <Windows.h>
#include <dwmapi.h>

void DrawString(int x, int y, LPCWSTR str)
{
	COORD pos = { x, y };
	SetConsoleCursorPosition(GetStdHandle(STD_OUTPUT_HANDLE), pos);
	fputws(str, stdout);
}

int _tmain(int argc, _TCHAR* argv[])
{
	LPCWSTR title = L"Hello Console Window!";
	// ���ñ���
	SetConsoleTitle(title);

	// ����������
	system("mode con cols=80 lines=40");

	// ���ұ����ھ�������ô�����ʽ
	HWND hwnd = FindWindow(L"ConsoleWindowClass", title);
	SetWindowLong(hwnd, GWL_STYLE, WS_CAPTION | WS_VISIBLE | WS_SYSMENU);
		
	// ��������Ч��
	MARGINS m = { -1 };
	DwmExtendFrameIntoClientArea(hwnd, &m);

	RECT rect;
	GetWindowRect(hwnd, &rect);
	// ������Ļ�������ö�
	rect.left = (GetSystemMetrics(SM_CXSCREEN) - rect.right + rect.left) / 2;
	rect.top = (GetSystemMetrics(SM_CYSCREEN) - rect.bottom + rect.top) / 2;
	SetWindowPos(hwnd, HWND_TOPMOST, rect.left, rect.top, rect.right, rect.bottom, SWP_SHOWWINDOW);

	DrawString(5, 5, L"Hahahaaha");
	return 0;
}

