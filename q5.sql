use springboardopt;

SET @v1 = 1612521;
SET @v2 = 1145072;
SET @v3 = 1828467;
SET @v4 = 'MGT382';
SET @v5 = 'Amber Hill';
SET @v6 = 'MGT';
SET @v7 = 'EE';			  
SET @v8 = 'MAT';


-- 5. List the names of students who have taken a course from department v6 (deptId), but not v7.
SELECT * FROM Student, 
	(SELECT studId FROM Transcript, Course WHERE deptId = 'MGT' AND Course.crsCode = Transcript.crsCode
	AND studId NOT IN
	(SELECT studId FROM Transcript, Course WHERE deptId = 'EE' AND Course.crsCode = Transcript.crsCode)) as alias
WHERE Student.id = alias.studId;




--OUTPUT--
-> Inner hash join (Student.id = Transcript.studId)  (cost=4112.69 rows=4000) (actual time=0.520..0.857 rows=30 loops=1)
    -> Table scan on Student  (cost=0.06 rows=400) (actual time=0.006..0.284 rows=400 loops=1)
    -> Hash
        -> Filter: (<in_optimizer>(Transcript.studId,Transcript.studId in (select #3) is false) and (Transcript.crsCode = Course.crsCode))  (cost=110.52 rows=100) (actual time=0.363..0.496 rows=30 loops=1)
            -> Inner hash join (<hash>(Transcript.crsCode)=<hash>(Course.crsCode))  (cost=110.52 rows=100) (actual time=0.133..0.228 rows=30 loops=1)
                -> Table scan on Transcript  (cost=0.13 rows=100) (actual time=0.004..0.072 rows=100 loops=1)
                -> Hash
                    -> Filter: (Course.deptId = 'MGT')  (cost=10.25 rows=10) (actual time=0.023..0.108 rows=26 loops=1)
                        -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.019..0.088 rows=100 loops=1)
            -> Select #3 (subquery in condition; run only once)
                -> Filter: ((Transcript.studId = `<materialized_subquery>`.studId))  (actual time=0.001..0.001 rows=0 loops=27)
                    -> Limit: 1 row(s)  (actual time=0.001..0.001 rows=0 loops=27)
                        -> Index lookup on <materialized_subquery> using <auto_distinct_key> (studId=Transcript.studId)  (actual time=0.000..0.000 rows=0 loops=27)
                            -> Materialize with deduplication  (cost=120.52..120.52 rows=100) (actual time=0.247..0.247 rows=32 loops=1)
                                -> Filter: (Transcript.crsCode = Course.crsCode)  (cost=110.52 rows=100) (actual time=0.108..0.207 rows=34 loops=1)
                                    -> Inner hash join (<hash>(Transcript.crsCode)=<hash>(Course.crsCode))  (cost=110.52 rows=100) (actual time=0.107..0.198 rows=34 loops=1)
                                        -> Table scan on Transcript  (cost=0.13 rows=100) (actual time=0.003..0.070 rows=100 loops=1)
                                        -> Hash
                                            -> Filter: (Course.deptId = 'EE')  (cost=10.25 rows=10) (actual time=0.006..0.083 rows=32 loops=1)
                                                -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.002..0.067 rows=100 loops=1)




_________

-- BOTTLENECK: table scans on transcript and course were repeated due to subqueries, increasing execution time and cost.The query was also made to return all fields rather than only the names of students as originally needed.--
_________

--SOLUTION: to minimize the # of joins, i only joined two tables (student and transcript), opting to filter by using "crsCode LIKE" which exist in the transcript table rather than filtering with deptId which exists in the Course table. I created a CTE table to only contain student names and courses in MGT or EE. In addition, i added an index on the student table based on ID.-
_________


CREATE INDEX stud_idx ON Student(id);

explain analyze
with student_course as(
select name, crsCode
from Student
join Transcript
on id=studId
where crsCode like 'MGT%' or crsCode like 'EE%')
select name
from student_course
where crsCode like 'MGT%' and crsCode not like 'EE%';


--OUTPUT--
-> Nested loop inner join  (cost=10.98 rows=2) (actual time=0.044..0.236 rows=26 loops=1)
    -> Filter: ((Transcript.crsCode like 'MGT%') and (not((Transcript.crsCode like 'EE%'))) and ((Transcript.crsCode like 'MGT%') or (Transcript.crsCode like 'EE%')) and (Transcript.studId is not null))  (cost=10.25 rows=2) (actual time=0.026..0.124 rows=26 loops=1)
        -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.022..0.093 rows=100 loops=1)
    -> Index lookup on Student using stud_idx (id=Transcript.studId)  (cost=0.30 rows=1) (actual time=0.003..0.004 rows=1 loops=26)


       
--OUTCOME: the cost and execution time were much faster due to less joins, and the addition of an index on student IDs redunced the cost and row count--
