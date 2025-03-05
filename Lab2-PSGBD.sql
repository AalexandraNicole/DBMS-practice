DECLARE

begin
    null;
end;
--bloc anonim

BEGIN
   DBMS_OUTPUT.PUT_LINE('Maine:' || (SYSDATE+1));
END;

set serveroutput on; /*fara de care nu se afiseaza in consola--- odata setat ramane setat*/
DECLARE
      v_mesaj VARCHAR2(50) DEFAULT 'Salutare, lume !'; /*Pot si cu ':=' */
BEGIN
    v_mesaj := 'La revedere'; /*Numai cu := pot sa fac reasignare*/
      DBMS_OUTPUT.PUT_LINE('Mesaj: ' || v_mesaj);
END;

--Domeniu de vizibilitate

<<eticheta>>
DECLARE
   v_nume VARCHAR2(20):='Cristi';
   v_varsta INTEGER:= 21;  -- INTEGER este un alias pentru NUMBER(38,0).
BEGIN
   DBMS_OUTPUT.PUT_LINE('Valoarea variabilei v_nume este: ' || v_nume);  -- va afisa 'Cristi'
   DECLARE
      v_nume NUMBER(3) := 5;
   BEGIN
         DBMS_OUTPUT.PUT_LINE('Valoarea variabilei v_nume este: ' || v_nume); -- va afisa 5
         DBMS_OUTPUT.PUT_LINE('Valoarea variabilei v_nume este: ' || eticheta.v_nume); -- va afisa Cristi
         DBMS_OUTPUT.PUT_LINE('Varsta este: ' || v_varsta); -- va afisa 21
   END;
   DBMS_OUTPUT.PUT_LINE('Valoarea variabilei v_nume este: ' || v_nume); -- va afisa 'Cristi'
END;


--Operatori

set serveroutput on;
DECLARE
   a NUMBER := 10;
   b NUMBER := 4;
BEGIN
   DBMS_OUTPUT.PUT_LINE('Suma: ' || (a+b));
   DBMS_OUTPUT.PUT_LINE('Diferenta: ' || (a-b));
   DBMS_OUTPUT.PUT_LINE('Produsul: ' || (a*b));
   DBMS_OUTPUT.PUT_LINE('Impartirea: ' || (a/b));
   DBMS_OUTPUT.PUT_LINE('Exponentierea: ' || (a ** b)); -- nu exista in SQL
END;
--... uitate la PLSQL1


--Preluarea unei singure valori din tabel

SELECT nume FROM studenti WHERE ROWNUM=1;

--cu INTO 

DECLARE
   v_valoare_nota_maxima note.valoare%TYPE;
   v_valoare_nota_minima note.valoare%TYPE; --ia tipul de date a coloanei valoare din tabela note
BEGIN   
   SELECT MAX(valoare) INTO v_valoare_nota_maxima FROM note; 
   SELECT MIN(valoare) INTO v_valoare_nota_minima FROM note;
   DBMS_OUTPUT.PUT_LINE('Nota maxima: ' || v_valoare_nota_maxima);
   DBMS_OUTPUT.PUT_LINE('Nota minima: ' || v_valoare_nota_minima);
END;


-- afisez numele prenumele si media primullui student (id=1)
DECLARE
    v_nume studenti.nume%TYPE;
    v_prenume studenti.prenume%TYPE;
    v_media NUMBER(4, 2);
BEGIN

    SELECT nume, prenume, round(AVG(VALOARE), 2) INTO v_nume, v_prenume , v_media
        FROM studenti s JOIN note n ON s.id = n.id_student
        WHERE s.id = 1
        GROUP BY nume, prenume, s.id
        ; 
    
    DBMS_OUTPUT.PUT_LINE('Numele, Prenumele si Media '|| v_nume ||' '|| v_prenume ||' '|| v_media);
    
END;

-- sa afisez numele, prenumele si media primului student in ordine alfabetica dupa nume si prenume cu media cea mai mare

DECLARE
    v_nume studenti.nume%TYPE;
    v_prenume studenti.prenume%TYPE;
    v_media NUMBER(4, 2);
BEGIN

    SELECT * INTO v_nume, v_prenume , v_media
    FROM(
            SELECT nume, prenume, round(AVG(VALOARE), 2) media
                FROM studenti s JOIN note n ON s.id = n.id_student
                GROUP BY nume, prenume, s.id
                having round(AVG(VALOARE), 2) = (SELECT MAX(round(AVG(VALOARE), 2)) FROM note GROUP BY id_student)
                ORDER BY nume, prenume
        ) WHERE ROWNUM = 1
        ; 
    
    DBMS_OUTPUT.PUT_LINE('Media maxiam: '|| v_nume ||' '|| v_prenume ||' '|| v_media);
    
    SELECT * INTO v_nume, v_prenume , v_media
    FROM(
            SELECT nume, prenume, round(AVG(VALOARE), 2) media
                FROM studenti s JOIN note n ON s.id = n.id_student
                GROUP BY nume, prenume, s.id
                having round(AVG(VALOARE), 2) = (SELECT MIN(round(AVG(VALOARE), 2)) FROM note GROUP BY id_student)
                ORDER BY nume, prenume
        ) WHERE ROWNUM = 1
        ; 
    
    DBMS_OUTPUT.PUT_LINE('Media minima: '|| v_nume ||' '|| v_prenume ||' '|| v_media);
    
END;

