use springboardopt;

SET @v1 = 1612521;
SET @v2 = 1145072;
SET @v3 = 1828467;
SET @v4 = 'MGT382';
SET @v5 = 'Amber Hill';
SET @v6 = 'MGT';
SET @v7 = 'EE';			  
SET @v8 = 'MAT';


-- 6. List the names of students who have taken all courses offered by department v8 (deptId).
SELECT name FROM Student,
	(SELECT studId
	FROM Transcript
		WHERE crsCode IN
		(SELECT crsCode FROM Course WHERE deptId = 'MAT' AND crsCode IN (SELECT crsCode FROM Teaching))
		GROUP BY studId
		HAVING COUNT(*) = 
			(SELECT COUNT(*) FROM Course WHERE deptId = 'MAT' AND crsCode IN (SELECT crsCode FROM Teaching))) as alias
WHERE id = alias.studId;




--OUTPUT--
-> Nested loop inner join  (cost=1041.00 rows=0) (actual time=0.952..0.952 rows=0 loops=1)
    -> Filter: (Student.id is not null)  (cost=41.00 rows=400) (actual time=0.023..0.262 rows=400 loops=1)
        -> Table scan on Student  (cost=41.00 rows=400) (actual time=0.022..0.233 rows=400 loops=1)
    -> Index lookup on alias using <auto_key0> (studId=Student.id)  (actual time=0.000..0.000 rows=0 loops=400)
        -> Materialize  (cost=0.00..0.00 rows=0) (actual time=0.632..0.632 rows=0 loops=1)
            -> Filter: (count(0) = (select #5))  (actual time=0.514..0.514 rows=0 loops=1)
                -> Table scan on <temporary>  (actual time=0.001..0.002 rows=19 loops=1)
                    -> Aggregate using temporary table  (actual time=0.310..0.312 rows=19 loops=1)
                        -> Nested loop inner join  (cost=1020.25 rows=10000) (actual time=0.176..0.299 rows=19 loops=1)
                            -> Filter: (Transcript.crsCode is not null)  (cost=10.25 rows=100) (actual time=0.004..0.066 rows=100 loops=1)
                                -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.004..0.059 rows=100 loops=1)
                            -> Single-row index lookup on <subquery3> using <auto_distinct_key> (crsCode=Transcript.crsCode)  (actual time=0.000..0.000 rows=0 loops=100)
                                -> Materialize with deduplication  (cost=120.52..120.52 rows=100) (actual time=0.218..0.220 rows=19 loops=1)
                                    -> Filter: (Course.crsCode is not null)  (cost=110.52 rows=100) (actual time=0.087..0.157 rows=19 loops=1)
                                        -> Filter: (Teaching.crsCode = Course.crsCode)  (cost=110.52 rows=100) (actual time=0.087..0.155 rows=19 loops=1)
                                            -> Inner hash join (<hash>(Teaching.crsCode)=<hash>(Course.crsCode))  (cost=110.52 rows=100) (actual time=0.087..0.151 rows=19 loops=1)
                                                -> Table scan on Teaching  (cost=0.13 rows=100) (actual time=0.003..0.049 rows=100 loops=1)
                                                -> Hash
                                                    -> Filter: (Course.deptId = 'MAT')  (cost=10.25 rows=10) (actual time=0.008..0.068 rows=19 loops=1)
                                                        -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.003..0.053 rows=100 loops=1)
                -> Select #5 (subquery in condition; run only once)
                    -> Aggregate: count(0)  (cost=211.25 rows=1000) (actual time=0.195..0.195 rows=1 loops=1)
                        -> Nested loop inner join  (cost=111.25 rows=1000) (actual time=0.112..0.192 rows=19 loops=1)
                            -> Filter: ((Course.deptId = 'MAT') and (Course.crsCode is not null))  (cost=10.25 rows=10) (actual time=0.004..0.069 rows=19 loops=1)
                                -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.002..0.053 rows=100 loops=1)
                            -> Single-row index lookup on <subquery6> using <auto_distinct_key> (crsCode=Course.crsCode)  (actual time=0.000..0.000 rows=1 loops=19)
                                -> Materialize with deduplication  (cost=20.25..20.25 rows=100) (actual time=0.118..0.120 rows=97 loops=1)
                                    -> Filter: (Teaching.crsCode is not null)  (cost=10.25 rows=100) (actual time=0.002..0.056 rows=100 loops=1)
                                        -> Table scan on Teaching  (cost=10.25 rows=100) (actual time=0.002..0.048 rows=100 loops=1)



_________

-- BOTTLENECK: the inclusion of many subqueries creates multiple nested inner joins and table scans which slows down query execution.--
_________

--SOLUTION: to minimize the # of joins, i only joined two tables (student and transcript), opting to filter by using "crsCode LIKE" which exist in the transcript table rather than filtering with deptId which exists in the Course table.In addition, i added an index on the student table based on ID.-
_________


CREATE INDEX stud_idx ON Student(id);

EXPLAIN ANALYZE
select name, crsCode
from Student
join Transcript
on id=studId
where crsCode like 'MAT%';



--OUTPUT--
-> Nested loop inner join  (cost=14.14 rows=11) (actual time=0.050..0.198 rows=19 loops=1)
    -> Filter: ((Transcript.crsCode like 'MAT%') and (Transcript.studId is not null))  (cost=10.25 rows=11) (actual time=0.030..0.116 rows=19 loops=1)
        -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.022..0.092 rows=100 loops=1)
    -> Index lookup on Student using stud_idx (id=Transcript.studId)  (cost=0.26 rows=1) (actual time=0.003..0.004 rows=1 loops=19)


       
--OUTCOME: the cost and execution time were much faster due to less joins, and the addition of an index on student IDs redunced the cost and row count--
