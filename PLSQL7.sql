----TRIGGERE-----
/*Tipuri de triggere
1. de tip DML
2. de tip DDL
3. system
*/

Necesar:
- timpul cand se declanseaza un trigger
- actiunea cand se declanseaza
- asupra cui (tabela si eventual coloana)

--1. Triggere de tip DML (cu BEFORE / AFTER): delete, insert, update

set serveroutput on;

CREATE OR REPLACE TRIGGER dml_stud
   BEFORE INSERT OR UPDATE OR DELETE ON studenti
DECLARE  -- la triggere se adauga cuvantul DECLARE pentru declaratii variabile, fata de subprograme
   nume varchar2(100);
BEGIN
    -- puteti sa vedeti cine a declansat triggerul:
  select user into nume from dual;
  dbms_output.put_line('Operatie DML in tabela studenti ! Realizata de catre userul: '||nume);

  CASE
     WHEN INSERTING THEN DBMS_OUTPUT.PUT_LINE('INSERT');
     WHEN DELETING THEN DBMS_OUTPUT.PUT_LINE('DELETE');
     WHEN UPDATING THEN DBMS_OUTPUT.PUT_LINE('UPDATE');
     -- WHEN UPDATING('NUME') THEN .... 
     -- vedeti mai jos trigere ce se executa doar la modificarea unui anumit camp, exemplu nume
  END CASE;
END;
/
select * from studenti where id=1025;/
select count(*) from note where id_student=1025;/
select count(*) from prieteni where id_student1=1025 or id_student2=1025;/

delete from studenti where id=1025;
rollback;

-------------------------------------------------------------------------------
--Efectul BEFORE/AFTER 
CREATE OR REPLACE TRIGGER dml_stud1
   BEFORE INSERT OR UPDATE OR DELETE ON studenti
declare   
   v_nume studenti.nume%type;
BEGIN  
  select nume into v_nume from studenti where id=200;
  dbms_output.put_line('Before DML TRIGGER: ' || v_nume);
END;
/

CREATE OR REPLACE TRIGGER dml_stud2
   AFTER INSERT OR UPDATE OR DELETE ON studenti
declare   
   v_nume studenti.nume%type;
BEGIN  
  select nume into v_nume from studenti where id=200;
  dbms_output.put_line('After DML TRIGGER: ' || v_nume);
END;
/

update studenti set nume='NumeNou' where id=200;
select * from studenti where id=200;
-- dupa cum se poate vedea au fost declansate toate cele 3 triggere pe tabela studenti:
--dml_stud, dml_stud1 si dml_stud2
rollback;

-- ce se intampla cand se modifica alt id?
select * from studenti where id=1025;
update studenti set nume='Numenou' where id=1025; -- este afisat numele user 200 de fapt, inainte si la fel dupa update
select * from studenti where id=1025; -- s-a facut update pe nume pt user 1025
select * from studenti where id=200; --nu s-a facut modificare pt user 200, doar este afisat numele lui in trigger
rollback;

-------  :OLD si :NEW -- DOAR PENTRU TIGERRE DE TIP EACH ROW!!!
-- La insert - :NEW exista si :OLD este null
-- La update - ambele
-- La delete - :OLD si :NEW este null

CREATE OR REPLACE TRIGGER marire_nota
  before UPDATE OF valoare ON note   -- aici se executa numai cand modificam valoarea !
  FOR EACH ROW -- se va declansa pentru fiecare rand modificat
BEGIN
  dbms_output.put_line('ID nota: ' || :OLD.id); 
  -- observati ca aveti acces si la alte campuri, nu numai la cele modificate...
  dbms_output.put_line('Vechea nota: ' || :OLD.valoare);  
  dbms_output.put_line('Noua nota: ' || :NEW.valoare);    

  -- totusi nu permitem sa facem update daca valoarea este mai mica (conform regulamentului universitatii):
  IF (:OLD.valoare>:NEW.valoare) THEN :NEW.valoare := :OLD.valoare;
  end if;  
END;
/

update note set valoare =8 where id between 1 and 6;
select * from note where id  between 1 and 6;
-- s-a modificat :NEW doar pentru ca e trigger BEFORE; 
-- :OLD nu poate fi modificat (nici :NEW daca era un delete ca e null)
rollback; 

--- CUM sa accesam valorile dintr-o coloana de tip Nested Table---
drop table stud;/
drop type note_stud;/

CREATE OR REPLACE TYPE note_stud IS TABLE OF number;
create table stud as select * from studenti;
alter table stud add coloana_note note_stud NESTED TABLE coloana_note STORE AS lista;
update stud set coloana_note = note_stud(5,8,9,10) where id=1;
update stud set coloana_note = note_stud(7,6,8) where id=2;

select coloana_note from stud where id in (1,2);

CREATE OR REPLACE TRIGGER marire_nota1
  before UPDATE  ON stud   
  FOR EACH ROW 

