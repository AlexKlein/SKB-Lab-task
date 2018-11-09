create or replace package meta_calc_cash_flow_pkg
/******************************* SKB-Lab HISTORY *******************************************\
Date        Author           ID       Description
----------  ---------------  -------- -------------------------------------------------------
2018-11-07  Klein A.M.      [000000]  Package creation.
\******************************* SKB-Lab HISTORY *******************************************/
is
    -- global variables
    -- record of balances
    type recBal is record (account_number       varchar(20),
                           client_name          varchar(2000),
                           value_day            date,
                           debit_turn_amt_cur   number,
                           credit_turn_amt_cur  number,
                           balance_amt_cur      number);
    -- collection of balances
    type tabBal is table of recBal;

    -- procedures
    procedure my_exception;
    procedure calc_balances  (pDate  date,
                              pAcc   varchar2);
    procedure add_cash_flow  (pDate  date,
                              pAccDt varchar2,
                              pAccCt varchar2,
                              pAccC  varchar2,
                              pSum   number,
                              pType  varchar2 default 'P');
    procedure edit_cash_flow (pDate  date,
                              pTrnNo varchar2,
                              pSum   number);
    procedure del_cash_flow  (pDate  date,
                              pTrnNo varchar2);
    -- functions
    function get_balances    (pDate  date,
                              pAcc   varchar2) return tabBal pipelined;

end meta_calc_cash_flow_pkg;
/
create or replace package body meta_calc_cash_flow_pkg
/******************************* SKB-Lab HISTORY *******************************************\
Date        Author           ID       Description
----------  ---------------  -------- -------------------------------------------------------
2018-11-07  Klein A.M.      [000000]  Package creation.
\******************************* SKB-Lab HISTORY *******************************************/
is
    -- package cursor for balancec recalculating
    cursor recalcBal (pDate  date,
                      ptrnNo varchar2)
        is
    select account_credit_uk,
           account_debit_uk 
    from   cbs_transaction
    where  value_day = pDate and
           trn_no    = ptrnNo;

    -- package variables
    rAccBal recalcBal%rowtype;
    
-- exception handling procedure
    procedure my_exception
        is
    begin
        dbms_output.put_line('Error '  ||chr(10)||
        dbms_utility.format_error_stack||
        dbms_utility.format_error_backtrace());
        commit;

    end my_exception;

-- calculate account balances procedure
    procedure calc_balances  (pDate  date,
                              pAcc   varchar2)
        is
    begin
        -- deleting balance line by account and date
        delete from cbs_balances bal
        where  value_day = pDate and
               exists (select 1
                       from   cbs_account acct
                       where  acct.account_number = regexp_replace(replace(pAcc, ' ',''), '[A-z]') and
                              acct.uk = bal.account_uk);
               
        -- transactions aggregation and balance table filling 
        insert into cbs_balances (account_uk,
                                  value_day,
                                  debit_turn_amt_cur,
                                  credit_turn_amt_cur,
                                  balance_amt_cur)
        with dbtCalc as (
            select dbtCalc.account_debit_uk     as account_uk,
                   dbtCalc.value_day            as value_day,
                   nvl(sum(dbtCalc.cur_amt), 0) as turn_amt_cur
            from   cbs_transaction dbtCalc
            inner join cbs_account acct
                    on acct.uk = dbtCalc.account_debit_uk and
                       acct.account_number = regexp_replace(replace(pAcc, ' ',''), '[A-z]')
            where  dbtCalc.value_day = pDate
            group by dbtCalc.account_debit_uk,
                     dbtCalc.value_day),
            crdCalc as (
            select crdCalc.account_credit_uk    as account_uk,
                   crdCalc.value_day            as value_day,
                   nvl(sum(crdCalc.cur_amt), 0) as turn_amt_cur
            from   cbs_transaction crdCalc
            inner join cbs_account acct
                    on acct.uk = crdCalc.account_debit_uk and
                       acct.account_number = regexp_replace(replace(pAcc, ' ',''), '[A-z]') 
            where  crdCalc.value_day = pDate
            group by crdCalc.account_credit_uk,
                     crdCalc.value_day),
            prevDay as (
            select nvl(prevDay.balance_amt_cur, 0) as balance_amt_cur
            from   dual
            left outer join (select balance_amt_cur,
                                    value_day
                             from  (select row_number() over 
                                          (partition by bal.account_uk 
                                           order by bal.value_day desc) as rn,
                                           bal.balance_amt_cur,
                                           bal.value_day
                                    from   cbs_balances bal
                                    inner join cbs_account acct
                                            on bal.account_uk  = acct.uk and
                                               acct.account_number = regexp_replace(replace(pAcc, ' ',''), '[A-z]'))
                             where  rn = 1) prevDay
                         on 1=1)
        select coalesce(dbtCalc.account_uk,
                        crdCalc.account_uk,
                        acct.uk,
                        0)                 as account_uk,
               coalesce(dbtCalc.value_day,
                        crdCalc.value_day,
                        pDate)             as value_day,
               nvl(dbtCalc.turn_amt_cur,0) as debit_turn_amt_cur,
               nvl(crdCalc.turn_amt_cur,0) as credit_turn_amt_cur,
               nvl(prevDay.balance_amt_cur -
                   dbtCalc.turn_amt_cur+
                   crdCalc.turn_amt_cur,0) as balance_amt_cur
        from   dual
        left outer join cbs_account acct
                     on acct.account_number = regexp_replace(replace(pAcc, ' ',''), '[A-z]') 
        left outer join dbtCalc
                     on 1=1
        left outer join crdCalc
                     on 1=1
        left outer join prevDay
                     on 1=1;
        
        commit;

    exception
        when others then
            my_exception;
            
    end calc_balances;

