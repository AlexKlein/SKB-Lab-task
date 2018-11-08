with 
    accList as (
    select /*+ materialize */ 
           distinct 
           account_debit_uk
    from   cbs_transaction trn
    where  trn.value_day between :pStartDate and
                                 :pEndDate),
    accAmtJF as (
    select /*+ materialize */ 
           dbt.account_debit_uk  as account_uk,
           (-1)*sum(dbt.cur_amt) as cur_amt
    from   cbs_transaction dbt
    inner join (select account_debit_uk
                from   accList) trnDbt
            on dbt.account_debit_uk = trnDbt.account_debit_uk
    where  dbt.value_day between :pStartDate and
                                 :pEndDate
    group by dbt.account_debit_uk
    union all
    select crd.account_credit_uk as account_uk,
           sum(crd.cur_amt)      as cur_amt
    from   cbs_transaction crd
    inner join (select account_debit_uk
                from   accList) trnCrd
            on crd.account_credit_uk = trnCrd.account_debit_uk
    where  crd.value_day between :pStartDate and
                                 :pEndDate
    group by crd.account_credit_uk),
    accAmtFeb as (
    select /*+ materialize */ 
           dbt.account_debit_uk  as account_uk,
           (-1)*sum(dbt.cur_amt) as cur_amt
    from   cbs_transaction dbt
    inner join (select account_debit_uk
                from   accList) trnDbt
            on dbt.account_debit_uk = trnDbt.account_debit_uk
    where  dbt.value_day between add_months(:pStartDate, 1) and
                                            :pEndDate
    group by dbt.account_debit_uk
    union all
    select crd.account_credit_uk as account_uk,
           sum(crd.cur_amt)      as cur_amt
    from   cbs_transaction crd
    inner join (select account_debit_uk
                from   accList) trnCrd
            on crd.account_credit_uk = trnCrd.account_debit_uk
    where  crd.value_day between add_months(:pStartDate, 1) and
                                            :pEndDate
    group by crd.account_credit_uk)
select f.account_uk,
       cur_amt_jf,
       f.cur_amt
from  (select account_uk,
              sum(cur_amt) as cur_amt_jf
       from  accAmtJF 
       group by account_uk) jf
left outer join accAmtFeb f
             on jf.account_uk = f.account_uk;
/