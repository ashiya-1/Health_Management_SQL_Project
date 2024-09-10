use project;


--  Overview of all tables
SELECT * FROM appointment;
SELECT * FROM billing;
SELECT * FROM medical_procedures;
SELECT * FROM patient;


-- 1. How many records are there in each of the following tables: appointment, billing, doctor, medical_procedures, and patient?
 select
    (select count(*) from appointment) as appointment_count,
    (select count(*) from billing) as billing_count,
    (select count(*) from doctor) as doctor_count,
    (select count(*) from medical_procedures) as medical_procedures_count,
    (select count(*) from patient) as patient_count;
    

-- 2. How many distinct doctors exist, along with what are their names?
select count(distinct doctorname) as count_doctor from doctor;
select distinct doctorname from doctor;


-- 3. What are the appointment details (including patient names) organized by appointment ID?
select a.appointmentid, p.firstname, p.lastname, a.date, a.time
from patient p
join appointment a on p.patientid = a.patientid
order by a.appointmentid;


-- 4. What are the procedure details, including patient names?
select p.firstname, p.lastname, mpr.procedurename
from patient p
join appointment a on p.patientid = a.patientid
join medical_procedures mpr on a.appointmentid = mpr.appointmentid;


-- 5. What are the doctor's details and appointment information?
select d.doctorname, d.specialization, a.patientid, a.appointmentid, a.date, a.time
from doctor d
join appointment a on d.doctorid = a.doctorid;


-- 6. What are the billing data for each patient?
select p.firstname, p.lastname, b.items, b.amount
from patient p
join billing b on p.patientid = b.patientid;


-- 7. What are the distinctive procedure names?
select distinct procedurename from medical_procedures;


-- 8. What are the unique things in the billing records, and how frequently does each appear?
select  distinct items, count(items) as item_count
from billing
group by items;


-- 9. How many doctors are there for each specialization?
select d.specialization, count(d.doctorid) as doctor_count
from doctor d
group by d.specialization
order by doctor_count desc;


-- 10. What are the appointment trends over time (monthly)?
select extract(month from date) as month, count(appointmentid) as total_appointments
from appointment
group by month
order by month;


-- 11. Which patients have multiple appointments (patient retention)?
select p.patientid, p.firstname, p.lastname, count(a.appointmentid) as total_appointments
from patient p 
join appointment a on p.patientid = a.patientid
group by p.patientid, p.firstname, p.lastname
having count(a.appointmentid) > 1;


-- 12. What are the most frequent medical procedures?
select mpr.procedurename, count(mpr.procedureid) as procedure_count
from medical_procedures mpr
group by mpr.procedurename
order by procedure_count desc ;


-- 13. What is the total revenue made by doctors, grouped by specialization?
select d.specialization, sum(b.amount) as total_revenue
from doctor d 
join appointment a on d.doctorid = a.doctorid
join billing b on a.patientid = b.patientid
group by d.specialization;


-- 14. What is the current total of billing amounts per patient?
select b.patientid, p.firstname, p.lastname, b.items, b.amount, 
sum(b.amount) over (partition by b.patientid order by b.invoiceid) as runningtotal
from billing b
join patient p on b.patientid = p.patientid;


-- 15. How are doctors ranked according to the quantity of procedures they perform?
select d.doctorname, count(mpr.procedureid) as procedurecount,
rank() over (order by count(mpr.procedureid) desc) as doctorrank
from doctor d
join appointment a on d.doctorid = a.doctorid
join medical_procedures mpr on a.appointmentid = mpr.appointmentid
group by d.doctorname;


-- 16. Which patients have paid more than the average amount for billing?
-- Calculate the average billing amount
with average_spending as (
    select avg(total_amount) as avg_spent
    from (
        select sum(amount) as total_amount
        from billing
        group by patientid
    ) as temp
)

-- Find patients who paid more than the average
select p.patientid, p.firstname, p.lastname, sum(b.amount) as total_spent
from patient p
join billing b on p.patientid = b.patientid
group by p.patientid, p.firstname, p.lastname
having sum(b.amount) > (select avg_spent from average_spending);



-- 17. Which procedures have a total billed cost that exceeds the average?
-- Calculate the average billed amount per procedure
with avg_billed as (
    select avg(sum_amount) as avg_billed
    from (
        select sum(b.amount) as sum_amount
        from billing b
        join appointment a on b.patientid = a.patientid
        group by a.appointmentid
    ) as temp
)

-- Find procedures that exceed the average billing
select mpr.procedurename
from medical_procedures mpr
join appointment a on mpr.appointmentid = a.appointmentid
join billing b on a.patientid = b.patientid
group by mpr.procedurename
having sum(b.amount) > (select avg_billed from avg_billed);


-- 18. How are patients ranked according to their spending?
-- Calculate total spending per patient
with patient_spending as (
    select p.patientid, p.firstname, p.lastname, sum(b.amount) as total_spent
    from patient p
    join billing b on p.patientid = b.patientid
    group by p.patientid, p.firstname, p.lastname
)

-- Calculate average spending of all patients
select ps.patientid, ps.firstname, ps.lastname, ps.total_spent,
    case when ps.total_spent > (select avg(total_spent) from patient_spending)
         then 'Above Average'
         else 'Below Average'
    end as spending_category
from patient_spending ps;


-- 19. What is the most common procedure performed by doctors?
-- Count how many times each procedure was done by doctors
with procedure_frequency as (
    select d.doctorname, mpr.procedurename, count(*) as procedure_count
    from doctor d
    join appointment a on d.doctorid = a.doctorid
    join medical_procedures mpr on a.appointmentid = mpr.appointmentid
    group by d.doctorname, mpr.procedurename
)

-- Show the most common procedures done by doctors
select doctorname, procedurename, procedure_count
from procedure_frequency
order by procedure_count desc;


-- 20. How many procedures were completed, and what was the average billing amount each procedure?
select mpr.procedurename, count(mpr.procedureid) as total_procedures, avg(b.amount) as avg_billing
from medical_procedures mpr
join appointment a on mpr.appointmentid = a.appointmentid
join billing b on a.patientid = b.patientid
group by mpr.procedurename;


-- 21. What is the maximum, minimum, and average amount billed per item?
select items, max(amount) as max_amount, min(amount) as min_amount, avg(amount) as avg_amount
from billing
group by items;

