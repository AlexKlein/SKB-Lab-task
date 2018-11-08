select account_uk,
       sum(cur_amt) as cur_amt
from  (select dbt.account_debit_uk  as account_uk,
              (-1)*sum(dbt.cur_amt) as cur_amt
       from   cbs_transaction dbt
       inner join (select distinct 
                          account_debit_uk
                   from   cbs_transaction trn
                   where  trn.value_day between :pStartDate and
                                                :pEndDate) trnDbt
               on dbt.account_debit_uk = trnDbt.account_debit_uk
       where  dbt.value_day between :pStartDate and
                                    :pEndDate
       group by dbt.account_debit_uk
       union all
       select crd.account_credit_uk as account_uk,
              sum(crd.cur_amt)      as cur_amt
       from   cbs_transaction crd
       inner join (select distinct 
                          account_debit_uk
                   from   cbs_transaction trn
                   where  trn.value_day between :pStartDate and
                                                :pEndDate) trnCrd
               on crd.account_credit_uk = trnCrd.account_debit_uk
       where  crd.value_day between :pStartDate and
                                    :pEndDate
       group by crd.account_credit_uk)
group by account_uk;
-- having sum(cur_amt) != 0 -- this statement is for filtering inactive clients
/