-- procedure for adding cash flow
    procedure add_cash_flow  (pDate  date,
                              pAccDt varchar2,
                              pAccCt varchar2,
                              pAccC  varchar2,
                              pSum   number,
                              pType  varchar2 default 'P')
    is
        pragma autonomous_transaction;
        vAcc   varchar2(20);   -- checking client's account
        vTrnNo varchar2(256);  -- generated transaction number
    begin
        
        select 'ADJ_'||to_char(s_transaction.nextval) as trn_no 
        into   vTrnNo
        from   dual;
        
        insert into cbs_transaction (trn_no,
                                     value_day,
                                     trn_content,
                                     cur_amt,
                                     account_corr_uk,
                                     account_credit_uk,
                                     account_debit_uk,
                                     client_uk)
        select vTrnNo                         as trn_no,
               pDate                          as value_day,
               'Adjustment of balance amount' as trn_content,
               pSum                           as cur_amt,
               accDt.uk                       as account_corr_uk,
               accCt.uk                       as account_credit_uk,
               accC.uk                        as account_debit_uk,
               case
                   when pType = 'P' then
                       accCt.client_uk
                   when pType = 'L' then
                       accDt.client_uk
               end                            as client_uk
        from   dual
        left outer join cbs_account accDt
                     on accDt.account_number = regexp_replace(replace(pAccDt, ' ',''), '[A-z]')
        left outer join cbs_account accCt
                     on accCt.account_number = regexp_replace(replace(pAccCt, ' ',''), '[A-z]')
        left outer join cbs_account accC
                     on accC.account_number  = regexp_replace(replace(pAccC, ' ',''), '[A-z]');
        
        commit;
        
        -- recalculating balances for both accounts
        for rowBal in recalcBal(pDate,
                                vTrnNo) loop
                                 
            meta_calc_cash_flow_pkg.calc_balances (pDate, rowBal.account_credit_uk);
            meta_calc_cash_flow_pkg.calc_balances (pDate, rowBal.account_debit_uk);
        
        end loop;
        
    exception
        when others then
            my_exception;
            
    end add_cash_flow;

-- procedure for editing cash flow
    procedure edit_cash_flow (pDate  date,
                              pTrnNo varchar2,
                              pSum   number)
        is
    begin
        update cbs_transaction
        set    cur_amt   = pSum
        where  value_day = pDate and
               trn_no    = ptrnNo;
               
        commit;
        
        -- recalculating balances for both accounts
        open recalcBal(pDate,
                       pTrnNo);
        
        loop
            exit when recalcBal%notfound;
            
            fetch recalcBal into rAccBal;    
        
            meta_calc_cash_flow_pkg.calc_balances (pDate, rAccBal.account_credit_uk);
            meta_calc_cash_flow_pkg.calc_balances (pDate, rAccBal.account_debit_uk);
            
        end loop;
        
        close recalcBal;
        
    exception
        when others then
            my_exception;
            
    end edit_cash_flow;

-- procedure for deleting cash flow
    procedure del_cash_flow  (pDate  date,
                              pTrnNo varchar2)
        is
    begin
        delete cbs_transaction
        where  value_day = pDate and
               trn_no    = ptrnNo;
               
        commit;
        
        -- recalculating balances for both accounts
        for rowBal in recalcBal(pDate,
                                pTrnNo) loop
                                 
            meta_calc_cash_flow_pkg.calc_balances (pDate, rowBal.account_credit_uk);
            meta_calc_cash_flow_pkg.calc_balances (pDate, rowBal.account_debit_uk);
        
        end loop;
        
    exception
        when others then
            my_exception;
            
    end del_cash_flow;

-- date account balance function 
    function get_balances    (pDate  date,
                              pAcc   varchar2) return tabBal pipelined
    is
        rRec recBal;  -- line with account balance
    begin
        
        for rBal in (select accnt.account_number as account_number,
                            nvl(
                            clnt.last_name ||' '||
                            clnt.first_name||' '||
                            clnt.middle_name,
                            clnt.short_name)     as client_name,
                            value_day,
                            debit_turn_amt_cur,
                            credit_turn_amt_cur,
                            balance_amt_cur
                     from   cbs_balances bal
                     inner join cbs_account accnt
                             on accnt.uk = bal.account_uk and
                                accnt.account_number = regexp_replace(replace(pAcc, ' ',''), '[A-z]')
                     left outer join cbs_client  clnt
                                  on clnt.uk = accnt.client_uk
                     where  bal.value_day = pDate) loop
            -- cleaning data in the line
            rRec := null;
            -- recording data from current line 
            rRec.account_number       := rBal.account_number;
            rRec.client_name          := rBal.client_name;
            rRec.value_day            := rBal.value_day;
            rRec.debit_turn_amt_cur   := rBal.debit_turn_amt_cur;
            rRec.credit_turn_amt_cur  := rBal.credit_turn_amt_cur;
            rRec.balance_amt_cur      := rBal.balance_amt_cur;
            
            -- flowing data in pipe
            pipe row (rRec);
        end loop;
        
    exception
        when others then
            my_exception;
            
    end get_balances;
   
end meta_calc_cash_flow_pkg;
/