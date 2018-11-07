declare
    object_not_found exception;
    pragma exception_init(object_not_found, -00942);
begin
    execute immediate ('drop table cbs_account');
exception
    when object_not_found then
        null;
    when others then
        dbms_output.put_line('Error '||sqlerrm);
end;
/
create table cbs_account (uk                 number        not null,
                          account_number     varchar2(20)  not null,
                          name               varchar2(255) not null,
                          start_date         date          not null,
                          end_date           date          not null,
                          client_uk          number        not null);
/
comment on table cbs_account is 'Accounts dimension';
/
comment on column cbs_account.uk              is 'Unique key';
comment on column cbs_account.account_number  is 'Account number';
comment on column cbs_account.name            is 'Name';
comment on column cbs_account.start_date      is 'Account opening date';
comment on column cbs_account.end_date        is 'Account closing date';
comment on column cbs_account.client_uk       is 'Account owner';
/
create unique index pk_cbs_account on cbs_account
(uk);
/
alter table cbs_account add (constraint pk_cbs_account primary key (uk)
using index pk_cbs_account);
/
create index ak_cbs_account_account on cbs_account
(account_number);
/
create index ak_cbs_account_client on cbs_account
(client_uk);
/