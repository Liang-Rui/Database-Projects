--Q1:

drop type if exists RoomRecord cascade;
create type RoomRecord as (valid_room_number integer, bigger_room_number integer);

create or replace function Q1(course_id integer)
    returns RoomRecord
as $$
DECLARE
	numOfEnrolment integer;
	numOfEnrolmentWaitlist integer;
	numOfRoom RoomRecord%ROWTYPE;

BEGIN
-- If no student enrols in the course, then raise invalid courseid error;
	IF not exists (select* from course_enrolments as ce where ce.course = course_id) then
		RAISE EXCEPTION 'INVALID COURSEID';
	END IF;
	
-- Count all the students who enrolled in the course.
	select count(ce.student) into numOfEnrolment
	from course_enrolments as ce
	where ce.course = course_id;
	
-- Count all the students who were in the course waitlist.
	select count(cew.student) into numOfEnrolmentWaitlist
	from course_enrolment_waitlist as cew
	where cew.course = course_id;
	
-- Count all the rooms which can hold all the students who enrolled in the course.
	select count(r.id) into numOfRoom.valid_room_number
	from rooms as r
	where r.capacity >= numOfEnrolment;
	
-- Count all the rooms which can hold all the students who were in the waitlist plus the students who enrolled in the course.
	select count(r.id) into numOfRoom.bigger_room_number
	from rooms as r
	where r.capacity >= (numOfEnrolmentWaitlist + numOfEnrolment);
	
	RETURN numOfRoom;

END;
$$ language plpgsql;



--Q2:

drop type if exists TeachingRecord cascade;
create type TeachingRecord as (cid integer, term char(4), code char(8), name text, uoc integer, average_mark integer, highest_mark integer, median_mark integer, totalEnrols integer);

create or replace function Q2(staff_id integer)
	returns setof TeachingRecord
as $$
DECLARE
	courseRecords RECORD;
	teachingResults TeachingRecord%ROWTYPE;
	courseMarks integer[];
	
BEGIN
-- First we should raise an exception if the staff_id does not match any staff.id
	IF not exists (select* from staff where staff.id = staff_id) THEN
		RAISE EXCEPTION 'INVALID STAFFID';
	END IF;
	
-- Then we can find out each valid course that this staff had taught.
	FOR courseRecords IN (select distinct courses.id as courseID, 
							(substring(cast(semesters.year as varchar(10)) from 3) || lower(semesters.term)) as courseTerm,
							subjects.code as courseCode,
							subjects.name as courseName,
							subjects.uoc as courseUOC
						  from course_staff as cs, course_enrolments as ce, courses, subjects, semesters
						  where cs.staff = staff_id and cs.course = ce.course 
													and ce.mark is not null 
													and courses.id = cs.course
													and subjects.id = courses.subject 
													and semesters.id = courses.semester)
	LOOP
		teachingResults.cid := courseRecords.courseID;
		teachingResults.term := courseRecords.courseTerm;
		teachingResults.code := courseRecords.courseCode;
		teachingResults.name := courseRecords.courseName;
		teachingResults.uoc := courseRecords.courseUOC;
		
-- Clear the array.
		courseMarks := '{}';
		
-- Store all the marks of that course into an array in descending order for computing.
		courseMarks := array(select ce.mark 
								from course_enrolments as ce 
								where ce.course = courseRecords.courseID and ce.mark is not null 
								order by ce.mark desc);

-- The number of marks is equal to the number of students since course_enrolments.student is unique.
		teachingResults.totalEnrols := array_length(courseMarks, 1);
		
-- The array is in descending order, so the first entry will be the highest mark.
		teachingResults.highest_mark := courseMarks[1];
		
-- Compute the median mark.
		IF (teachingResults.totalEnrols % 2) = 1 THEN
			teachingResults.median_mark := courseMarks[(teachingResults.totalEnrols + 1)/2];
		ELSE
			teachingResults.median_mark := round((courseMarks[teachingResults.totalEnrols/2] + courseMarks[teachingResults.totalEnrols/2 + 1]) :: numeric / 2);
		END IF;

-- Compute the average mark.
		select round(avg(ce.mark)) INTO teachingResults.average_mark
		from course_enrolments as ce
		where ce.course = courseRecords.courseID and ce.mark is not null;

-- Accumulate the result tuple.
		RETURN NEXT teachingResults;

	END LOOP;
	
-- Returns the accumulated tuples.
	RETURN;
	
END;
$$ language plpgsql;


--Q3:

drop type if exists CourseRecord cascade;
create type CourseRecord as (unswid integer, student_name text, course_records text);

create or replace function Q3(org_id integer, num_courses integer, min_score integer)
  returns setof CourseRecord
as $$
DECLARE
-- resultRecord_val is used to return the student's course record.
	resultRecord_val CourseRecord%ROWTYPE;
-- student_records is used for the loop to loop every student who satisfy the requirements.
	student_records RECORD;
-- numOfRecord is used for counting the number of records concatenated.
	numOfRecord_val integer;
-- student_id_val is used for selecting the first five students who satisfy the requirements.
	student_id_val integer;
BEGIN
-- First we need to check whether the function input is valid.
	IF not exists (select* from orgunits where orgunits.id = org_id) THEN
		RAISE EXCEPTION 'INVALID ORGID';
	END IF;
-- Initiate numOfRecord_val to check the condition in the loop.
	numOfRecord_val := 0;
