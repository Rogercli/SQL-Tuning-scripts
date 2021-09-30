use springboardopt;

SET @v1 = 1612521;
SET @v2 = 1145072;
SET @v3 = 1828467;
SET @v4 = 'MGT382';
SET @v5 = 'Amber Hill';
SET @v6 = 'MGT';
SET @v7 = 'EE';			  
SET @v8 = 'MAT';

-- 2. List the names of students with id in the range of v2 (id) to v3 (inclusive).
SELECT name FROM Student WHERE id BETWEEN @v2 AND @v3;
_________

EXPLAIN ANALYZE
SELECT name 
FROM Student 
WHERE id BETWEEN 1145072 AND 1828467;

--OUTPUT--
-> Filter: (Student.id between 1145072 and 1828467)  (cost=41.00 rows=278) (actual time=0.017..0.321 rows=278 loops=1)
    -> Table scan on Student  (cost=41.00 rows=400) (actual time=0.016..0.274 rows=400 loops=1)--

_________

EXPLAIN 
SELECT name 
FROM Student 
WHERE id BETWEEN '1145072' AND '1828467';


--OUTPUT--
# id, select_type, table, partitions, type, possible_keys, key, key_len, ref, rows, filtered, Extra
'1', 'SIMPLE', 'Student', NULL, 'ALL', 'Student_id', NULL, NULL, NULL, '400', '69.50', 'Using where'


_________

-- BOTTLENECK: still does a full table scan rather than index scan. This is because even though the index based on id is created, it is not used as a key since we are selecting name.--
_________

--SOLUTION: Need to create an index with id and name together--
_________

CREATE INDEX id_name_idx ON Student(id,name);


EXPLAIN ANALYZE
SELECT name 
FROM Student 
WHERE id BETWEEN '1145072' AND '1828467';

--OUTPUT--
-> Filter: (Student.id between '1145072' and '1828467')  (cost=64.52 rows=278) (actual time=0.016..0.149 rows=278 loops=1)
    -> Index range scan on Student using id_name_idx  (cost=64.52 rows=278) (actual time=0.015..0.111 rows=278 loops=1)


--OUTCOME: although the cost is higher, the number of rows searched and execution time decreases--