BEGIN

  dbms_output.put_line('ID note: ' || :OLD.id); 
  for i in 1..:old.coloana_note.count loop
    dbms_output.put_line('Vechea nota: ' || :old.coloana_note(i));  
    dbms_output.put_line('Noua nota: ' || :new.coloana_note(i) ); 
  IF (:OLD.coloana_note(i)>:NEW.coloana_note(i)) THEN 
        dbms_output.put_line('Nu se modifica nota');
        :NEW.coloana_note(i) := :OLD.coloana_note(i);
  end if;  
end loop;

END;

update stud set coloana_note = note_stud(4,9,5) where id=2;
select coloana_note from stud where id in (1,2);
rollback;

--------------Aparitia erorilor de tip Mutating Table: PENTRU TRIGGERE EACH ROW --------------------

create or replace trigger mutate_example
after delete on note for each row
declare 
   v_ramase int;
begin
   dbms_output.put_line('Stergere nota cu ID: '|| :OLD.id);
   select count(*) into v_ramase from note;
   dbms_output.put_line('Au ramas '|| v_ramase || ' note.');
--daca le comentam se fac face delete    
end;
/
delete from note where id between 101 and 110;
/
-- nu se poate declansa triggerul pentru ca este de tip each row si de fiecare cand se face delete se face si citire
-- daca se comenteaza liniile de cod cu select si afisarea nr de note ramase, triggerul va functiona
rollback;

--SOLUTII---
--Utilizarea triggerilor compusi
--Utilizarea unei tabele temporare

--TRIGGER COMPUS---
CREATE OR REPLACE TRIGGER stergere_note 
FOR DELETE ON NOTE
COMPOUND TRIGGER
  v_ramase INT;
  
  AFTER EACH ROW IS 
  BEGIN
     dbms_output.put_line('Stergere nota cu ID: '|| :OLD.id);
  END AFTER EACH ROW;
  
  AFTER STATEMENT IS 
  BEGIN
     select count(*) into v_ramase from note;
     dbms_output.put_line('Au ramas '|| v_ramase || ' note.');  
  END AFTER STATEMENT ;
END stergere_note;

delete from note where id between 241 and 250;
rollback;


drop trigger dml_stud;/
drop trigger dml_stud1;/
drop trigger dml_stud2;/
drop trigger marire_nota;/
drop trigger mutate_example;/
drop trigger stergere_note;/


----FOLLOWS si PRECEDES 
create or replace trigger primul
    before update of valoare on note
    for each row
    begin
      if :old.valoare>:new.valoare then 
        :new.valoare:=:old.valoare;  --in primul trigger modificam nota noua daca e mai mica
        
      end if;
end;

create or replace trigger doi
    before update of valoare on note
    for each row
    begin
      dbms_output.put_line('Nota initiala este '||:old.valoare||' si noua nota este: '||:new.valoare);
      --in al doilea trigger afisam direct 
end;

select valoare from note where id=1;
update note set valoare = 4 where id=1;
/* Se va afisa ca nota noua este 4 desi noi am modificat in primul trigger valoare 
pentru nota cea noua in cazul in care este mai mica. 
Acest lucru are loc pentru ca intai se declanseaza triggerul doi si apoi primul.
Solutia este FOLLOWS */
rollback;

drop trigger doi;/
create or replace trigger doi
    before update of valoare on note
    for each row
    follows primul
    begin
      dbms_output.put_line('Nota initiala este '||:old.valoare||' si noua nota este: '||:new.valoare);
      --in al doilea trigger afisam direct 
end;

select valoare from note where id=1; 
update note set valoare = 4 where id=1; -- acum se afiseaza corect noua nota
rollback;


drop trigger primul;/
drop trigger doi;/

--------------Triggere de tipul instead of----------------
--- DOAR PESTE VIEW-uri
drop view std;/
create view std as select * from studenti;/

CREATE OR REPLACE TRIGGER delete_student
  INSTEAD OF delete ON std
BEGIN
  dbms_output.put_line('Stergem pe:' || :OLD.nume);
  delete from note where id_student=:OLD.id;
  delete from prieteni where id_student1=:OLD.id;
  delete from prieteni where id_student2=:OLD.id;
  delete from studenti where id=:OLD.id;
END;

delete from std where id=75;
select * from studenti where id=75;
rollback;

drop trigger delete_student;


----------------2. Triggere DDL ------------
-- de tipul before, after sau instead.
-- modificata schema de baze de date: drop, alter, create sau de tipul instead of create.

CREATE OR REPLACE TRIGGER drop_trigger
  BEFORE DROP ON studentSGBD.SCHEMA --numele userului vostru, la mine este studentSGBD
  BEGIN
    RAISE_APPLICATION_ERROR (
      num => -20000,
      msg => 'can''t touch this');
  END;
/

drop table note;

CREATE OR REPLACE TRIGGER t
  INSTEAD OF CREATE ON SCHEMA
  BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE T (n NUMBER, m NUMBER)';
  END;
/
create table a(x number); -- de fapt va crea tabelul T.
select * from  a;
select * from  t;


drop trigger drop_trigger;/
drop trigger t;/
drop table t;/


---------------Triggere  Sistem-------



