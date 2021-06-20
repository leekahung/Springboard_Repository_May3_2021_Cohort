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

SELECT name
FROM Facilities
WHERE membercost != 0;

/* Q2: How many facilities do not charge a fee to members? */

SELECT COUNT(name)
FROM Facilities
WHERE membercost = 0;

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE membercost != 0 AND membercost < monthlymaintenance * 0.20;

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT *
FROM Facilities
WHERE facid IN (1, 5);

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance,
    (CASE WHEN monthlymaintenance < 100 THEN 'cheap' 
        ELSE 'expensive' END) AS cheap_or_expensive
FROM Facilities;

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname
FROM Members
WHERE memid != 0;

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT CONCAT(m.firstname, ' ', m.surname) AS name
FROM Bookings
INNER JOIN Facilities as f
USING(facid)
INNER JOIN Members as m
USING(memid)
WHERE f.name LIKE 'Tennis Court%' AND m.memid != 0 -- excluding guests (comment out "AND m.memid != 0" to include)
ORDER BY name;

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT 
    f.name, 
    CONCAT(firstname, ' ', surname) AS booked_by,
    (CASE WHEN m.memid = 0 THEN slots * guestcost
        ELSE slots * membercost END) AS cost
FROM Bookings AS b
INNER JOIN Facilities AS f
USING (facid)
INNER JOIN Members AS m
USING (memid)
WHERE starttime LIKE '2012-09-14%'
HAVING cost > 30
ORDER BY cost DESC;

/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT *
FROM(
    SELECT 
        f.name,
        CONCAT(firstname, ' ', surname) AS booked_by,
        (CASE WHEN m.memid = 0 THEN slots * guestcost
            ELSE slots * membercost END) AS cost
    FROM Bookings AS b
    INNER JOIN Facilities AS f
    USING (facid)
    INNER JOIN Members AS m
    USING (memid)
    WHERE starttime LIKE '2012-09-14%') AS info
WHERE cost > 30
ORDER BY cost DESC;

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

WITH guest AS (
    SELECT
        f.name,
        b.facid,
        SUM(slots) * f.guestcost AS guest_revenue
    FROM Bookings as b
    INNER JOIN Facilities as f
    USING(facid)
    WHERE b.memid = 0
    GROUP BY facid
),
members AS (
    SELECT
        f.name,
        b.facid,
        SUM(slots) * f.membercost AS member_revenue
    FROM Bookings as b
    INNER JOIN Facilities as f
    USING(facid)
    WHERE b.memid != 0
    GROUP BY facid
)

SELECT
    f.name,
    guest.guest_revenue + members.member_revenue AS revenue
FROM Bookings
INNER JOIN Facilities as f
USING(facid)
INNER JOIN guest
USING(facid)
INNER JOIN members
USING(facid)
GROUP BY facid
HAVING revenue < 1000
ORDER BY revenue DESC

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

SELECT
    a.surname || ', ' || a.firstname AS surname_firstname, -- sqlite use || instead of CONCAT
    b.surname || ', ' || b.firstname AS recommededby_name
FROM Members AS a
LEFT JOIN Members AS b
ON a.recommendedby = b.memid
WHERE a.recommendedby != ''; -- apparently empty string '' is not null

/* Q12: Find the facilities with their usage by member, but not guests */

SELECT
    f.name,
    ROUND(SUM(b.slots) * 1.0 / (SELECT SUM(slots) FROM Bookings) * 100, 2) AS member_percent_usage
FROM Bookings as b
INNER JOIN Facilities as f
USING(facid)
WHERE b.memid != 0
GROUP BY facid;

/* Q13: Find the facilities usage by month, but not guests */

WITH july AS (
    SELECT
        f.name,
        b.facid,
        ROUND(SUM(b.slots) * 1.0 / (SELECT SUM(slots) FROM Bookings) * 100, 2) AS jul_percent_usage
    FROM Bookings as b
    INNER JOIN Facilities as f
    USING(facid)
    WHERE strftime('%m', b.starttime) = '07'
    GROUP BY facid
),    
august AS (
    SELECT
        f.name,
        b.facid,
        ROUND(SUM(b.slots) * 1.0 / (SELECT SUM(slots) FROM Bookings) * 100, 2) AS aug_percent_usage
    FROM Bookings as b
    INNER JOIN Facilities as f
    USING(facid)
    WHERE strftime('%m', b.starttime) = '08'
    GROUP BY facid
),
september AS (
    SELECT
        f.name,
        b.facid,
        ROUND(SUM(b.slots) * 1.0 / (SELECT SUM(slots) FROM Bookings) * 100, 2) AS sept_percent_usage
    FROM Bookings as b
    INNER JOIN Facilities as f
    USING(facid)
    WHERE strftime('%m', b.starttime) = '09'
    GROUP BY facid
)
 
SELECT
    f.name,
    july.jul_percent_usage,
    august.aug_percent_usage,
    september.sept_percent_usage
FROM Bookings
INNER JOIN Facilities as f
USING(facid)
INNER JOIN july
USING(facid)
INNER JOIN august
USING(facid)
INNER JOIN september
USING(facid)
GROUP BY facid;
