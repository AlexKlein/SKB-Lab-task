select *
from   table(meta_calc_cash_flow_pkg.get_balances(date'2016-01-01',
                                                  '40817810900005789321'));
/