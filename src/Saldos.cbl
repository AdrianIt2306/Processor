       identification division.
       program-id. saldos.

       data division.
       working-storage section.

           exec sql include sqlca end-exec.

           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01 hv-customers      pic 9(9) value 0.
           EXEC SQL END DECLARE SECTION END-EXEC.

       procedure division.
       inicio.
           EXEC SQL
               SELECT COUNT(*)
                 INTO :hv-customers
                 FROM customers
           END-EXEC

           if sqlcode not = 0
               display "Error SELECT SQLCODE=" sqlcode
               display "SQLSTATE=" sqlstate
           else
               display "CUSTOMERS total: " hv-customers
           end-if

           goback.

       end program saldos.