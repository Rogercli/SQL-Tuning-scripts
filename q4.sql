use springboardopt;

SET @v1 = 1612521;
SET @v2 = 1145072;
SET @v3 = 1828467;
SET @v4 = 'MGT382';
SET @v5 = 'Amber Hill';
SET @v6 = 'MGT';
SET @v7 = 'EE';			  
SET @v8 = 'MAT';

-- 4. List the names of students who have taken a course taught by professor v5 (name).
EXPLAIN ANALYZE
SELECT name FROM Student,
	(SELECT studId FROM Transcript,
		(SELECT crsCode, semester FROM Professor
			JOIN Teaching
			WHERE Professor.name = 'Amber Hill' AND Professor.id = Teaching.profId) as alias1
	WHERE Transcript.crsCode = alias1.crsCode AND Transcript.semester = alias1.semester) as alias2
WHERE Student.id = alias2.studId;




--OUTPUT--
-> Inner hash join (Student.id = Transcript.studId)  (cost=1313.72 rows=160) (actual time=0.260..0.260 rows=0 loops=1)
    -> Table scan on Student  (cost=0.03 rows=400) (never executed)
    -> Hash
        -> Inner hash join (Professor.id = Teaching.profId)  (cost=1144.90 rows=4) (actual time=0.256..0.256 rows=0 loops=1)
            -> Filter: (Professor.`name` = <cache>((@v5)))  (cost=0.95 rows=4) (never executed)
                -> Table scan on Professor  (cost=0.95 rows=400) (never executed)
            -> Hash
                -> Filter: ((Teaching.semester = Transcript.semester) and (Teaching.crsCode = Transcript.crsCode))  (cost=1010.70 rows=100) (actual time=0.250..0.250 rows=0 loops=1)
                    -> Inner hash join (<hash>(Teaching.semester)=<hash>(Transcript.semester)), (<hash>(Teaching.crsCode)=<hash>(Transcript.crsCode))  (cost=1010.70 rows=100) (actual time=0.250..0.250 rows=0 loops=1)
                        -> Table scan on Teaching  (cost=0.01 rows=100) (actual time=0.004..0.074 rows=100 loops=1)
                        -> Hash
                            -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.021..0.093 rows=100 loops=1)




_________

-- BOTTLENECK: table scans on all 4 tables and does not use indexes. Furthermore, some queries are never executed such as the table scan on student or professor and there is no output returned.--
_________

--SOLUTION: to minimize nested joins and queries, one method was using temporary tables (one approach with indexing and another without) and another method was using CTE.These methods were used to connect Professor with Course Table and Student with Transcript table--
_________


CREATE TEMPORARY TABLE professor_course as
select id, crsCode
from Professor
join Teaching
on id=profId
where name='Amber Hill';

CREATE TEMPORARY TABLE student_transcript as
select name, crsCode
from Student
join Transcript
on id=studId;

EXPLAIN ANALYZE
select name
from professor_course
join student_transcript
using(crsCode);

--TEMP TABLE W/O INDEX--
-> Filter: (student_transcript.crsCode = professor_course.crsCode)  (cost=10.60 rows=10) (actual time=0.044..0.074 rows=2 loops=1)
    -> Inner hash join (<hash>(student_transcript.crsCode)=<hash>(professor_course.crsCode))  (cost=10.60 rows=10) (actual time=0.042..0.072 rows=2 loops=1)
        -> Table scan on student_transcript  (cost=1.25 rows=100) (actual time=0.003..0.033 rows=100 loops=1)
        -> Hash
            -> Table scan on professor_course  (cost=0.35 rows=1) (actual time=0.018..0.021 rows=1 loops=1)



_________

CREATE INDEX crscode_idx ON student_transcript(crsCode);


EXPLAIN ANALYZE
select name
from professor_course
join student_transcript
using(crsCode);


--TEMP TABLE WITH INDEX--
-> Nested loop inner join  (cost=0.70 rows=1) (actual time=0.040..0.046 rows=2 loops=1)
    -> Filter: (professor_course.crsCode is not null)  (cost=0.35 rows=1) (actual time=0.019..0.020 rows=1 loops=1)
        -> Table scan on professor_course  (cost=0.35 rows=1) (actual time=0.018..0.019 rows=1 loops=1)
    -> Index lookup on student_transcript using crscode_idx (crsCode=professor_course.crsCode)  (cost=0.35 rows=1) (actual time=0.019..0.024 rows=2 loops=1)





_________


EXPLAIN ANALYZE
with professor_course_cte as (
select id, crsCode
from Professor
join Teaching
on id=profId
where name='Amber Hill'),
student_transcript_cte as(
select name, crsCode
from Student
join Transcript
on id=studId)
select name
from student_transcript_cte
join professor_course_cte
using(crsCode);

--CTE OUTPUT--
-> Inner hash join (Student.id = Transcript.studId)  (cost=164490.09 rows=160000) (actual time=0.569..0.869 rows=2 loops=1)
    -> Table scan on Student  (cost=0.01 rows=400) (actual time=0.004..0.269 rows=400 loops=1)
    -> Hash
        -> Filter: (Transcript.crsCode = Teaching.crsCode)  (cost=4442.07 rows=4000) (actual time=0.473..0.538 rows=2 loops=1)
            -> Inner hash join (<hash>(Transcript.crsCode)=<hash>(Teaching.crsCode))  (cost=4442.07 rows=4000) (actual time=0.473..0.537 rows=2 loops=1)
                -> Table scan on Transcript  (cost=0.01 rows=100) (actual time=0.003..0.069 rows=100 loops=1)
                -> Hash
                    -> Inner hash join (Teaching.profId = Professor.id)  (cost=441.04 rows=400) (actual time=0.381..0.440 rows=1 loops=1)
                        -> Table scan on Teaching  (cost=0.03 rows=100) (actual time=0.005..0.070 rows=100 loops=1)
                        -> Hash
                            -> Filter: (Professor.`name` = 'Amber Hill')  (cost=40.75 rows=40) (actual time=0.047..0.345 rows=1 loops=1)
                                -> Table scan on Professor  (cost=40.75 rows=400) (actual time=0.022..0.286 rows=400 loops=1)


--OUTCOME: comparing the results, using the temporary tables reduced the cost of the queries and number of rows reduced significantly. The CTE approach still performed table scans for all 4 tables while the temporary table method did not. In addition, adding indexing to the temporary tables reduced cost, row # and execution times--
