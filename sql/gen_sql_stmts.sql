-- ��ʾscott�û������б�
-- dba_all_tables��ʾ����object tables��relational tables
declare
	cursor cur is
		select table_name
		from dba_all_tables
		where owner = 'SCOTT';
	vtable varchar2(30);
	vsql varchar2(30);
begin
	for rec in cur loop
		vtable := rec.table_name;
		vsql := 'select * from scott.' || vtable;
		execute immediate vsql;
		--dbms_output.put_line(vsql);
	end loop;
end;