-- ����1 3 5 7 9
select 2 * rownum - 1 from dual connect by rownum < 10;

-- ���ɵ���������1->2->...->9
select level, rownum from dual connect by rownum < 10;

-- rownumԭ��ÿ�ڽ���������һ����¼���Ͱ�rownum+1��
-- ����rownumֻ����С�ڱȽϣ����ܴ��ڻ���ڣ���Ϊ������
-- �ڲ�����λ��ĳһ����¼֮ǰ�����м�¼ʱ�������ü�¼��
-- ��rownum������ֱ����Ծ��ĳ��������ֻ���𲽵�������ֵ��

-- start with���ʡ�ԣ�Ĭ����ÿ����¼Ϊ������ɭ�֡�
-- ִ�мƻ��У�connect by without filtering�������������