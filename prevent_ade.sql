Identifying Adverse Drug Events (ADEs) with Stored Programs
use ade;

select * from recommendation;

-- A stored procedure to process and validate prescriptions
-- Four things we need to check
-- a) Is patient a child and is medication suitable for children?
-- b) Is patient pregnant and is medication suitable for pregnant women?
-- c) Are there any adverse drug reactions


drop procedure if exists prescribe;

delimiter //
create procedure prescribe
(
    in patient_name_param varchar(255),
    in doctor_name_param varchar(255),
    in medication_name_param varchar(255),
    in ppd_param int -- pills per day prescribed
)
procedure_prescribe: begin
	-- variable declarations
    declare patient_id_var int;
    declare age_var float;
    declare is_pregnant_var boolean;
    declare weight_var int;
    declare doctor_id_var int;
    declare medication_id_var int;
    declare take_under_12_var boolean;
    declare take_if_pregnant_var boolean;
    declare mg_per_pill_var double;
    declare max_mg_per_10kg_var double;

    declare message varchar(255); -- The error message
    declare ddi_medication varchar(255); -- The name of a medication involved in a drug-drug interaction




    -- select relevant values into variables
    
-- get patient_id and age based on the patient_name parameter
select patient_id, (datediff(now(), dob)/365) as age, weight, is_pregnant
into patient_id_var, age_var, weight_var, is_pregnant_var
from patient 
where patient_name = patient_name_param;

-- get doctor_id based on the doctor_name parameter
select doctor_id 
into doctor_id_var
from doctor
where doctor_name = doctor_name_param;

-- get medication_id based on the medication_name parameter 
select medication_id, take_under_12, take_if_pregnant, mg_per_pill, max_mg_per_10kg
into medication_id_var, take_under_12_var, take_if_pregnant_var, mg_per_pill_var, max_mg_per_10kg_var
from medication 
where medication_name = medication_name_param;




    -- check age of patient
IF take_under_12_var = 0 and age_var < 12 THEN
    set message = concat(medication_name_param, ' cannot be prescribed to children under 12.');
    
    -- report the error message and exit stored procedure 
    select message;
    leave procedure_prescribe;

end if;

    -- check if medication ok for pregnant women
if take_if_pregnant_var = 0 and is_pregnant_var = 1 then 
	set message = concat(medication_name_param, ' cannot be prescribed to pregnant women');
    
    -- report the error message and exit stored procedure 
    select message;
    leave procedure_prescribe;

end if;

    -- Check for reactions involving medications already prescribed to patient
select medication_name into ddi_medication
from prescription join medication on prescription.medication_id = medication.medication_id
where patient_id = patient_id_var 
and exists(select medication_2 
		  from interaction 
          where medication_2 = prescription.medication_id
          and medication_1 = medication_id_var);

if ddi_medication is not null then 
set message = concat(medication_name_param, ' interacts with ', ddi_medication, ' currently
prescribed to ', patient_name_param);

-- report the error message and exit stored procedure 
select message;
leave procedure_prescribe;

end if;

    -- No exceptions thrown, so insert the prescription record
    
    -- create a prescription record based on the parameters 
insert into ade.prescription
(medication_id, patient_id, doctor_id, prescription_dt, ppd)
values(medication_id_var, patient_id_var, doctor_id_var, now(), ppd_param);

end //
delimiter ;



-- Trigger

DROP TRIGGER IF EXISTS patient_after_update_pregnant;

DELIMITER //

CREATE TRIGGER patient_after_update_pregnant
	AFTER UPDATE ON patient
	FOR EACH ROW
BEGIN

    -- Patient became pregnant
    -- Add pre-natal recommenation
    -- Delete any prescriptions that shouldn't be taken if pregnant

if new.is_pregnant = 1 then 

insert into ade.recommendation
(patient_id, message)
values (new.patient_id, 'Take pre-natal vitamins');

delete from prescription
where medication_id = (
	select medication_id from (
	select prescription.medication_id
	from medication join prescription on medication.medication_id = prescription.medication_id
	where take_if_pregnant = 0
    and prescription.patient_id = new.patient_id) as m )
and patient_id = new.patient_id;  

else 

    -- Patient is no longer pregnant
    -- Remove pre-natal recommendation

delete from recommendation 
where patient_id = new.patient_id;

-- 

end if;
END //

DELIMITER ;


-- --------------------------                  TEST CASES                     -----------------------

truncate prescription;

-- These prescriptions should succeed
call prescribe('Jones', 'Dr.Marcus', 'Happyza', 2);
call prescribe('Johnson', 'Dr.Marcus', 'Forgeta', 1);
call prescribe('Williams', 'Dr.Marcus', 'Happyza', 1);
call prescribe('Phillips', 'Dr.McCoy', 'Forgeta', 1);

-- These prescriptions should fail
-- Pregnancy violation
call prescribe('Jones', 'Dr.Marcus', 'Forgeta', 2);

-- Age restriction
call prescribe('BillyTheKid', 'Dr.Marcus', 'Muscula', 1);


-- Drug interaction
call prescribe('Williams', 'Dr.Marcus', 'Sadza', 1);



-- Testing trigger
-- Phillips (patient_id=4) becomes pregnant
-- Verify that a recommendation for pre-natal vitamins is added
-- and that her prescription for
update patient
set is_pregnant = True
where patient_id = 4;

select * from recommendation;
select * from prescription;


-- Phillips (patient_id=4) is no longer pregnant
-- Verify that the prenatal vitamin recommendation is gone
-- Her old prescription does not need to be added back

update patient
set is_pregnant = False
where patient_id = 4;

select * from recommendation;
