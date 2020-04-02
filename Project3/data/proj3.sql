--Q1:

drop type if exists RoomRecord cascade;
create type RoomRecord as (valid_room_number integer, bigger_room_number integer);

create or replace function Q1(course_id integer)
    returns RoomRecord
as $$
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;


--Q2:

drop type if exists TeachingRecord cascade;
create type TeachingRecord as (cid integer, term char(4), code char(8), name text, uoc integer, average_mark integer, highest_mark integer, median_mark integer, totalEnrols integer);

create or replace function Q2(staff_id integer)
	returns setof TeachingRecord
as $$
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;


--Q3:

drop type if exists CourseRecord cascade;
create type CourseRecord as (unswid integer, student_name text, course_records text);

create or replace function Q3(org_id integer, num_courses integer, min_score integer)
  returns setof CourseRecord
as $$
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;