-- I use a complex query to retrieve all the students who satisfy the requirements.
	FOR student_records IN (with
				-- organisationID_table retrieves all the organisation id recursively.
						organisationID_table(orgID) 
						AS (
						(with recursive organisationGroups(sub_member) as (
						select orgunit_groups.member
						from orgunit_groups
						where orgunit_groups.owner = $1 and orgunit_groups.member <> $1
						
						UNION ALL
																									
						select orgunit_groups.member
						from organisationGroups, orgunit_groups
						where orgunit_groups.owner = organisationGroups.sub_member and orgunit_groups.owner <> orgunit_groups.member
						)
						
						select organisationGroups.sub_member
						from organisationGroups)
						
						union 
						
						select $1),
					
				-- Then we can find out all the students who had taken courses offered by the particular organisational units.
						coursesTaken(stID, courseID, semester, courseMark, subjectCode, subjectName, subjectOrgID)
						AS (
						select ce.student,courses.id ,courses.semester, ce.mark, subjects.code, subjects.name, subjects.offeredby
						from organisationID_table, subjects, courses, course_enrolments as ce
						where organisationID_table.orgID = subjects.offeredby and courses.subject = subjects.id 
						and ce.course = courses.id),

				-- Then we can find out those students who satisfy the requirements given.
						student_records_table(unswID, stName, studentID)
						AS 
						(with numOfCoursesTaken(studentID_course_greater) as (
						select coursesTaken.stID
						from coursesTaken
						group by coursesTaken.stID
						having count(coursesTaken.courseID) > $2 and max(coursesTaken.courseMark) >= $3
						)

						select people.unswid, people.name, numOfCoursesTaken.studentID_course_greater
						from numOfCoursesTaken, people
						where numOfCoursesTaken.studentID_course_greater = people.id)
						
					-- Then we can retrieve the students' course records.
						select  student_records_table.studentID as studentID, 
								student_records_table.unswID as unswID, 
								student_records_table.stName as stName,
								coursesTaken.subjectCode as subjectCode, 
								coursesTaken.subjectName as subjectName, 
								semesters.name as semestersName, 
								orgunits.name as orgunitsName, 
								coursesTaken.courseMark as courseMark
						from coursesTaken, student_records_table, semesters, orgunits
						where  coursesTaken.stID = student_records_table.studentID and coursesTaken.semester = semesters.id
								and coursesTaken.subjectOrgID = orgunits.id
						order by student_records_table.studentID,
									coursesTaken.courseMark desc nulls last,
									coursesTaken.courseID asc)
		LOOP
-- First check whether it is the first time inter the loop and initial all the variables.
		IF numOfRecord_val = 0 THEN
			student_id_val := student_records.studentID;
			resultRecord_val.unswid := student_records.unswID;
			resultRecord_val.student_name := student_records.stName;
			resultRecord_val.course_records := '';
			resultRecord_val.course_records := resultRecord_val.course_records || student_records.subjectCode :: text || ', '
												|| student_records.subjectName :: text || ', '
												|| student_records.semestersName :: text || ', '
												|| student_records.orgunitsName :: text || ', ';
			IF student_records.courseMark is null THEN
				resultRecord_val.course_records := resultRecord_val.course_records || 'null' ||  E'\n';
			ELSE
				resultRecord_val.course_records := resultRecord_val.course_records || student_records.courseMark :: text ||  E'\n';
			END IF;
			numOfRecord_val := numOfRecord_val + 1;
-- If it is not the first time enter the loop, we can check whether a different student record enter the loop,
-- then we can return the previous student's records and initiate the new student's record.
		ELSIF student_records.studentID <> student_id_val THEN
			RETURN NEXT resultRecord_val;
			numOfRecord_val := 1;
			student_id_val := student_records.studentID;
			resultRecord_val.unswid := student_records.unswID;
			resultRecord_val.student_name := student_records.stName;
			resultRecord_val.course_records := '';
			resultRecord_val.course_records := resultRecord_val.course_records || student_records.subjectCode :: text || ', '
												|| student_records.subjectName :: text || ', '
												|| student_records.semestersName :: text || ', '
												|| student_records.orgunitsName :: text || ', ';
			IF student_records.courseMark is null THEN
				resultRecord_val.course_records := resultRecord_val.course_records || 'null' ||  E'\n';
			ELSE
				resultRecord_val.course_records := resultRecord_val.course_records || student_records.courseMark :: text ||  E'\n';
			END IF;
-- If the number of course records are less than five, we concatenate the new course record.
		ELSIF numOfRecord_val < 5 THEN
			resultRecord_val.course_records := resultRecord_val.course_records || student_records.subjectCode :: text || ', '
												|| student_records.subjectName :: text || ', '
												|| student_records.semestersName :: text || ', '
												|| student_records.orgunitsName :: text || ', ';
			IF student_records.courseMark is null THEN
				resultRecord_val.course_records := resultRecord_val.course_records || 'null' ||  E'\n';
			ELSE
				resultRecord_val.course_records := resultRecord_val.course_records || student_records.courseMark :: text ||  E'\n';
			END IF;
			numOfRecord_val := numOfRecord_val + 1;
		END IF;
	END LOOP;
-- Return the last student's record.
	RETURN NEXT resultRecord_val;
-- Return all the records.
	RETURN;
END;
$$ language plpgsql;