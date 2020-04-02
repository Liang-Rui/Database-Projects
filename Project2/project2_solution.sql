-- COMP9311 18s1 Project 1
--
-- MyMyUNSW Solution
--
-- Produced by Rui Liang




-- Q1: 
-- The following view will retrieve all the international students' id
create or replace view Q1a(studentsid)
as
select s.id
from students s
where s.stype = 'intl'
;
-- The following view will join international students with their enrolments
-- and choose students with course mark at least 85.
-- Then group the students by their id, and count how many courses they achieved at least 85 marks.
create or replace view Q1b(ceid)
as
select ce.student
from course_enrolments ce, Q1a q
where ce.student = q.studentsid and ce.mark >= 85
group by ce.student
having count(ce.course) > 20
;
-- Join thouse students with people to get the result.
create or replace view Q1(unswid, name)
as
select p.unswid, p.name
from people p, Q1b
where p.id = Q1b.ceid
;



-- Q2: 
-- Create a view that select all the id of buildings called 'Computer Science Building'.
-- Since this may result in multiple id (eg. different campus may have buildings called
-- 'Computer Science Building'), so I decided to join buildings with rooms
create or replace view Q2a(buildings_id)
as
select b.id
from buildings b
where b.name = 'Computer Science Building'
;

create or replace view Q2b(room_type_id)
as
select rt.id
from room_types rt
where rt.description = 'Meeting Room'
;

create or replace view Q2(unswid, name)
as
select r.unswid, r.longname
from rooms r,Q2a, Q2b
where r.building = Q2a.buildings_id and r.rtype = Q2b.room_type_id and 
	  r.capacity is not null and r.capacity >= 20
;


-- Q3: 
-- First we should know Stefan Bilek have enrolled in which course and the corresponding staff id.
-- Since different people may called Stefan Bilek so I decided to consider all the possible ids.
-- Since some people called Stefan Bilek may not be a student, so I ignore those people.
create or replace view Q3a(people_id)
as
select p.id
from people p
where p.name = 'Stefan Bilek' and p.id in (select students.id from students)
;

-- Find out which course Stefan Bilek have enrolled.
create or replace view Q3b(course_enrolments_course)
as
select ce.course
from course_enrolments ce, Q3a
where ce.student = Q3a.people_id
;

-- Find out the staffs who teach the coureses.
create or replace view Q3c(course_staff_id)
as
select cs.staff
from Q3b, course_staff cs
where cs.course = Q3b.course_enrolments_course
;

-- Finally retrieve their name
create or replace view Q3(unswid, name)
as
select p.unswid, p.name
from people p, Q3c
where p.id = Q3c.course_staff_id
;



-- Q4:
-- Find out students who have enrolled in comp3331
create or replace view Q4a(id)
as
select ce.student
from courses c, course_enrolments ce, subjects s
where s.code = 'COMP3331' and c.subject = s.id and ce.course = c.id
;

-- Find out students who have enrolled in comp3231
create or replace view Q4b(id)
as
select ce.student
from courses c, course_enrolments ce, subjects s
where s.code = 'COMP3231' and c.subject = s.id and ce.course = c.id
;

-- Find out students who enrolled in comp3331 but not comp3231
create or replace view Q4c(id)
as
(select q4a.id
from q4a)
except
(select q4b.id
from q4b)
;

-- Retrieve their unswid and name
create or replace view Q4(unswid, name)
as
select p.unswid,p.name
from people p, q4c
where p.id = q4c.id
;



-- Q5a: 
-- First we can find out which program did local students enrol in 11s1.
create or replace view Q5aa(students_id,program_enrolments_id)
as
select s.id,pe.id
from students s,program_enrolments pe,semesters ss
where s.stype = 'local' and s.id = pe.student and pe.semester = ss.id and ss.year = 2011
		and ss.term = 'S1'
;

-- Then we can find out such students who enrolled in streams called 'Chemistry'
create or replace view Q5ab(students_id)
as
select distinct Q5aa.students_id
from Q5aa,stream_enrolments se,streams s
where Q5aa.program_enrolments_id = se.partof and se.stream = s.id and
		s.name = 'Chemistry'
;

create or replace view Q5a(num)
as
select count(*)
from Q5ab
;

-- Q5b: 
-- First we can find out which program did international students enrol in 11s1.
create or replace view Q5ba(students_id,program_enrolments_id)
as
select s.id,pe.program
from students s,program_enrolments pe,semesters ss
where s.stype = 'intl' and s.id = pe.student and pe.semester = ss.id and ss.year = 2011
		and ss.term = 'S1'
;

