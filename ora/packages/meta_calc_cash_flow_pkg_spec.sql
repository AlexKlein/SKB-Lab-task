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