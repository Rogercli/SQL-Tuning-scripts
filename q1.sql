
-- 1. List the name of the student with id equal to v1 (id).
SELECT name FROM Student WHERE id = 1612521;

_________

EXPLAIN ANALYZE
SELECT name 
FROM Student 
WHERE id = 1612521;

--OUTPUT--
-> Filter: (Student.id = 1612521)  (cost=41.00 rows=40) (actual time=0.080..0.304 rows=1 loops=1)
    -> Table scan on Student  (cost=41.00 rows=400) (actual time=0.021..0.273 rows=400 loops=1)

_________

-- BOTTLENECK:because the query performed a full table scan. This was identified by adding "EXPLAIN ANALYZE" into the query.--
_________

--SOLUTION:To resolve this, we can create an index based on the student id--
_________

CREATE INDEX Student_id ON Student(id);


EXPLAIN ANALYZE
SELECT name 
FROM Student 
WHERE id = 1612521;

--OUTPUT--
-> Index lookup on Student using Student_id (id=1612521)  (cost=0.35 rows=1) (actual time=0.025..0.028 rows=1 loops=1)

_________

-- OUTCOME:by doing this, we can see that the planning and execution time decreased, and the number of rows it had to scan for went from 400 rows to 1 row--

