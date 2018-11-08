select distinct
       owner,
       name
from   sys.all_source 
where  lower(type) = 'package' and
       regexp_like(lower(text),'((procedure){1}( )+(procedure_for_exec123){1})');
/