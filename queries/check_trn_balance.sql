select nvl(trnDbt.account_debit_uk,  0) as debit_uk,
       nvl(trnDbt.account_credit_uk, 0) as credit_uk,
       nvl(trnDbt.cur_amt, 0)           as trn_cur_amt,
       nvl(calcTrnDbt.cur_amt, 0)       as sum_cur_amt
from   cbs_balances bal
left outer join cbs_transaction trnDbt
             on bal.account_uk = trnDbt.account_debit_uk and
                bal.value_day  = trnDbt.value_day
left outer join (select trn.account_debit_uk,
                        trn.value_day,
                        sum(trn.cur_amt) as cur_amt
                 from   cbs_transaction trn
                 where  trn.value_day between :pStartDate and
                                              :pEndDate
                 group by trn.account_debit_uk,
                        trn.value_day) calcTrnDbt 
             on bal.account_uk = calcTrnDbt.account_debit_uk and
                bal.value_day  = calcTrnDbt.value_day
where  bal.value_day between :pStartDate and
                             :pEndDate
union all
select nvl(trnCrd.account_debit_uk,  0) as debit_uk,
       nvl(trnCrd.account_credit_uk, 0) as credit_uk,
       nvl(trnCrd.cur_amt, 0)           as trn_cur_amt,
       nvl(calcTrnDbt.cur_amt, 0)       as sum_cur_amt
from   cbs_balances bal
left outer join cbs_transaction trnCrd
             on bal.account_uk = trnCrd.account_credit_uk and
                bal.value_day  = trnCrd.value_day
left outer join (select trn.account_debit_uk,
                        trn.value_day,
                        sum(trn.cur_amt) as cur_amt
                 from   cbs_transaction trn
                 where  trn.value_day between :pStartDate and
                                              :pEndDate
                 group by trn.account_debit_uk,
                        trn.value_day) calcTrnDbt 
             on bal.account_uk = calcTrnDbt.account_debit_uk and
                bal.value_day  = calcTrnDbt.value_day
where  bal.value_day between :pStartDate and
                             :pEndDate;
/