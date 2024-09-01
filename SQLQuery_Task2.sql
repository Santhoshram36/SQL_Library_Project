select * from books;
select * from branch;
select * from employees;
select * from issued_status;
select * from members;
select * from return_status;

/*
Task 13:
Identify members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). Display the members's_id, member's name, book title, issue date, and days overdue.
*/


SELECT ist.issued_member_id,
       m.member_name,
       bk.book_title,
       ist.issued_date,
       DATEDIFF(day, ist.issued_date, '2024-08-24') AS over_dues_days  -- Use your desired date here
FROM issued_status AS ist
JOIN members AS m
  ON m.member_id = ist.issued_member_id
JOIN books AS bk
  ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status AS rst
  ON ist.issued_id = rst.issued_id
WHERE 
   rst.return_date IS NULL
   and
   DATEDIFF(day, ist.issued_date, '2024-08-01') > 30
order by 
    ist.issued_member_id

/*
Task 14: Update Book Status on return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
*/

select * from issued_status
where issued_book_isbn = '978-0-451-52994-2'

select * from books
where isbn = '978-0-451-52994-2'

update books
set status = 'no'
where isbn = '978-0-451-52994-2'

select * from return_status
where issued_id = 'IS130'

--
insert into return_status(return_id, issued_id, return_date, book_quality)
values
('RS125','IS130', getdate(), 'Good')
select * from return_status
where issued_id = 'IS130'

update books
set status = 'yes'
where isbn = '978-0-451-52994-2'

--Stored Procedures
CREATE PROCEDURE add_return_records
    @p_return_id VARCHAR(10), 
    @p_issued_id VARCHAR(10), 
    @p_book_quality VARCHAR(10)
AS
BEGIN
    DECLARE @v_isbn VARCHAR(50);
    DECLARE @v_book_name VARCHAR(50);

    -- Inserting into return_status based on user input
    INSERT INTO return_status (return_id, issued_id, return_date, book_quality)
    VALUES (@p_return_id, @p_issued_id, GETDATE(), @p_book_quality);

    -- Retrieving issued_book_isbn and book_title into variables
    SELECT 
        @v_isbn = ist.issued_book_isbn,
        @v_book_name = ist.issued_book_name
    FROM issued_status AS ist
    WHERE ist.issued_id = @p_issued_id;

    -- Updating the book's status
    UPDATE books
    SET status = 'yes'
    WHERE isbn = @v_isbn;

    -- Printing a message
    PRINT 'Thank you for returning the book: ' + @v_book_name;
END;


--Testing Function add_return_records

select * from books
where isbn = '978-0-307-58837-1';

select * from issued_status
where issued_book_isbn = '978-0-307-58837-1';

select * from return_status
where issued_id = 'IS135';

--Calling Function
EXEC add_return_records 'RS138', 'IS135', 'Good';


--Calling Function
EXEC add_return_records 'RS148', 'IS140', 'Good';

/*
Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rental.
*/

SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) as number_book_issued,
    COUNT(rs.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue
INTO branch_reports
FROM issued_status as ist
JOIN 
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
JOIN 
books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id,b.manager_id;


-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.

SELECT * 
INTO active_members
FROM members
WHERE member_id IN (
    SELECT DISTINCT issued_member_id
    FROM issued_status
    WHERE issued_date >= DATEADD(MONTH, -2, GETDATE())  -- Subtracting 2 months from the current date
);

select * from active_members;

-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

select e.emp_name,
       b.branch_id, 
       b.manager_id, 
       b.branch_address,
	   b.contact_no,
	   count(ist.issued_id) as no_book_issued
from issued_status as ist
join employees as e
on e.emp_id = ist.issued_emp_id
join branch as b
on e.branch_id = b.branch_id
group by e.emp_name,
       b.branch_id, 
       b.manager_id, 
       b.branch_address,
	   b.contact_no;

/*
Task 18: Stored Procedure Objective: 

Create a stored procedure to manage the status of books in a library system. 

Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 

The procedure should function as follows: 

The stored procedure should take the book_id as an input parameter. 

The procedure should first check if the book is available (status = 'yes'). 

If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 

If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/


CREATE PROCEDURE issue_book
    @p_issued_id VARCHAR(10), 
    @p_issued_member_id VARCHAR(30), 
    @p_issued_book_isbn VARCHAR(30), 
    @p_issued_emp_id VARCHAR(10)
AS
BEGIN
    DECLARE @v_status VARCHAR(10);

    -- Checking if the book is available
    SELECT 
        @v_status = status
    FROM books
    WHERE isbn = @p_issued_book_isbn;

    IF @v_status = 'yes'
    BEGIN
        -- Inserting into issued_status
        INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES
        (@p_issued_id, @p_issued_member_id, GETDATE(), @p_issued_book_isbn, @p_issued_emp_id);

        -- Updating the book's status
        UPDATE books
        SET status = 'no'
        WHERE isbn = @p_issued_book_isbn;

        -- Displaying a success message
        PRINT 'Book records added successfully for book isbn: ' + @p_issued_book_isbn;
    END
    ELSE
    BEGIN
        -- Displaying a failure message
        PRINT 'Sorry to inform you the book you have requested is unavailable. book_isbn: ' + @p_issued_book_isbn;
    END
END;


select * from books
-- "978-0-553-29698-2" -- yes
-- "978-0-375-41398-8" -- no
select * from issued_status

--Calling Function
EXEC issue_book'IS155', 'C108', '978-0-553-29698-2', 'E104';


EXEC issue_book'IS156', 'C108', '978-0-375-41398-8', 'E104';

