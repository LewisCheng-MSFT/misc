-- emp���е�ÿ����¼����50%�ĸ��ʱ�ѡΪ������
select * from scott.emp sample(50);

-- ��������ȡ��ǰ7����¼��
select *
from (select *
	  from scott.emp
	  order by dbms_random.value(0, 1000))
where rownum < 8;