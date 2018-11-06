declare
    object_not_found exception;
    pragma exception_init(object_not_found, -00942);
begin
    execute immediate ('drop table cbs_balances');
exception
    when object_not_found then
        null;
    when others then
        dbms_output.put_line('Error '||sqlerrm);
end;
/
create table cbs_balances (account_uk           number not null,
                           value_day            date   not null,
                           debit_turn_amt_cur   number,
                           credit_turn_amt_cur  number,
                           balance_amt_cur      number)
partition by range (value_day)
(  
  partition p201601 values less than (to_date(' 2016-02-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')),
  partition p201602 values less than (to_date(' 2016-03-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')),
  partition pmax values less than (maxvalue));
/
comment on table cbs_balances is 'Account balances';
/
comment on column cbs_balances.account_uk          is 'Account';
comment on column cbs_balances.value_day           is 'Balance date';
comment on column cbs_balances.debit_turn_amt_cur  is 'Debit turns in account currency';
comment on column cbs_balances.credit_turn_amt_cur is 'Credit turns in account currency';
comment on column cbs_balances.balance_amt_cur     is 'Account balance in account currency';
/
create unique index pk_cbs_balances on cbs_balances
(
  account_uk, 
  value_day);