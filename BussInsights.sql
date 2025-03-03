-- ----------------------------------------------------------------------------------------------------------------------------------------    
										     		 ### Basic SQL Operations ###
													    ### CRUD Operations ###
													    ### CTAS Operations ###
-- ----------------------------------------------------------------------------------------------------------------------------------------  
-- Task 1. Create a New Book Record
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

insert into books
values('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
insert into books(isbn, book_title, category, rental_price, status, author, publisher) 
values('978-1-60129-456-3', 'To Kill a Mockingbird', 'Classic', 6.00, 'yess', 'Harper Leee', 'J.B. Lippincott & Com.');

-- Task 2: Update an Existing Member's Address
UPDATE members 
SET 
    member_address = 'azad nagar'
WHERE
    member_id = 'c101';

UPDATE members 
SET 
    member_address = '420 elm st'
WHERE
    member_name = 'Alice Johnson';


-- Task 3: Delete a Record from the Issued Status Table
-- Objective: Delete the record with issued_id = 'IS104' from the issued_status table.

DELETE FROM issue_status 
WHERE
    issued_id = 'is104';
DELETE FROM issue_status 
WHERE
    issued_id = 'is106';

-- Task 4: Retrieve All Books Issued by a Specific Employee
-- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT 
    issued_emp_id, issued_book_name
FROM
    issue_status
WHERE
    issued_emp_id = 'e101';

-- Task 5: List Members Who Have Issued More Than One Book
-- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT 
    issued_emp_id, COUNT(issued_id) AS total_issued_books
FROM
    issue_status
GROUP BY issued_emp_id
HAVING COUNT(issued_id) > 1;


-- ### 3. CTAS (Create Table As Select)

CREATE TABLE total_book_issued AS SELECT bk.book_title, bk.isbn FROM
    books AS bk
        JOIN
    issue_status AS ist ON ist.issued_book_isbn = bk.isbn
GROUP BY 1 , 2;

-- ### 4. Data Analysis & Findings

SELECT 
    *
FROM
    books
WHERE
    Category = 'classic';

-- Task 8: Find Total Rental Income by Category:
SELECT 
    Category, SUM(rental_price) AS total_prices
FROM
    books
GROUP BY 1;

SELECT 
    bk.category, SUM(bk.rental_price), COUNT(*) AS total_issued
FROM
    books AS bk
        JOIN
    issue_status AS ist ON ist.issued_book_isbn = bk.isbn
GROUP BY 1;


-- Task 9. **List Members Who Registered in the Last 180 Days**:
SELECT 
    *
FROM
    members
WHERE
    DATEDIFF(CURDATE(), reg_date) <= 180;

-- Task 10: List Employees with Their Branch Manager's Name and their branch details**:
select emp.emp_id,emp.emp_name , br.manager_id , emp2.emp_name as manager_name from employees as emp
join
branch as br
on br.branch_id = emp.branch_id
join
employees as emp2
on
br.manager_id = emp2.emp_id;

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold
create table books_price_avobe_7usd
as
select * from books
where rental_price >7;

select * from books_price_avobe_7usd;

-- Task 12: Retrieve the List of Books Not Yet Returned
select * from issue_status as ist
left join 
return_status as rst
on rst.issued_id = ist.issued_id
where rst.return_id is null;
-- ----------------------------------------------------------------------------------------------------------------------------------------    
										     		### Advanced SQL Operations ###
-- ----------------------------------------------------------------------------------------------------------------------------------------    
/*
Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's name, book title, issue date, and days overdue. 
*/
select 
mb.member_name,
ist.issued_book_name,
ist.issued_date,
curdate() - ist.issued_date as overdue_days

from issue_status as ist
join
books as bk
on bk.isbn = ist.issued_book_isbn
join 
members as mb
on
mb.member_id = ist.issued_member_id
left join
return_status as rs
on 
rs.issued_id = ist.issued_id
where return_id is null
and
curdate() - ist.issued_date > 30;

/*
Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "available" when they are returned 
(based on entries in the return_status table).
*/

DELIMITER $$
CREATE PROCEDURE add_return_records(
    IN p_return_id VARCHAR(10), 
    IN p_issued_id VARCHAR(10)
)
BEGIN
    DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);

    -- Insert into return_status based on user input
    INSERT INTO return_status (return_id, issued_id, return_date)
    VALUES (p_return_id, p_issued_id, CURRENT_DATE);

    -- Select the issued book's ISBN and name from issued_status
    SELECT issued_book_isbn, issued_book_name
    INTO v_isbn, v_book_name
    FROM issue_status
    WHERE issued_id = p_issued_id;

    -- Update the books status to 'yes' (indicating the book has been returned)
    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    -- Output a message to indicate successful book return
    SELECT CONCAT('Thank you for returning the book: ', v_book_name) AS message;

END $$
DELIMITER ;
   CALL add_return_records('RS140', 'IS135');
   CALL add_return_records('RS148', 'IS140');
   
/*
Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued,
the number of books returned, and the total revenue generated from book rentals.
*/
CREATE TABLE branch_reports
AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) as number_book_issued,
    COUNT(rs.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue
FROM issue_status as ist
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
GROUP BY 1, 2;

SELECT * FROM branch_reports;



/*Task 16: CTAS: Create a Table of Active Members
 Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members 
 who have issued at least one book in the last 6 months.
 */

CREATE TABLE active_members AS
SELECT *
FROM members
WHERE member_id IN (
    SELECT DISTINCT issued_member_id
    FROM issue_status
    WHERE issued_date >= DATE_SUB(CURDATE(), INTERVAL 2 MONTH)
);
SELECT * FROM active_members;


/*
Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues.
Display the employee name, number of books processed, and their branch.
*/

SELECT 
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) as no_book_issued
FROM issue_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY 1, 2;
/*
Task 18: Identify Members Issuing High-Risk Books
Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. 
Display the member name, book title, and the number of times they've issued damaged books.    
*/
DELIMITER $$

CREATE PROCEDURE issue_book(
    p_issued_id VARCHAR(10),
    p_issued_member_id VARCHAR(30),
    p_issued_book_isbn VARCHAR(30),
    p_issued_emp_id VARCHAR(10)
)
BEGIN
    DECLARE v_status VARCHAR(10);

    -- Check if the book is available
    SELECT status
    INTO v_status
    FROM books
    WHERE isbn = p_issued_book_isbn
    LIMIT 1;  -- Ensures only one row is selected

    -- If the book is available (status = 'yes')
    IF v_status = 'yes' THEN
        -- Insert record into the issued_status table
        INSERT INTO issue_status (issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES (p_issued_id, p_issued_member_id, CURDATE(), p_issued_book_isbn, p_issued_emp_id);

        -- Update the book status to 'no' (book is now issued)
        UPDATE books
        SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        -- Output success message
        SELECT CONCAT('Book issued successfully for book isbn: ', p_issued_book_isbn) AS message;

    ELSE
        -- Output failure message if the book is unavailable
        SELECT CONCAT('Sorry, the book you requested is unavailable (book isbn: ', p_issued_book_isbn, ')') AS message;
    END IF;
END$$

DELIMITER ;
CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');
