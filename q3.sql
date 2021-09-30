use springboardopt;

SET @v1 = 1612521;
SET @v2 = 1145072;
SET @v3 = 1828467;
SET @v4 = 'MGT382';
SET @v5 = 'Amber Hill';
SET @v6 = 'MGT';
SET @v7 = 'EE';			  
SET @v8 = 'MAT';

-- 3. List the names of students who have taken course v4 (crsCode).
SELECT name FROM Student WHERE id IN (SELECT studId FROM Transcript WHERE crsCode = @v4);

_________

EXPLAIN ANALYZE
SELECT name FROM Student WHERE id IN (SELECT studId FROM Transcript WHERE crsCode = 'MGT382');

--OUTPUT--
-> Nested loop inner join  (cost=5.50 rows=10) (actual time=0.134..0.140 rows=2 loops=1)
    -> Filter: (`<subquery2>`.studId is not null)  (cost=10.33..2.00 rows=10) (actual time=0.118..0.119 rows=2 loops=1)
        -> Table scan on <subquery2>  (cost=0.26..2.62 rows=10) (actual time=0.001..0.001 rows=2 loops=1)
            -> Materialize with deduplication  (cost=11.51..13.88 rows=10) (actual time=0.118..0.118 rows=2 loops=1)
                -> Filter: (Transcript.studId is not null)  (cost=10.25 rows=10) (actual time=0.048..0.110 rows=2 loops=1)
                    -> Filter: (Transcript.crsCode = 'MGT382')  (cost=10.25 rows=10) (actual time=0.047..0.109 rows=2 loops=1)
                        -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.020..0.088 rows=100 loops=1)
    -> Index lookup on Student using Student_id (id=`<subquery2>`.studId)  (cost=2.60 rows=1) (actual time=0.009..0.010 rows=1 loops=2)



_________

-- BOTTLENECK: although it does use an index scan on student id, since there is a subquery in the WHERE statement, the cost of checking this id constraint is very costly at 2.60. Additionally, it performs the two filtering statements (crscode, studId) seperately. It also perforfms two different tablescans--
_________

--SOLUTION: use a join statement rather than a subquery in the WHERE statement.--
_________


EXPLAIN ANALYZE
SELECT name FROM Student join Transcript on id=studid where crsCode='MGT382';


--OUTPUT--
-> Nested loop inner join  (cost=13.75 rows=10) (actual time=0.085..0.179 rows=2 loops=1)
    -> Filter: ((Transcript.crsCode = 'MGT382') and (Transcript.studId is not null))  (cost=10.25 rows=10) (actual time=0.065..0.151 rows=2 loops=1)
        -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.020..0.121 rows=100 loops=1)
    -> Index lookup on Student using Student_id (id=Transcript.studId)  (cost=0.26 rows=1) (actual time=0.011..0.012 rows=1 loops=2)


_________

--OUTCOME: cost of index lookup Student using Student_id is reduced from 2.6 to 0.26. Filtering for crsCode and studID is also now processed together, saving execution time and cost.Lastly, there is only one tablescan on Trascripts rather than addition table scan on the subquery--
