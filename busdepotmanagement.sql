drop database busdepot;
create database busdepot;
use busdepot;

create table bus(                                -- bus table
    busid int primary key auto_increment,
    busnumber varchar(20) unique,
    capacity int,
    depotname varchar(20)
    );
    
create table driver(                             -- driver table
    driverid int primary key auto_increment,
    name varchar(20),
    licensenumber varchar(20) unique,
    experienceyears int
    );

create table route(                              -- route table
    routeid int primary key auto_increment,
    source varchar(20),
    destination varchar(20),
    distance_km int
    );

create table timetable(                          -- timetable table
    timetableid int primary key auto_increment,
    busid int,
    routeid int,
    deparaturetime  datetime,
    arrivaltime datetime,
    foreign key (busid) references bus(busid),
    foreign key (routeid) references route (routeid)
    );

create table ticket (                             -- ticket table
    ticketid int primary key auto_increment,
    timetableid int,
    passangername varchar(20),
    seatnumber int,
    fare decimal (10,2),
    foreign key (timetableid) references timetable(timetableid)
    );

-- insert buses:
insert into bus (busnumber, capacity, depotname) values
('MH01AB1234', 40, 'Kalyan Depot'),
('MH02CD5678', 50, 'Thane Depot'),
('MH03EF9012', 30, 'Mumbai Depot');

-- insert drivers:
insert into driver (name, licensenumber, experienceyears)  values
('Ramesh Patil', 'LIC12345', 10),
('Suresh Jadhav', 'LIC67890', 5),
('Anil Kumar', 'LIC54321', 8);

-- insert routes:
insert into route (source, destination, distance_km) values
('Kalyan', 'Thane', 20),
('Thane', 'Mumbai', 25),
('Kalyan', 'Pune', 120);

-- insert timetable:
insert into timetable (busid, routeid, deparaturetime, arrivaltime) values
(1, 1, '2026-02-14  08:00:00', '2026-02-14  08:45:00'),
(2, 2, '2026-02-14  09:00:00', '2026-02-14  09:50:00'),
(3, 3, '2026-02-14  07:00:00', '2026-02-14  09:30:00');

-- insert ticket:
insert into ticket (timetableid, passangername, seatnumber, fare) values
(1, 'Amit Sharma', 1, 50.00),
(1, 'Priya Singh', 2, 50.00),
(2, 'Rahul Mehta', 1, 70.00),
(3, 'Sneha Desai', 1, 200.00),
(3, 'Vikas Joshi', 2, 200.00);

-- questions :-
-- 1 show all buses with their depot
select busnumber, capacity, depotname from bus;

-- 2 find all timetable with route info
select s.timetableid, b.busnumber, r.source, r.destination, s.deparaturetime
from timetable s
join bus b on s.busid = b.busid
join route r on s.routeid = r.routeid;

-- 3 total revenue per bus
select b.busnumber, sum(t.fare) as totalrevenue
from ticket t
join timetable s on t.timetableid = s.timetableid
join bus b on s.busid = b.busid
group by b.busnumber;

-- 4 find busiest route(most tickets booked)
select r.source, r.destination, count(t.ticketid) as ticketsbooked
from ticket t
join timetable s on t.timetableid = s.timetableid
join route r on s.routeid = r.routeid
group by r.routeid
order by  ticketsbooked desc;

-- 5 tickets with bus and route info
select 
  t.ticketid,
  t.passangername,
  t.seatnumber,
  t.fare,
  b.busnumber,
  r.source,
  r.destination,
  s.deparaturetime
from  ticket t
join timetable s on t.timetableid = s.timetableid
join bus b on s.busid = b.busid
join route r on s.routeid = r.routeid
order by t.ticketid;

-- advance sql practice :
-- 1 find passangers who paid fare greater than the average fare
select passangername, fare
from ticket
where fare>(select avg(fare) from ticket);

-- 2 show bus details with total tickets booked (using left join)
select b.busnumber, count(t.ticketid) as ticketsbooked
from bus b
left join timetable s on b.busid = s.busid
left join ticket t on s.timetableid = t.timetableid
group by b.busnumber;

-- 3 find the route with maximum revenue (using subquery)
select r.source, r.destination, sum(t.fare) as totalrevenue
from ticket t
join timetable s on t.timetableid = s.timetableid
join route r on s.routeid = r.routeid
group by r.routeid
having sum(t.fare)=(
 select max(totalfare)
 from (
      select sum(t.fare) as totalfare
      from ticket t
      join timetable s on t.timetableid = s.timetableid
      group by s.routeid
      ) as revenuetable
      );

-- 4 find buses that have not been assigned any schedule
select busnumber
from bus
where busid not in (select busid from timetable);

-- 5 get all tickets for a given bus (stored procedure)
delimiter //
create procedure  getticketsbybus (in busid int)
begin
     select t.ticketid, t.passangername, t.seatnumber, t.fare
     from ticket t
     join timetable s on t.timetableid = s.timetableid
     where s.busid = busid;
end //
delimiter ;
-- call getticketsbybus(1);   (to see output call this function)	

-- 6 prevent duplicate seat booking in same schedule (Trigger)
delimiter //
create trigger preventduplicateseat
before insert on ticket
for each row
begin 
     if exists(
          select 1 from ticket
          where timetableid = new.timetableid
          and seatnumber = new.seatnumber
		) then
          signal sqlstate '45000'
          set message_text = 'seat already booked!' ;
		end if;
	end //
    delimiter ;
/* INSERT INTO Ticket (timetableid, PassangerName, SeatNumber, Fare)
VALUES (1, 'Test User', 1, 50.00);  */                              -- error output dekhne ke liye
/*INSERT INTO Ticket (timetableid, PassangerName, SeatNumber, Fare)
VALUES (1, 'New Passenger', 3, 50.00); */                           -- output main row affected ho jayega 

