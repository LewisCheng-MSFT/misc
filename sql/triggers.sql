-- �﷨
create [or replace] trigger <trigger_name>
{ before | after | instead of } <trigger_event>
on <table_name>
[for each row [when <trigger_condition>]]
begin
	<trigger_body>
end <trigger_name>;

-- trigger_event:
-- ����������ڱ��ϣ�delete, insert, update����or����
-- ��������������ݿ⣺create, alter, drop, truncate, ��or����

-- table_name:
-- �����Ǿ���ı�����database

-- trigger_condition:
-- ֱ����new��old����Ҫ��ǰ���ð��

-- trigger_body:
-- ������:new��:old�ֱ������º;ɵļ�¼

select * from user_triggers where trigger_name='XXX';

alter trigger <trigger_name> { disable | enable };