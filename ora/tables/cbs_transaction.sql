declare
    object_not_found exception;
    pragma exception_init(object_not_found, -00942);
begin
    execute immediate ('drop table cbs_transaction');
exception
    when object_not_found then
        null;
    when others then
        dbms_output.put_line('Error '||sqlerrm);
end;
/
create table cbs_transaction (trn_no            varchar2(21)    not null,
                              value_day         date            not null,
                              trn_content       varchar2(2000),
                              cur_amt           number,
                              account_corr_uk   number          not null,
                              account_credit_uk number          not null,
                              account_debit_uk  number          not null,
                              client_uk         number          not null)
partition by range (value_day)
(  
  partition p201601 values less than (to_date(' 2016-02-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')),
  partition p201602 values less than (to_date(' 2016-03-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')),
  partition pmax values less than (maxvalue));
/
comment on table cbs_transaction is 'Transactions';
/
comment on column cbs_transaction.trn_no            is 'Transaction unique code';
comment on column cbs_transaction.value_day         is 'Date of operation';
comment on column cbs_transaction.trn_content       is 'Content of transaction';
comment on column cbs_transaction.cur_amt           is 'Amount in transaction currency';
comment on column cbs_transaction.account_corr_uk   is 'Correspondent account';
comment on column cbs_transaction.account_credit_uk is 'Credit account';
comment on column cbs_transaction.account_debit_uk  is 'Debit account';
comment on column cbs_transaction.client_uk         is 'Client';
/
create unique index pk_cbs_transaction on cbs_transaction
(
  value_day, 
  trn_no);