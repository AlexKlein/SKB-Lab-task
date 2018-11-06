declare
    object_not_found exception;
    pragma exception_init(object_not_found, -00942);
begin
    execute immediate ('drop table cbs_client');
exception
    when object_not_found then
        null;
    when others then
        dbms_output.put_line('Error '||sqlerrm);
end;
/
create table cbs_client (uk                    number        not null,
                         first_name            varchar2(255),
                         middle_name           varchar2(255),
						 last_name             varchar2(255),
                         short_name            varchar2(100));
/
comment on table cbs_client is 'Clients dimension';
/
comment on column cbs_client.uk              is 'Unique key';
comment on column cbs_client.first_name      is 'First name';
comment on column cbs_client.middle_name     is 'Middle name';
comment on column cbs_client.last_name       is 'Last name';
comment on column cbs_client.short_name      is 'Short name';
/
create unique index pk_cbs_client on cbs_client
(uk);
/
alter table cbs_client add (constraint pk_cbs_client primary key (uk)
using index pk_cbs_client);
/