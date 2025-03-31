-- task-1
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1, (10^7)::int) x;



-- task-2
/*
Initial space usage before DELETE:

Total Size: 575 MB

Table Size: 575 MB

Index Size: 0 bytes

TOAST Size: 8 KB
 */
SELECT *,
       pg_size_pretty(total_bytes) AS total,
       pg_size_pretty(index_bytes) AS index,
       pg_size_pretty(toast_bytes) AS toast,
       pg_size_pretty(table_bytes) AS table
FROM (
    SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
    FROM (
        SELECT c.oid, nspname AS table_schema,
               relname AS table_name,
               c.reltuples AS row_estimate,
               pg_total_relation_size(c.oid) AS total_bytes,
               pg_indexes_size(c.oid) AS index_bytes,
               pg_total_relation_size(reltoastrelid) AS toast_bytes
        FROM pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
    ) a
) a
WHERE table_name LIKE '%table_to_delete%';


-- task-3
DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all rows


-- a) Execution Time: 22 seconds

-- b) Space Usage After DELETE: Still 575 MB (no space freed yet)
-- c)
VACUUM FULL VERBOSE table_to_delete;

-- d Table Size Reduced: 393 MB

TOAST Size Remained Same: 8 KB

Conclusion: VACUUM FULL successfully reclaimed space.

-- part -4 
TRUNCATE table_to_delete;

-- a) Execution Time: 0.079 seconds (much faster than DELETE)

-- b) tuncate method is faster than delete;

-- c) Space Usage After TRUNCATE: 0 bytes (fully freed space).