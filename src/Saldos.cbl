       identification division.
       program-id. saldos.

       data division.
       working-storage section.

           exec sql include sqlca end-exec.

           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01 hv-customers      pic 9(9) value 0.
       01 hv-cust-id        pic 9(9) value 0.
       01 hv-cust-name      pic x(100) value spaces.
       01 hv-cust-last      pic x(100) value spaces.
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
               display "CUSTOMERS totals: " hv-customers
           end-if


      *--- Mostrar todos los registros de customers ---*
           EXEC SQL
               DECLARE c1 CURSOR FOR
                   SELECT cust_id, cust_name, cust_last_name
                   FROM customers
           END-EXEC

           EXEC SQL OPEN c1 END-EXEC

           perform until sqlcode not = 0
               EXEC SQL
                   FETCH c1 INTO
                       :hv-cust-id,
                       :hv-cust-name,
                       :hv-cust-last
               END-EXEC
               display 'FETCH SQLCODE=' sqlcode
               if sqlcode = 0
                   display hv-cust-id ' |>'
                           hv-cust-name(1:20) '<|>'
                           hv-cust-last(1:20) '<'
               end-if
           end-perform

           EXEC SQL CLOSE c1 END-EXEC

           goback.

       end program saldos.