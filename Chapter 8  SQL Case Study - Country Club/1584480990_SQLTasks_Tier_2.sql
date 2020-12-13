/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */
SELECT * 
FROM country_club.Facilities 
WHERE membercost > 0;

/* Q2: How many facilities do not charge a fee to members? */
SELECT DISTINCT COUNT(name) as name
FROM country_club.Facilities 
WHERE membercost = 0;

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT 
	facid, 
    name, 
    membercost, 
    monthlymaintenance
FROM country_club.Facilities 
WHERE membercost > 0 AND membercost < monthlymaintenance *0.2;

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT *
FROM country_club.Facilities 
WHERE facid IN (1,5);

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */
SELECT name, monthlymaintenance, 
CASE WHEN (monthlymaintenance > 100) THEN 'expensive'
ELSE 'cheap'
END AS label
FROM country_club.Facilities;

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */
SELECT firstname, surname, joindate 
FROM country_club.Members 
WHERE joindate IN (
    SELECT MAX(joindate) 
    FROM country_club.Members);

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */
SELECT CONCAT( Members.firstname,  ' ', Members.surname ) AS name, Facilities.name AS court
FROM Bookings
INNER JOIN Facilities ON Bookings.facid = Facilities.facid
AND Facilities.name LIKE  'Tennis Court%'
INNER JOIN Members ON Bookings.memid = Members.memid
GROUP BY firstname, surname, court
ORDER BY name

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT CONCAT( Members.firstname,  ' ', Members.surname ) AS name, Facilities.name AS facility,
	CASE WHEN Members.memid = 0 THEN Facilities.guestcost * Bookings.slots
	ELSE  Facilities.membercost * Bookings.slots
	END AS cost
FROM Bookings
INNER JOIN Members ON Bookings.memid = Members.memid
INNER JOIN Facilities ON Bookings.facid = Facilities.facid
WHERE Bookings.starttime LIKE '2012-09-14%' 
AND ((Members.memid = 0 AND (Facilities.guestcost * Bookings.slots) > 30 )
     OR (Members.memid != 0 AND (Facilities.membercost * Bookings.slots) > 30))
GROUP BY firstname, surname, facility, cost
ORDER BY cost DESC
 

/* Q9: This time, produce the same result as in Q8, but using a subquery. */
SELECT CONCAT( sub.firstname,  ' ', sub.surname ) AS name, sub.facility, sub.cost
FROM (
SELECT Facilities.name AS facility, Members.firstname AS firstname, Members.surname AS surname,
CASE WHEN Members.memid = 0 THEN Facilities.guestcost * Bookings.slots
ELSE  Facilities.membercost * Bookings.slots
END AS cost
FROM Bookings
INNER JOIN Facilities ON Bookings.facid = Facilities.facid
INNER JOIN Members ON Bookings.memid = Members.memid 
WHERE Bookings.starttime LIKE '2012-09-14%'
) sub
WHERE sub.cost > 30
GROUP BY sub.firstname, sub.surname, sub.facility, sub.cost
ORDER BY sub.cost DESC

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

SELECT * FROM(
SELECT sub.facility AS facility, SUM(sub.cost) AS revenue 
FROM (
SELECT Facilities.name AS facility,
CASE WHEN Members.memid = 0 THEN Facilities.guestcost * Bookings.slots
ELSE  Facilities.membercost * Bookings.slots
END AS cost
FROM Bookings
INNER JOIN Members ON Bookings.memid = Members.memid
INNER JOIN Facilities ON Bookings.facid = Facilities.facid
) sub
GROUP BY sub.facility) sub2
WHERE sub2.revenue < 1000
ORDER BY revenue DESC

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

SELECT sub.name, CONCAT( Members.firstname, ' ', Members.surname ) AS recommender_name
FROM (

SELECT CONCAT( Members.firstname, ' ', Members.surname ) AS name, Members.memid, Members.recommendedby AS reco_id
FROM Members
WHERE recommendedby >0
)sub
INNER JOIN Members ON sub.reco_id = Members.memid
WHERE sub.memid !=0
ORDER BY sub.name

/* Q12: Find the facilities with their usage by member, but not guests */
/*Assuming any member using a facility is counted as a usage. A member using same facility 3 times means 3 usage*/
SELECT Facilities.name,   sub.facility_usage_by_member
FROM 
(SELECT 
	facid, 
 	COUNT(facid) AS facility_usage_by_member
FROM Bookings
INNER JOIN Members ON Members.memid = Bookings.memid
WHERE Bookings.memid !=0
GROUP BY facid) sub
INNER JOIN Facilities ON Facilities.facid = sub.facid

/* Q13: Find the facilities usage by month, but not guests */
/* usage of each facility by month excluding guests*/
SELECT sub.month, Facilities.name,   sub.facility_usage_by_month
FROM 
(SELECT  
 	Month(starttime) as month,
	facid, 
 	COUNT(facid) AS facility_usage_by_month
FROM Bookings
INNER JOIN Members ON Members.memid = Bookings.memid
WHERE Bookings.memid !=0
GROUP BY facid,month) sub
INNER JOIN Facilities ON Facilities.facid = sub.facid
ORDER BY sub.month