-- Then we can find out the degrees offered by School of Computer Science and Engineering.
-- Since degrees are associated with programs, so we just need to retrieve programs offered
-- by School of Computer Science and Engineering.
create or replace view Q5bb(program_id)
as
select p.id
from programs p, orgunits o
where p.offeredby = o.id and o.longname = 'School of Computer Science and Engineering'
;

-- Find out those students who have enrolled in the programs.
create or replace view Q5bc(students_id)
as
select distinct Q5ba.students_id
from Q5bb,Q5ba
where Q5ba.program_enrolments_id = Q5bb.program_id
;

-- Count the number of the students satisfying all the requirements.
create or replace view Q5b(num)
as
select count(Q5bc.students_id)
from Q5bc
;


-- Q6:
-- This function only return one of the results that have the same code but different names.
create or replace function
	Q6(text) returns text
as
$$
select s.code || ' ' || s.name || ' ' || cast(s.uoc as text)
from subjects s
where s.code = $1 AND s.uoc is not null AND s.name is not null;
$$ language sql;



-- Q7: 
-- First we can find out how many international students enrolled in a program.
create or replace view Q7a(programs_id,num)
as
select pe.program,count(pe.student)
from program_enrolments pe, students s
where pe.student = s.id and s.stype = 'intl'
group by pe.program
;

-- Then we can find out how many students enrolled in a program.
create or replace view Q7b(programs_id,num)
as
select pe.program, count(pe.student)
from program_enrolments pe
group by pe.program
;

-- Calculate the percentage of internation students/all the students.
create or replace view Q7c(programs_id,percentage)
as
select Q7a.programs_id,cast(Q7a.num as numeric)*100 / cast(Q7b.num as numeric)
from Q7a,Q7b
where Q7a.programs_id = Q7b.programs_id
;

-- Retrieve the program code and name that satisfys the requirements.
create or replace view Q7(code, name)
as
select p.code,p.name
from programs p, (select Q7c.programs_id as id, Q7c.percentage as per
	   			  from Q7c
	   			  where Q7c.percentage > 50) as program_per
where program_per.id = p.id
;



-- Q8:
-- First we can calculate each course's average mark.
create or replace view Q8a(course, averageMark)
as
select ce.course,avg(ce.mark)
from course_enrolments ce
where ce.mark is not null
group by ce.course
having count(ce.mark) >= 15
;

-- Then we can find out which course has the hightest average mark.
create or replace view Q8b(course)
as
select Q8a.course
from Q8a
where Q8a.averageMark = 
(select max(Q8a.averageMark)
from Q8a)
;

create or replace view Q8(code, name, semester)
as
select s.code,s.name,se.name
from Q8b,courses c,subjects s,semesters se
where Q8b.course = c.id and c.semester = se.id and c.subject = s.id
;



-- Q9:
-- First we can find out all the current Head of School at UNSW.
create or replace view Q9a(staffid,name, school, email, starting)
as
select a.staff,p.name,o.longname,p.email,a.starting
from affiliations a,orgunits o,orgunit_types ot,staff_roles sr,people p
where sr.name = 'Head of School' and sr.id = a.role and a.isprimary = true and
		a.ending is null and a.orgunit = o.id and o.utype = ot.id and ot.name = 'School' and
			p.id = a.staff
;

-- Then we can find out how many subjects each staff have taught.
-- I use distinct to eliminate the same staff taught subjects with the same code.
-- This view will filter out those staff who did not taught any subjects by joining
-- q9a with course_staff.
create or replace view Q9b(staffid, subject_code)
as
select distinct q9a.staffid, s.code
from q9a, course_staff cs, courses c, subjects s
where q9a.staffid = cs.staff and cs.course = c.id and c.subject = s.id
;

create or replace view Q9c(staffid, num_subjects)
as
select q9b.staffid, count(q9b.subject_code)
from q9b
group by q9b.staffid
;

-- Join the staff who satisfys the requirements.
create or replace view Q9(name, school, email, starting, num_subjects)
as
select Q9a.name, Q9a.school, Q9a.email, Q9a.starting, Q9c.num_subjects
from Q9a,Q9c
where Q9a.staffid = Q9c.staffid
;



-- Q10:
-- Firstly we need to find out which subject is offered in every major semester.
-- Q10a can find out courses with the name starting 'COMP93' offered from 2003 to 2012.
-- This view will filter out courses that no valid students enrolled in.
create or replace view Q10a(id,code,name,year,term)
as
select distinct c.id,s.code,s.name,se.year,se.term
from semesters se,courses c, subjects s, course_enrolments ce
where c.semester = se.id and se.year >= 2003 and se.year <= 2012 and
		s.id = c.subject and s.code ~ '^COMP93' and ce.course = c.id and
			ce.mark >= 0
