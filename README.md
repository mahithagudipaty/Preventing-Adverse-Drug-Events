# Preventing Adverse Drug Events (ADEs) with MySQL Stored Programs

This project demonstrates how stored procedures and triggers in MySQL can be used to prevent Adverse Drug Events (ADEs) within an electronic medical record (EMR) system. ADEs occur when a medication is improperly prescribed or when multiple drugs interact negatively, potentially leading to serious side effects.
The goal is to build a robust database workflow that validates prescriptions, detects potential drug-drug interactions, and proactively recommends safer alternatives when necessary

## Features

### Prescription Validation

* A stored procedure (prescribe) ensures that any prescribed medication complies with patient-specific constraints:
* Rejects prescriptions contraindicated for children under 12
* Prevents prescribing unsafe drugs to pregnant patients
* Detects potential drug-drug interactions using existing prescriptions and the interaction table
* Generates clear, contextual error messages when rules are violated

### Pregnancy-Aware Triggers

* A database trigger (patient_after_update_pregnant) monitors changes to a patient’s pregnancy status:
* Automatically adds a recommendation for prenatal vitamins when a patient becomes pregnant
* Deletes prescriptions for any medications unsafe during pregnancy
* Removes recommendations once the patient is no longer pregnant

### Built-In Test Cases

* Multiple test cases validate the stored procedure and trigger logic:
* Successful prescriptions
* Violations for age restrictions, pregnancy safety, and drug interactions
* Automatic handling of pregnancy status updates and recommendations