;

-- Q10b_1 finds out courses satisfy Q10a and they offered every s1 and s2.
create or replace view Q10b_1(subject_code, subject_name, subject_year, s1_term, course_s1_id, s2_term, course_s2_id)
as
select q1.code, q1.name, q1.year, q1.term, q1.id, q2.term, q2.id
from Q10a q1, Q10a q2
where q1.code = q2.code and q1.year = q2.year and q1.term < q2.term
;

-- Courses not offered every year and every major semester from 2003 to 2012 will be filtered out.
create or replace view Q10b_2(subject_code)
as
select q.subject_code
from Q10b_1 q
group by q.subject_code
having count(q.subject_year) = 10
;

-- Join satisfiable courses with subjects to get their code, name.
create or replace view Q10b(subject_code, subject_name, subject_year, s1_term, course_s1_id, s2_term, course_s2_id)
as
select q1.subject_code, q1.subject_name, q1.subject_year, q1.s1_term, q1.course_s1_id, q1.s2_term, course_s2_id
from Q10b_1 q1, Q10b_2 q2
where q1.subject_code = q2.subject_code
;

-- Then we can find out the HD rate for each course.
-- Q10c_1 gets every valid marks for courses of s1.
create or replace view Q10c_1(subject_code, subject_name, subject_year, s1_term, course_s1_id, s1_mark)
as
select q.subject_code, q.subject_name, q.subject_year, q.s1_term, q.course_s1_id, ce.mark
from Q10b q, course_enrolments ce
where q.course_s1_id = ce.course and ce.mark >= 0
;

-- Q10c_2 counts the number of students who got HD in each course.
create or replace view Q10c_2(course_s1_id, s1_hd)
as
select q.course_s1_id, count(*)
from q10c_1 q
where q.s1_mark >= 85
group by q.course_s1_id
;

-- Q10c_3 counts the number of valid students taking each course.
create or replace view Q10c_3(course_s1_id, s1_mark_num)
as
select q.course_s1_id, count(*)
from Q10c_1 q
group by q.course_s1_id
;

-- Q10c_4 calculates the HD rate for each course of s1.
create or replace view Q10c_4(course_s1_id, s1_mark_hd_rate)
as
select Q10c_3.course_s1_id, cast((cast(COALESCE(Q10c_2.s1_hd,0) as numeric) / cast(Q10c_3.s1_mark_num as numeric)) as numeric(4,2))
from Q10c_3 left outer join Q10c_2 on Q10c_3.course_s1_id = Q10c_2.course_s1_id
;

-- Q10d_1 gets every valid marks for courses of s2.
create or replace view Q10d_1(subject_code, subject_name, subject_year, s2_term, course_s2_id, s2_mark)
as
select q.subject_code, q.subject_name, q.subject_year, q.s2_term, q.course_s2_id, ce.mark
from Q10b q, course_enrolments ce
where q.course_s2_id = ce.course and ce.mark >= 0
;

-- Q10d_2 counts the number of students get HD in each course.
create or replace view Q10d_2(course_s2_id, s2_hd)
as
select q.course_s2_id, count(*)
from q10d_1 q
where q.s2_mark >= 85
group by q.course_s2_id
;

-- Q10d_3 counts the number of valid students taking each course.
create or replace view Q10d_3(course_s2_id, s2_mark_num)
as
select q.course_s2_id, count(*)
from Q10d_1 q
group by q.course_s2_id
;

-- Q10d_4 calculates the HD rate for each course of s2.
create or replace view Q10d_4(course_s2_id, s2_mark_hd_rate)
as
select Q10d_3.course_s2_id, cast((cast(COALESCE(Q10d_2.s2_hd,0) as numeric) / cast(Q10d_3.s2_mark_num as numeric)) as numeric(4,2))
from Q10d_3 left outer join Q10d_2 on Q10d_3.course_s2_id = Q10d_2.course_s2_id
;

-- Q10 joins each course's HD rate with each satisfiable course.
create or replace view Q10(code, name, year, s1_HD_rate, s2_HD_rate)
as
select Q10b.subject_code, Q10b.subject_name, (substring(cast(Q10b.subject_year as varchar(10)) from 3)) as year, 
			Q10c_4.s1_mark_hd_rate, Q10d_4.s2_mark_hd_rate
from Q10b left outer join Q10c_4 on Q10b.course_s1_id = Q10c_4.course_s1_id
		left outer join Q10d_4 on Q10b.course_s2_id = Q10d_4.course_s2_id
;

